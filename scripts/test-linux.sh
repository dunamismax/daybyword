#!/bin/sh
# Builds and tests the shared packages and the server on Linux, in a container
# with the toolchain pinned in .swift-version (BUILD.md P1.6). The repository
# is mounted read-only; build products live in a named volume between runs.
set -eu
cd "$(dirname "$0")/.."

runtime=${CONTAINER_RUNTIME:-docker}
if ! command -v "$runtime" >/dev/null 2>&1 || ! "$runtime" info >/dev/null 2>&1; then
  echo "test-linux: no running container runtime ($runtime); start Docker or Colima, or set CONTAINER_RUNTIME" >&2
  exit 1
fi

version=$(cat .swift-version)
image="daybyword-linux:$version"

echo "test-linux: preparing $image"
"$runtime" build --quiet --build-arg "SWIFT_VERSION=$version" --tag "$image" scripts/linux >/dev/null

"$runtime" run --rm \
  --volume "$PWD:/src:ro" \
  --volume "daybyword-linux-build-$version:/scratch" \
  "$image" sh -euc '
    swift --version
    for package in ReadingEngine ReadingData CatalogCompiler; do
      echo "== $package"
      swift test --package-path "/src/Packages/$package" --scratch-path "/scratch/$package"
    done
    echo "== Server"
    swift test --package-path /src/Server --scratch-path /scratch/Server --force-resolved-versions
  '
