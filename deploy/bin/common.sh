# Shared settings for deploy/bin/*.sh (docs/deploy.md). Sourced, not run.
# Every path and name can be overridden, so the rehearsal (rehearse.sh) runs
# the same scripts against a throwaway project on this machine.
DBW_ROOT=${DBW_ROOT:-/srv/www/daybyword.com}
DBW_ENV_FILE=${DBW_ENV_FILE:-$DBW_ROOT/shared/env}
DBW_BACKUPS=${DBW_BACKUPS:-$DBW_ROOT/shared/backups}
DBW_PROJECT=${DBW_PROJECT:-daybyword}
DBW_PORT=${DBW_PORT:-4318}
# The release directory these scripts belong to: deploy/bin/../..
DBW_RELEASE_DIR=${DBW_RELEASE_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}
# The release Compose names in its image tags: the one serving, unless a
# script is given another (deploy.sh, rollback.sh).
DBW_RELEASE=${DBW_RELEASE:-$(cat "$DBW_ROOT/current-release" 2>/dev/null || echo none)}
export DBW_PROJECT DBW_PORT DBW_RELEASE

# Takes the host's shared deploy lock (P7.1: /run/web-deploy/lock, which
# `with-deploy-lock COMMAND` holds on fd 9 for the whole command), or
# accepts it when the caller already holds it that way.
take_lock() {
  lock=$1
  if [ -e "/proc/$$/fd/9" ] && [ "$(readlink "/proc/$$/fd/9")" = "$lock" ]; then return 0; fi
  if command -v flock >/dev/null 2>&1; then
    exec 9<"$lock"
    flock -w 900 9 || fail "could not take the deploy lock $lock"
  else
    until mkdir "$lock.d" 2>/dev/null; do sleep 1; done
    trap 'rmdir "$lock.d"' EXIT
  fi
}

say() { printf '%s: %s\n' "$(basename "$0" .sh)" "$*"; }
fail() { printf '%s: %s\n' "$(basename "$0" .sh)" "$*" >&2; exit 1; }

# Compose for this project, from a release directory (default: this one).
compose_in() {
  release_dir=$1
  shift
  docker compose -p "$DBW_PROJECT" -f "$release_dir/deploy/compose.yaml" --env-file "$DBW_ENV_FILE" "$@"
}
compose() { compose_in "$DBW_RELEASE_DIR" "$@"; }

# psql as the superuser inside this project's database container.
psql_admin() { compose exec -T postgres psql -v ON_ERROR_STOP=1 -U postgres -d daybyword -At "$@"; }

# Waits until URL answers 200, or fails after about 30 seconds.
wait_for() {
  i=0
  until curl -fsS -o /dev/null "$1" 2>/dev/null; do
    i=$((i + 1))
    [ "$i" -le 60 ] || return 1
    sleep 0.5
  done
}
