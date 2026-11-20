#!/bin/sh
# Proves the newest backup restores (docs/deploy.md): checks its SHA-256,
# restores it into a throwaway PostgreSQL 18 container on no network at all,
# recreates the roles from web/db/roles.sql, and checks the migrations and
# the current catalog against the backup's manifest. The live database is
# never touched. Run monthly by daybyword-restore-check.timer, and before
# the first deploy.
set -eu
# shellcheck source=deploy/bin/common.sh
. "$(dirname "$0")/common.sh"

dump=$(ls -1 "$DBW_BACKUPS"/daybyword-*.dump 2>/dev/null | sort | tail -n 1)
[ -n "$dump" ] || fail "no backup in $DBW_BACKUPS"
base=${dump%.dump}
(cd "$DBW_BACKUPS" && { sha256sum -c "$(basename "$base").sha256" 2>/dev/null ||
  shasum -a 256 -c "$(basename "$base").sha256"; }) >/dev/null || fail "$dump does not match its checksum"

image=$(sed -n 's/^ *image: \(postgres:.*\)$/\1/p' "$DBW_RELEASE_DIR/deploy/compose.yaml" | head -n 1)
[ -n "$image" ] || fail "no PostgreSQL image in deploy/compose.yaml"
container="${DBW_PROJECT}-restore-check-$$"
trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT
docker run -d --name "$container" --network none \
  -e POSTGRES_DB=daybyword -e POSTGRES_PASSWORD=restore-check-only \
  "$image" >/dev/null
i=0
until docker exec "$container" pg_isready -U postgres -d daybyword >/dev/null 2>&1; do
  i=$((i + 1)); [ "$i" -le 60 ] || fail "the throwaway database did not start"; sleep 1
done
# The image's init runs once more after its first readiness; wait for the real start.
sleep 2
until docker exec "$container" pg_isready -U postgres -d daybyword >/dev/null 2>&1; do sleep 1; done

docker exec -i "$container" psql -v ON_ERROR_STOP=1 -U postgres -d daybyword -q \
  <"$DBW_RELEASE_DIR/web/db/roles.sql" >/dev/null
docker exec -i "$container" pg_restore -U postgres -d daybyword --exit-on-error <"$dump"

query() { docker exec "$container" psql -v ON_ERROR_STOP=1 -U postgres -d daybyword -At -c "$1"; }
migrations=$(query "select count(*) from drizzle.__drizzle_migrations")
catalog=$(query "select i.content_sha256 from catalog_current c join catalog_imports i on i.id = c.import_id")
readable=$(docker exec "$container" psql -v ON_ERROR_STOP=1 -U daybyword_app -d daybyword -At -c "select count(*) from plans")
expected_migrations=$(sed -n 's/.*"migrations": \([0-9]*\).*/\1/p' "$base.json")
expected_catalog=$(sed -n 's/.*"catalogSha256": "\([0-9a-f]*\)".*/\1/p' "$base.json")
[ "$migrations" = "$expected_migrations" ] || fail "restored $migrations migrations, the manifest says $expected_migrations"
[ "$catalog" = "$expected_catalog" ] || fail "restored catalog $catalog, the manifest says $expected_catalog"
say "$(basename "$dump") restores: $migrations migrations, catalog ${catalog%"${catalog#????????????}"}…, $readable plan(s) readable as daybyword_app"
