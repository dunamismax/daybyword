#!/bin/sh
# Runs once, when the database volume is new (the image's initdb hook): the
# project's two roles from web/db/roles.sql, and their passwords from the
# container's environment, never from a file in the repository.
set -eu
psql -v ON_ERROR_STOP=1 --username postgres --dbname daybyword -f /etc/daybyword/roles.sql
psql -v ON_ERROR_STOP=1 --username postgres --dbname daybyword \
  -v app="$DBW_APP_PASSWORD" -v migrate="$DBW_MIGRATE_PASSWORD" <<'SQL'
ALTER ROLE daybyword_app PASSWORD :'app';
ALTER ROLE daybyword_migrate PASSWORD :'migrate';
SQL
