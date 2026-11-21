#!/bin/sh
# Proves the newest backup restores (docs/deploy.md, "Backups"): checks its
# SHA-256, restores it into a throwaway PostgreSQL 18 cluster that listens on
# no TCP port at all (a Unix socket in a private directory, run by the
# postgres account and deleted afterwards), recreates the roles from
# db/roles.sql, and checks the migrations and the current catalog against the
# backup's manifest and that the web role can read the plans. The live
# database is never touched. Run monthly by daybyword-restore-check.timer, as
# root.
set -eu
# shellcheck source=deploy/bin/common.sh
. "$(dirname "$0")/common.sh"

[ "$(id -u)" = 0 ] || fail "run as root"
dump=$(ls -1 "$DBW_BACKUPS"/daybyword-*.dump 2>/dev/null | sort | tail -n 1)
[ -n "$dump" ] || fail "no backup in $DBW_BACKUPS"
base=${dump%.dump}
(cd "$DBW_BACKUPS" && sha256sum -c "$(basename "$base").sha256" >/dev/null 2>&1) ||
  fail "$dump does not match its checksum"
check_dump "$dump" || fail "$dump failed its check"

work=$(mktemp -d /var/tmp/daybyword-restore-check.XXXXXX)
chown postgres:postgres "$work"
chmod 0700 "$work"
pg() { runuser -u postgres -- env PATH="$DBW_PG_BIN:/usr/bin:/bin" "$@"; }
cleanup() {
  pg pg_ctl -D "$work/data" -m immediate stop >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT INT TERM

pg initdb -D "$work/data" -U postgres -A trust -E UTF8 --locale=C --no-instructions >"$work/initdb.log" 2>&1 ||
  fail "the throwaway cluster did not initialise"
pg pg_ctl -D "$work/data" -l "$work/server.log" -w -s \
  -o "-c listen_addresses='' -k $work -p 5432 -c fsync=off" start || fail "the throwaway cluster did not start"
q() { pg psql -X -v ON_ERROR_STOP=1 -h "$work" -p 5432 "$@"; }

q -U postgres -d postgres -qc "create database $DBW_DATABASE"
q -U postgres -d "$DBW_DATABASE" -q <"$DBW_RELEASE_DIR/db/roles.sql" >/dev/null
pg pg_restore -h "$work" -p 5432 -U postgres -d "$DBW_DATABASE" --exit-on-error <"$dump"

migrations=$(q -U postgres -d "$DBW_DATABASE" -At -c "select count(*) from drizzle.__drizzle_migrations")
catalog=$(PGOPTIONS="-c search_path=app,public" q -U postgres -d "$DBW_DATABASE" -At -c "select i.content_sha256 from catalog_current c join catalog_imports i on i.id = c.import_id")
readable=$(q -U daybyword_web -d "$DBW_DATABASE" -At -c "select count(*) from plans")
expected_migrations=$(sed -n 's/.*"migrations": \([0-9]*\).*/\1/p' "$base.json")
expected_catalog=$(sed -n 's/.*"catalogSha256": "\([0-9a-f]*\)".*/\1/p' "$base.json")
[ "$migrations" = "$expected_migrations" ] || fail "restored $migrations migrations, the manifest says $expected_migrations"
[ "$catalog" = "$expected_catalog" ] || fail "restored catalog $catalog, the manifest says $expected_catalog"
[ "$readable" -gt 0 ] || fail "the web role reads no plans from the restored database"
say "$(basename "$dump") restores: $migrations migrations, catalog ${catalog%"${catalog#????????????}"}…, $readable plan(s) readable as daybyword_web"
