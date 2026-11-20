#!/bin/sh
# Switches the web service back to the previous release's image (docs/deploy.md,
# "Release and rollback"), keeping the database as it is: migrations are
# additive while two builds may share it (E35), so the previous release
# still reads it. Never restores a backup over the live database and never
# removes a volume.
#
#   with-deploy-lock deploy/bin/rollback.sh
set -eu
# shellcheck source=deploy/bin/common.sh
. "$(dirname "$0")/common.sh"

lock=${DBW_DEPLOY_LOCK:-/run/astro-deploy/lock}
take_lock "$lock"

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
