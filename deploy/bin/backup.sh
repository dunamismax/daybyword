#!/bin/sh
# Backs up this project's database (docs/deploy.md, "Backups and jobs"): a
# custom-format pg_dump from inside its container, with a SHA-256 and a
# manifest of when, which release, which migrations and which catalog, kept
# in shared/backups (0700) for 14 days. Run nightly by
# daybyword-backup.timer; the off-server, encrypted copy is the host's
# ubuntu-vm-backup entry for shared/backups (P7.3). Fails loudly, so systemd
# records the failure.
set -eu
# shellcheck source=deploy/bin/common.sh
. "$(dirname "$0")/common.sh"

umask 077
mkdir -p "$DBW_BACKUPS"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
name="daybyword-$stamp"
partial="$DBW_BACKUPS/.$name.dump.partial"
trap 'rm -f "$partial"' EXIT

compose exec -T postgres pg_dump -U postgres -d daybyword --format=custom --compress=6 >"$partial"
[ -s "$partial" ] || fail "pg_dump wrote nothing"
mv "$partial" "$DBW_BACKUPS/$name.dump"

migrations=$(psql_admin -c "select count(*) from drizzle.__drizzle_migrations")
catalog=$(psql_admin -c "select i.content_sha256 from catalog_current c join catalog_imports i on i.id = c.import_id")
release=$(cat "$DBW_ROOT/current-release" 2>/dev/null || echo unknown)
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$DBW_BACKUPS" && sha256sum "$name.dump") >"$DBW_BACKUPS/$name.sha256"
else
  (cd "$DBW_BACKUPS" && shasum -a 256 "$name.dump") >"$DBW_BACKUPS/$name.sha256"
fi
cat >"$DBW_BACKUPS/$name.json" <<JSON
{ "created": "$stamp", "release": "$release", "migrations": ${migrations:-0},
  "catalogSha256": "${catalog:-none}", "postgres": 18, "format": "pg_dump custom",
  "bytes": $(wc -c <"$DBW_BACKUPS/$name.dump" | tr -d ' ') }
JSON

# Keep 14 days: remove only this script's own older files.
find "$DBW_BACKUPS" -maxdepth 1 -type f -name 'daybyword-*' -mtime +14 -delete
say "wrote $DBW_BACKUPS/$name.dump ($(wc -c <"$DBW_BACKUPS/$name.dump" | tr -d ' ') bytes)"
