#!/bin/sh
# Deploys a release deploy/bin/build-release.sh has built (docs/deploy.md,
# "Deploying"), as root, inside the host's deploy lock:
#
#   with-deploy-lock /home/sawyer/web-work/daybyword.com-COMMIT/release/deploy/bin/activate.sh COMMIT
#
# 1. stage the release as releases/COMMIT (root-owned, never edited), and run
#    the rest from there;
# 2. back up the database (deploy/bin/backup.sh, which checks the dump);
# 3. migrate and import the release's catalog as daybyword-web with
#    migration.env only, and check the migrations against the release;
# 4. boot the release as a candidate on a free 44xx port under a copy of its
#    own unit file, and check it (deploy/bin/check-live.sh, /healthz with
#    the commit);
# 5. switch `current` to it and restart daybyword-web.service;
# 6. check what is live, by the running process (web-live) and over HTTP;
# 7. install the Caddy site file only if it changed (caddy-apply);
# 8. record it, and check https://daybyword.com and the other sites.
# Fix-forward only. Up to step 4 a failure leaves the previous release
# serving; after it, the fix is a new commit and a new deploy.
set -eu
commit=${1:?usage: activate.sh COMMIT}
# shellcheck source=deploy/bin/common.sh
. "$(dirname "$0")/common.sh"

[ "$(id -u)" = 0 ] || fail "run as root"
case $commit in *[!0-9a-f]* | "") fail "COMMIT is the full 40-character SHA" ;; esac
[ ${#commit} -eq 40 ] || fail "COMMIT is the full 40-character SHA"
require_lock
[ "$(cat "$DBW_RELEASE_DIR/REVISION")" = "$commit" ] || fail "$DBW_RELEASE_DIR is not the release of $commit"
for file in web.env migration.env; do
  [ -f "$DBW_ENV_DIR/$file" ] || fail "$DBW_ENV_DIR/$file is missing (bin/provision-app-database daybyword --web-access read-only)"
done
release=$DBW_ROOT/releases/$commit

# 1. Stage, then continue from the root-owned copy.
if [ "$DBW_RELEASE_DIR" != "$release" ]; then
  say "staging $release"
  if [ -d "$release" ]; then
    diff -r "$DBW_RELEASE_DIR" "$release" >/dev/null || fail "$release exists and differs from this build"
  else
    rm -rf "$release.staging"
    cp -a "$DBW_RELEASE_DIR/." "$release.staging"
    chown -R root:root "$release.staging"
    chmod -R u=rwX,go=rX "$release.staging"
    mv -T "$release.staging" "$release"
  fi
  exec "$release/deploy/bin/activate.sh" "$commit"
fi

held=$(ss -ltnHp "sport = :$DBW_PORT")
pid=$(systemctl show -p MainPID --value "$DBW_UNIT.service" 2>/dev/null || echo 0)
case $held in "" | *"pid=$pid,"*) ;; *) fail "port $DBW_PORT is held by something other than $DBW_UNIT.service: $held" ;; esac
neighbors() {
  for file in /etc/caddy/sites/*.caddy; do
    [ "$file" = "/etc/caddy/sites/$DBW_SITE.caddy" ] && continue
    name=$(grep -m1 -oE '^[a-z0-9.-]+\.[a-z]+' "$file" || true)
    [ -n "$name" ] && printf '%s %s\n' "$name" "$(curl -s -o /dev/null -m 15 -w '%{http_code}' "https://$name/")"
  done
}
before=$(neighbors)

id -u "$DBW_ACCOUNT" >/dev/null 2>&1 ||
  useradd --system --user-group --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin "$DBW_ACCOUNT"
install -d -o root -g root -m 0755 "$DBW_ROOT" "$DBW_ROOT/releases"

# 2-3. Back up, migrate, import.
say "backing up before migrating"
"$release/deploy/bin/backup.sh"
job() {
  systemd-run --wait --collect --pipe --quiet --unit="$DBW_UNIT-$1" \
    -p User="$DBW_ACCOUNT" -p Group="$DBW_ACCOUNT" \
    -p EnvironmentFile="$DBW_ENV_DIR/migration.env" -p Environment=NODE_ENV=production \
    -p WorkingDirectory="$release" \
    -p NoNewPrivileges=true -p ProtectSystem=strict -p ProtectHome=true -p PrivateTmp=true \
    -p PrivateDevices=true -p RestrictAddressFamilies="AF_UNIX AF_INET AF_INET6" \
    "$DBW_NODE" "$@"
}
say "migrating and importing the catalog"
job migrate "$release/scripts/db-migrate.ts"
job import "$release/scripts/catalog-import.ts" "$release/catalog/catalog-export.json"
applied=$(psql_admin -c "select count(*) from drizzle.__drizzle_migrations")
expected=$(grep -c '"tag"' "$release/drizzle/meta/_journal.json")
[ "$applied" = "$expected" ] || fail "the database has $applied migrations; the release carries $expected"

# 4. The candidate: this release's own unit, its own account and sandbox,
# the real database, on a free loopback port.
port=4400
while [ -n "$(ss -ltnH "sport = :$port")" ]; do
  port=$((port + 1))
  [ "$port" -le 4499 ] || fail "no free candidate port in 4400-4499"
done
unit=/run/systemd/system/$DBW_UNIT-candidate.service
stop_candidate() {
  systemctl stop "$DBW_UNIT-candidate.service" 2>/dev/null || true
  rm -f "$unit"
  systemctl daemon-reload
}
sed -e "s|$DBW_ROOT/current|$release|g" -e "s|PORT=$DBW_PORT\\b|PORT=$port|" \
  "$release/deploy/systemd/$DBW_UNIT.service" >"$unit"
grep -q "PORT=$port " "$unit" || { rm -f "$unit"; fail "could not give the candidate its port"; }
systemctl daemon-reload
say "starting the candidate on 127.0.0.1:$port"
systemctl start "$DBW_UNIT-candidate.service"
if ! wait_for "http://127.0.0.1:$port/healthz" || ! "$release/deploy/bin/check-live.sh" "http://127.0.0.1:$port" "$commit"; then
  journalctl -u "$DBW_UNIT-candidate.service" -n 20 --no-pager >&2 || true
  stop_candidate
  fail "the candidate failed its checks; the previous release still serves"
fi
stop_candidate

# 5. Switch.
say "activating $commit"
changed=0
if ! cmp -s "$release/deploy/systemd/$DBW_UNIT.service" "/etc/systemd/system/$DBW_UNIT.service"; then
  systemd-analyze verify "$release/deploy/systemd/$DBW_UNIT.service"
  install -m 0644 "$release/deploy/systemd/$DBW_UNIT.service" "/etc/systemd/system/$DBW_UNIT.service"
  changed=1
fi
dropin=/etc/systemd/system/$DBW_UNIT.service.d/50-resource-boundaries.conf
if ! cmp -s "$release/deploy/systemd/50-resource-boundaries.conf" "$dropin"; then
  install -D -m 0644 "$release/deploy/systemd/50-resource-boundaries.conf" "$dropin"
  changed=1
fi
for timer in daybyword-backup daybyword-restore-check; do
  for kind in service timer; do
    if ! cmp -s "$release/deploy/systemd/$timer.$kind" "/etc/systemd/system/$timer.$kind"; then
      install -m 0644 "$release/deploy/systemd/$timer.$kind" "/etc/systemd/system/$timer.$kind"
      changed=1
    fi
  done
done
[ "$changed" = 0 ] || systemctl daemon-reload
systemctl enable --quiet "$DBW_UNIT.service" daybyword-backup.timer daybyword-restore-check.timer
ln -sfn "$release" "$DBW_ROOT/current.next"
mv -Tf "$DBW_ROOT/current.next" "$DBW_ROOT/current"
systemctl restart "$DBW_UNIT.service"

# 6. What is live.
i=0
until curl -fsS "http://127.0.0.1:$DBW_PORT/healthz" 2>/dev/null | grep -q "\"revision\":\"$commit\""; do
  i=$((i + 1))
  if [ "$i" -gt 60 ]; then
    journalctl -u "$DBW_UNIT.service" -n 20 --no-pager >&2 || true
    fail "$DBW_UNIT.service does not answer /healthz with $commit; fix forward (docs/deploy.md)"
  fi
  sleep 0.5
done
"$release/deploy/bin/check-live.sh" "http://127.0.0.1:$DBW_PORT" "$commit"
live=$(/home/sawyer/github/ubuntu-vm-backup/bin/web-live "$DBW_UNIT.service")
echo "$live"
want=$(printf '%s\t%s\t%s\t%s\t%s' "$DBW_UNIT.service" "/opt/node-v$(cat "$release/.node-version")-linux-x64/bin/node" "$release" "$commit" current)
[ "$live" = "$want" ] || fail "web-live does not report $release on Node $(cat "$release/.node-version") as current"

# 7. Caddy, only if the site file changed.
if ! cmp -s "$release/deploy/caddy/$DBW_SITE.caddy" "/etc/caddy/sites/$DBW_SITE.caddy"; then
  say "installing the Caddy site file"
  caddy-apply "$DBW_SITE" "$release/deploy/caddy/$DBW_SITE.caddy"
fi

# 8. Record and check from outside.
logger -t web-deploy "$DBW_SITE $commit live"
i=0
until curl -fsS "https://$DBW_SITE/healthz" 2>/dev/null | grep -q "\"revision\":\"$commit\""; do
  i=$((i + 1))
  [ "$i" -le 30 ] || fail "https://$DBW_SITE/healthz does not report $commit"
  sleep 2
done
"$release/deploy/bin/check-live.sh" "https://$DBW_SITE" "$commit"
after=$(neighbors)
if [ "$before" != "$after" ]; then
  echo "activate: another site answers differently than before this deploy:" >&2
  printf 'before:\n%s\nafter:\n%s\n' "$before" "$after" >&2
  exit 1
fi
say "$commit is serving; the other sites answer as before"
