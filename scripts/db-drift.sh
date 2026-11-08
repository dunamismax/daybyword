#!/bin/sh
# Fails if web/src/db/schema.ts holds a change that no committed migration in
# web/drizzle/ does, or if drizzle-kit finds the migrations inconsistent
# (BUILD.md PM.14). It generates into a copy, so web/drizzle/ is untouched.
set -eu
cd "$(dirname "$0")/../web"

# drizzle-kit wants a path relative to web/, inside the ignored build/.
mkdir -p ../build
copy=$(mktemp -d ../build/drizzle-drift.XXXXXX)
trap 'rm -rf "$copy"' EXIT INT TERM
cp -R drizzle/. "$copy/"
before=$(cd "$copy" && find . -type f | sort | xargs cat | shasum -a 256)
DBW_DRIZZLE_OUT="$copy" npx drizzle-kit check >/dev/null
DBW_DRIZZLE_OUT="$copy" npx drizzle-kit generate --name drift >/dev/null
after=$(cd "$copy" && find . -type f | sort | xargs cat | shasum -a 256)
if [ "$before" != "$after" ]; then
  echo "db-drift: web/src/db/schema.ts has changes with no migration; run make db-generate NAME=… and review the SQL" >&2
  exit 1
fi
echo "db-drift: the schema and web/drizzle/ agree"
