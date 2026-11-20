#!/bin/sh
# Deploys the release in this directory (docs/deploy.md, "Release and
# rollback"), under the host's shared deploy lock:
#
#   DBW_RELEASE=<commit> with-deploy-lock deploy/bin/deploy.sh
#
# DBW_RELEASE tags the image; DBW_COMMIT, the commit Settings shows,
# defaults to it.
#
# 1. build the image daybyword-web:<commit> (the release directory holds
#    build/catalog/catalog-export.json from `make catalog-export`);
# 2. start PostgreSQL and reapply web/db/roles.sql (safe to repeat);
# 3. back up the database, if it has been migrated before;
# 4. run the one-shot migration and catalog import as daybyword_migrate;
# 5. boot the release as a candidate on a spare loopback port and check it;
# 6. switch the web service to it, check it, and record it as current,
#    keeping the previous release's image for deploy/bin/rollback.sh.
# Never removes a volume. Fails, leaving the previous release serving, at
# the first problem before step 6; a failure in step 6 rolls back.
set -eu
release=${DBW_RELEASE:?DBW_RELEASE names the commit being deployed}
# shellcheck source=deploy/bin/common.sh
. "$(dirname "$0")/common.sh"

commit=${DBW_COMMIT:-$release}
lock=${DBW_DEPLOY_LOCK:-/run/web-deploy/lock}
candidate_port=${DBW_CANDIDATE_PORT:-}
bin=$(dirname "$0")

take_lock "$lock"

[ -f "$DBW_RELEASE_DIR/build/catalog/catalog-export.json" ] || fail "no catalog export in the release"
say "building daybyword-web:$release"
docker build -q -f "$DBW_RELEASE_DIR/deploy/Dockerfile" --build-arg "DBW_COMMIT=$commit" \
  -t "daybyword-web:$release" "$DBW_RELEASE_DIR" >/dev/null

export DBW_RELEASE="$release"
say "starting the database"
compose up -d --wait postgres
psql_admin -q <"$DBW_RELEASE_DIR/web/db/roles.sql" >/dev/null

if [ "$(psql_admin -c "select to_regclass('drizzle.__drizzle_migrations') is not null")" = t ]; then
  say "backing up before migrating"
  "$bin/backup.sh"
fi

say "migrating and importing the catalog"
compose run --rm -T migrate

say "starting a loopback-only candidate"
candidate="${DBW_PROJECT}-candidate"
docker rm -f "$candidate" >/dev/null 2>&1 || true
compose run -d --name "$candidate" -p "127.0.0.1:$candidate_port:3000" web >/dev/null
candidate_port=$(docker port "$candidate" 3000/tcp | sed -n 's/^127\.0\.0\.1://p')
[ -n "$candidate_port" ] || fail "Docker did not publish a loopback candidate port"
if ! wait_for "http://127.0.0.1:$candidate_port/up" || ! "$bin/check-live.sh" "http://127.0.0.1:$candidate_port"; then
  docker logs "$candidate" 2>&1 | tail -n 20 >&2
  docker rm -f "$candidate" >/dev/null
  fail "the candidate failed its checks; the previous release still serves"
fi
docker rm -f "$candidate" >/dev/null

previous=$(cat "$DBW_ROOT/current-release" 2>/dev/null || true)
say "activating $release${previous:+ (previous: $previous)}"
compose up -d --wait --no-deps web
if ! wait_for "http://127.0.0.1:$DBW_PORT/up" || ! "$bin/check-live.sh" "http://127.0.0.1:$DBW_PORT"; then
  [ -n "$previous" ] || fail "the release failed after activation and there is no previous release"
  say "the release failed after activation; rolling back to $previous"
  DBW_RELEASE=$previous compose up -d --wait --no-deps web
  fail "rolled back to $previous"
fi
[ -n "$previous" ] && [ "$previous" != "$release" ] && printf '%s\n' "$previous" >"$DBW_ROOT/previous-release"
printf '%s\n' "$release" >"$DBW_ROOT/current-release"
ln -sfn "$DBW_RELEASE_DIR" "$DBW_ROOT/current"
say "$release is serving"
