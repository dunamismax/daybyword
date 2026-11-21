#!/bin/sh
# Builds and checks one release on the server, as the checkout owner,
# outside the deploy lock (docs/deploy.md, "Deploying"); nothing on the host
# changes here. deploy/bin/release.sh runs it with the pinned toolchain:
#
#   node-26 deploy/bin/build-release.sh COMMIT EXPORT.json
#
# COMMIT must be origin/main; EXPORT.json is the release catalog export that
# `make catalog-export` built from that commit on the Mac (the catalog
# compiler is Swift). The release is `git archive COMMIT` of web/ with:
# pnpm install --frozen-lockfile; `pnpm run check`, `lint` and `test`; the
# database tests and the production server's tests in throwaway PostgreSQL 18
# clusters; the adapter-node build; and production dependencies only. It is
# assembled in /home/sawyer/web-work/daybyword.com-COMMIT/release:
#
#   REVISION .node-version package.json node_modules/ build/ server.ts
#   scripts/ src/lib/ drizzle/ db/roles.sql catalog/catalog-export.json deploy/
set -eu
commit=${1:?usage: build-release.sh COMMIT EXPORT.json}
export_file=${2:?usage: build-release.sh COMMIT EXPORT.json}
repo=${DBW_REPO:-/home/sawyer/github/daybyword}
fail() { echo "build-release: $*" >&2; exit 1; }
say() { echo "== $*"; }
[ "$(id -u)" != 0 ] || fail "build as the checkout owner, not root"
[ -f "$export_file" ] || fail "no catalog export at $export_file"
git -C "$repo" fetch -q origin
[ "$(git -C "$repo" rev-parse origin/main)" = "$commit" ] || fail "$commit is not origin/main"
work=/home/sawyer/web-work/daybyword.com-$commit
[ ! -e "$work/src" ] || fail "$work/src exists; remove it or deploy another commit"

say "archive $commit"
mkdir -p "$work/src"
git -C "$repo" archive "$commit" | tar -x -C "$work/src"
cd "$work/src"
[ "$(node --version)" = "v$(cat .node-version)" ] || fail "Node $(cat .node-version) required, found $(node --version) (run through node-26)"
[ "$(cd web && pnpm --version)" = "$(sed -nE 's/.*"packageManager": "pnpm@([0-9.]+)".*/\1/p' web/package.json)" ] ||
  fail "pnpm does not match web/package.json's packageManager"
export PATH="/usr/lib/postgresql/18/bin:$PATH" DBW_PG_MAJOR=18
mkdir -p build/catalog
cp "$export_file" build/catalog/catalog-export.json
export_path="$work/src/build/catalog/catalog-export.json"

cd web
say "install"
pnpm install --frozen-lockfile --reporter=silent
say "check, lint, test"
pnpm run check
pnpm run lint
pnpm run test
node scripts/catalog-import.ts --check "$export_path"
say "database tests (throwaway PostgreSQL 18)"
DBW_TEST_DB=1 DBW_REPOSITORY_EXPORT="$export_path" ../scripts/with-postgres.sh pnpm exec vitest run
say "build and the production server's tests"
pnpm exec vite build --logLevel warn
../scripts/web-smoke.sh
DBW_CATALOG_EXPORT="$export_path" ../scripts/with-catalog.sh sh -c 'DBW_TEST_BUILD=1 pnpm exec vitest run'
cd ..

say "assemble $work/release"
release=$work/release
rm -rf "$release" "$work/prod"
mkdir -p "$release/scripts" "$release/src" "$release/db" "$release/catalog" "$work/prod"
cp web/package.json web/pnpm-lock.yaml web/pnpm-workspace.yaml "$work/prod/"
# Production dependencies only; no install scripts (svelte-kit sync is a
# development step).
(cd "$work/prod" && pnpm install --frozen-lockfile --prod --ignore-scripts --reporter=silent)
cp -a "$work/prod/node_modules" web/package.json web/build web/server.ts web/drizzle "$release/"
cp web/scripts/db-migrate.ts web/scripts/catalog-import.ts "$release/scripts/"
cp -a web/src/lib "$release/src/lib"
cp web/db/roles.sql "$release/db/roles.sql"
cp "$export_path" "$release/catalog/catalog-export.json"
cp -a deploy "$release/deploy"
cp .node-version "$release/.node-version"
printf '%s\n' "$commit" >"$release/REVISION"
for file in build/handler.js server.ts scripts/db-migrate.ts drizzle/meta/_journal.json catalog/catalog-export.json; do
  [ -f "$release/$file" ] || fail "the release is missing $file"
done
[ ! -e "$release/node_modules/vitest" ] || fail "development dependencies reached the release"
echo "built $commit: $release"
