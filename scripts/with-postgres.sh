#!/bin/sh
# Runs a command against a throwaway PostgreSQL cluster: initdb in a new
# temporary directory, listening on a Unix socket there only (no TCP), with
# PGHOST, PGPORT, PGUSER and PGDATABASE exported for the command, then
# stopped and deleted (BUILD.md PM.14). Nothing touches another database.
#
#   scripts/with-postgres.sh COMMAND [ARGUMENTS...]
#
# Needs PostgreSQL's server binaries on the PATH (README.md prerequisites),
# the same major version the deploy image uses (DBW_PG_MAJOR, 17).
set -eu

major=${DBW_PG_MAJOR:-17}
found=$(initdb --version 2>/dev/null | sed -nE 's/.* ([0-9]+)\.[0-9]+.*/\1/p')
if [ "$found" != "$major" ]; then
  echo "with-postgres: needs PostgreSQL $major's initdb and pg_ctl on the PATH, found ${found:-none}" >&2
  echo "with-postgres: on macOS, brew install postgresql@$major and add its bin to the PATH" >&2
  exit 1
fi

# A short path: a Unix socket's path is limited to about 100 bytes.
dir=$(mktemp -d /tmp/dbwpg.XXXXXX)
cleanup() {
  pg_ctl -D "$dir/data" -m immediate stop >/dev/null 2>&1 || true
  rm -rf "$dir"
}
trap cleanup EXIT INT TERM

LC_ALL=C initdb -D "$dir/data" -U postgres -A trust -E UTF8 --locale=C --no-instructions >"$dir/initdb.log" 2>&1 ||
  { cat "$dir/initdb.log" >&2; exit 1; }
LC_ALL=C pg_ctl -D "$dir/data" -l "$dir/server.log" -w -s \
  -o "-c listen_addresses='' -k $dir -p 5432 -c fsync=off -c full_page_writes=off" start ||
  { cat "$dir/server.log" >&2; exit 1; }

PGHOST=$dir PGPORT=5432 PGUSER=postgres PGDATABASE=postgres "$@"
