# Shared settings for deploy/bin/*.sh (docs/deploy.md). Sourced, not run.
DBW_SITE=daybyword.com
DBW_ROOT=${DBW_ROOT:-/srv/www/daybyword.com}
DBW_BACKUPS=${DBW_BACKUPS:-$DBW_ROOT/shared/backups}
DBW_DATABASE=daybyword
DBW_UNIT=daybyword-web
DBW_ACCOUNT=daybyword-web
DBW_PORT=4318
DBW_ENV_DIR=/etc/web-apps/daybyword
DBW_NODE=/opt/node-26/bin/node
# PostgreSQL 18's own programs (initdb and pg_ctl for the restore check).
DBW_PG_BIN=/usr/lib/postgresql/18/bin
# The release directory these scripts belong to: deploy/bin/../..
DBW_RELEASE_DIR=${DBW_RELEASE_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}

say() { printf '%s: %s\n' "$(basename "$0" .sh)" "$*"; }
fail() { printf '%s: %s\n' "$(basename "$0" .sh)" "$*" >&2; exit 1; }

# The caller already holds the host's deploy lock on fd 9
# (`with-deploy-lock COMMAND`), or this stops.
require_lock() {
  [ "$(readlink "/proc/$$/fd/9" 2>/dev/null)" = /run/web-deploy/lock ] && flock -n 9 ||
    fail "run inside the deploy lock: with-deploy-lock $0 ..."
}

# psql as the cluster's superuser, on the server's own database.
psql_admin() { runuser -u postgres -- psql -X -v ON_ERROR_STOP=1 -d "$DBW_DATABASE" -At "$@"; }

# Waits until URL answers 200, or fails after about 30 seconds.
wait_for() {
  i=0
  until curl -fsS -o /dev/null "$1" 2>/dev/null; do
    i=$((i + 1))
    [ "$i" -le 60 ] || return 1
    sleep 0.5
  done
}

# Exits non-zero unless FILE is a pg_dump archive pg_restore can read with at
# least one table in it. A shell redirect creates its file before the command
# runs, so a failed pg_dump leaves an empty file; this is what refuses it.
check_dump() {
  [ -s "$1" ] || { echo "$1 is empty" >&2; return 1; }
  pg_restore --list "$1" >/dev/null 2>&1 || { echo "$1 is not a readable pg_dump archive" >&2; return 1; }
  pg_restore --list "$1" | awk '$1 ~ /^[0-9]+;$/ && $4 == "TABLE" && $5 != "DATA" { n++ } END { exit n > 0 ? 0 : 1 }' ||
    { echo "$1 holds no tables" >&2; return 1; }
}
