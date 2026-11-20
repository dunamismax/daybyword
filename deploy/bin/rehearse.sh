#!/bin/sh
# Rehearses the whole release cycle on this machine with Docker (BUILD.md
# PM.18), against a throwaway project that touches nothing else: a fresh
# database, deploy (build, roles, migrate, import, candidate, activate,
# check-live), a backup and an isolated restore check, a second deploy over
# the same database, a rollback that keeps the database, and teardown of
# the project's containers, volume, network and images.
#
#   make rehearse-deploy        (after make catalog-export)
set -eu
cd "$(dirname "$0")/../.."
root=$(mktemp -d "${TMPDIR:-/tmp}/dbw-rehearsal.XXXXXX")
free_port() { node -e 'const s=require("node:net").createServer();s.listen(0,"127.0.0.1",()=>{console.log(s.address().port);s.close()})'; }
hex() { node -e 'console.log(require("node:crypto").randomBytes(24).toString("hex"))'; }

DBW_ROOT="$root" DBW_ENV_FILE="$root/env" DBW_BACKUPS="$root/backups"
DBW_PROJECT="dbwrehearsal$$" DBW_PORT=$(free_port) DBW_CANDIDATE_PORT=$(free_port)
DBW_DEPLOY_LOCK="$root/deploy.lock" DBW_RELEASE_DIR=$(pwd) DBW_COMMIT=$(git rev-parse HEAD)
export DBW_ROOT DBW_ENV_FILE DBW_BACKUPS DBW_PROJECT DBW_PORT DBW_CANDIDATE_PORT
export DBW_DEPLOY_LOCK DBW_RELEASE_DIR DBW_COMMIT
umask 077
cat >"$DBW_ENV_FILE" <<ENV
POSTGRES_PASSWORD=$(hex)
DBW_APP_PASSWORD=$(hex)
DBW_MIGRATE_PASSWORD=$(hex)
ENV

commit=$(git rev-parse --short=12 HEAD)
first="$commit-rehearsal-a"
second="$commit-rehearsal-b"
export DBW_RELEASE="$first"
cleanup() {
  DBW_RELEASE=$first docker compose -p "$DBW_PROJECT" -f deploy/compose.yaml --env-file "$DBW_ENV_FILE" \
    --profile jobs down --remove-orphans >/dev/null 2>&1 || true
  docker volume rm "${DBW_PROJECT}_postgres_data" >/dev/null 2>&1 || true
  docker image rm "daybyword-web:$first" "daybyword-web:$second" >/dev/null 2>&1 || true
  rm -rf "$root"
}
trap cleanup EXIT

step() { printf '\n== rehearse: %s\n' "$*"; }
query() {
  docker compose -p "$DBW_PROJECT" -f deploy/compose.yaml --env-file "$DBW_ENV_FILE" \
    exec -T postgres psql -U postgres -d daybyword -At -c "$1"
}

step "first deploy of $first onto a new database"
DBW_RELEASE=$first deploy/bin/deploy.sh
imports=$(query "select count(*) from catalog_imports")

step "nightly backup, then restore it in isolation"
deploy/bin/backup.sh
deploy/bin/restore-check.sh

step "the web role can read and cannot write"
DBW_RELEASE=$first docker compose -p "$DBW_PROJECT" -f deploy/compose.yaml --env-file "$DBW_ENV_FILE" \
  exec -T postgres psql -U postgres -d daybyword -At -c \
  "set role daybyword_app; insert into catalog_current values (1, 1)" >/dev/null 2>&1 &&
  { echo "rehearse: daybyword_app could write" >&2; exit 1; }
echo "rehearse: daybyword_app is refused writes"

step "second deploy of $second over the same database"
DBW_RELEASE=$second deploy/bin/deploy.sh
[ "$(query "select count(*) from catalog_imports")" = "$imports" ] ||
  { echo "rehearse: the re-import was not a no-op" >&2; exit 1; }
echo "rehearse: re-importing the same catalog changed nothing"
find "$DBW_BACKUPS" -name '*.dump' | wc -l | xargs printf 'rehearse: %s backups (one from before the second migration)\n'

step "roll back to $first, keeping the database"
deploy/bin/rollback.sh
[ "$(cat "$DBW_ROOT/current-release")" = "$first" ] || { echo "rehearse: not rolled back" >&2; exit 1; }
[ "$(query "select count(*) from catalog_imports")" = "$imports" ] ||
  { echo "rehearse: the database changed in the rollback" >&2; exit 1; }
docker inspect --format '{{.Config.User}} {{.HostConfig.ReadonlyRootfs}}' "$(docker compose -p "$DBW_PROJECT" -f deploy/compose.yaml --env-file "$DBW_ENV_FILE" ps -q web)" |
  xargs printf 'rehearse: the web runs as %s, read-only root %s\n'
published=$(docker compose -p "$DBW_PROJECT" -f deploy/compose.yaml --env-file "$DBW_ENV_FILE" port postgres 5432 2>/dev/null || true)
case $published in "" | ":0") ;; *) echo "rehearse: PostgreSQL is published at $published" >&2; exit 1 ;; esac
echo "rehearse: PostgreSQL has no host port"

step "logs hold method, route pattern, status and time only"
logs=$(docker compose -p "$DBW_PROJECT" -f deploy/compose.yaml --env-file "$DBW_ENV_FILE" logs --no-log-prefix web)
printf '%s\n' "$logs" | grep -q '^request method=GET route=/plans/\[id=planid\] status=200 ms=' ||
  { echo "rehearse: no route-pattern log line" >&2; exit 1; }
printf '%s\n' "$logs" | grep -q 'gospels-at-your-pace' && { echo "rehearse: a log line holds an address" >&2; exit 1; }
echo "rehearse: the logs name route patterns, never addresses"

printf '\nrehearse: deploy, backup, restore check, redeploy and rollback all passed\n'
