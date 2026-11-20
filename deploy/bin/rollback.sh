#!/bin/sh
# Switches the web service back to the previous release's image (docs/deploy.md,
# "Release and rollback"), keeping the database as it is: migrations are
# additive while two builds may share it (E35), so the previous release
# still reads it. Never restores a backup over the live database and never
# removes a volume.
#
#   DBW_DEPLOY_LOCK=<the host's lock> deploy/bin/rollback.sh
set -eu
# shellcheck source=deploy/bin/common.sh
. "$(dirname "$0")/common.sh"

lock=${DBW_DEPLOY_LOCK:?DBW_DEPLOY_LOCK names the host\'s shared deploy lock (P7.1)}
if command -v flock >/dev/null 2>&1; then
  exec 9>"$lock"
  flock -w 900 9 || fail "could not take the deploy lock $lock"
else
  until mkdir "$lock.d" 2>/dev/null; do sleep 1; done
  trap 'rmdir "$lock.d"' EXIT
fi

previous=$(cat "$DBW_ROOT/previous-release" 2>/dev/null || true)
current=$(cat "$DBW_ROOT/current-release" 2>/dev/null || true)
[ -n "$previous" ] || fail "there is no previous release"
docker image inspect "daybyword-web:$previous" >/dev/null 2>&1 || fail "the image daybyword-web:$previous is gone"

say "switching from $current to $previous"
DBW_RELEASE=$previous compose up -d --wait --no-deps web
wait_for "http://127.0.0.1:$DBW_PORT/up" || fail "$previous did not become ready"
"$(dirname "$0")/check-live.sh" "http://127.0.0.1:$DBW_PORT"
printf '%s\n' "$previous" >"$DBW_ROOT/current-release"
printf '%s\n' "$current" >"$DBW_ROOT/previous-release"
say "$previous is serving; $current can be deployed again later"
