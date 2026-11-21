#!/bin/sh
# Backs up this project's database (docs/deploy.md, "Backups"): a
# custom-format pg_dump of `daybyword` on the server's PostgreSQL cluster,
# taken as the postgres superuser, with a SHA-256 and a manifest of when,
# which release, which migrations and which catalog, kept in shared/backups
# (0700) for 14 days. Run nightly by daybyword-backup.timer and before every
# migration by deploy/bin/activate.sh, as root. The off-server, encrypted copy
# is ubuntu-vm-backup's daily dump of every database in the cluster. Fails
# loudly, so systemd records the failure, and never leaves a dump it has not
# checked.
set -eu
# shellcheck source=deploy/bin/common.sh
. "$(dirname "$0")/common.sh"

[ "$(id -u)" = 0 ] || fail "run as root"
umask 077
mkdir -p "$DBW_BACKUPS"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
name="daybyword-$stamp"
partial="$DBW_BACKUPS/.$name.dump.partial"
trap 'rm -f "$partial"' EXIT

runuser -u postgres -- pg_dump --format=custom --compress=6 --dbname="$DBW_DATABASE" >"$partial" ||
  fail "pg_dump of $DBW_DATABASE failed; no backup was written"
check_dump "$partial" || fail "the dump failed its check; no backup was written"
mv "$partial" "$DBW_BACKUPS/$name.dump"

migrations=$(psql_admin -c "select count(*) from drizzle.__drizzle_migrations")
catalog=$(psql_admin -c "select i.content_sha256 from app.catalog_current c join app.catalog_imports i on i.id = c.import_id")
release=$(cat "$DBW_ROOT/current/REVISION" 2>/dev/null || echo unknown)
(cd "$DBW_BACKUPS" && sha256sum "$name.dump") >"$DBW_BACKUPS/$name.sha256"
cat >"$DBW_BACKUPS/$name.json" <<JSON
{ "created": "$stamp", "release": "$release", "migrations": ${migrations:-0},
  "catalogSha256": "${catalog:-none}", "postgres": 18, "format": "pg_dump custom",
  "bytes": $(wc -c <"$DBW_BACKUPS/$name.dump" | tr -d ' ') }
JSON

# Keep 14 days: remove only this script's own older files.
find "$DBW_BACKUPS" -maxdepth 1 -type f -name 'daybyword-*' -mtime +14 -delete
say "wrote $DBW_BACKUPS/$name.dump ($(wc -c <"$DBW_BACKUPS/$name.dump" | tr -d ' ') bytes, $migrations migrations)"
