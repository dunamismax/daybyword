#!/bin/sh
# Runs a command with the web's database as a deploy leaves it: a throwaway
# PostgreSQL (scripts/with-postgres.sh) holding this project's roles, every
# migration, and the release catalog's export, with DATABASE_URL naming
# it for the read-only web role. So `make serve-web`, the production tests
# and the web tour see the plans the way daybyword.com serves them, through
# the same code (BUILD.md P8.10). Everything is deleted when the command ends.
#
#   scripts/with-catalog.sh COMMAND [ARGUMENTS...]
#
# Needs build/catalog/catalog-export.json (make catalog-export).
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
export="${DBW_CATALOG_EXPORT:-$root/build/catalog/catalog-export.json}"
[ -f "$export" ] || { echo "with-catalog: no $export; run make catalog-export" >&2; exit 1; }

if [ "${DBW_WITH_CATALOG:-}" != "inside" ]; then
  DBW_WITH_CATALOG=inside DBW_CATALOG_EXPORT="$export" exec "$root/scripts/with-postgres.sh" "$0" "$@"
fi

# Inside with-postgres.sh: PGHOST is the cluster's socket directory.
createdb daybyword
psql -q -v ON_ERROR_STOP=1 -d daybyword -f "$root/web/db/roles.sql" >/dev/null
(
  cd "$root/web"
  export PGDATABASE=daybyword PGUSER=daybyword_migration DB_OWNER_ROLE=daybyword_owner
  node scripts/db-migrate.ts >/dev/null
  node scripts/catalog-import.ts "$export" >/dev/null
)
# pg reads the socket directory from the URL's host parameter.
DATABASE_URL="postgresql://daybyword_web@localhost/daybyword?host=$PGHOST" "$@"
