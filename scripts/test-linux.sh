#!/bin/sh
# Builds and tests the shared Swift packages on Linux, in a container
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

# The image is rebuilt only when what it is made from changes: the toolchain
# version and the files in scripts/linux, whose checksum the image carries as
# a label. An unchanged image is reused without asking the registry, so the
# tests still run when Docker Hub cannot be reached.
inputs=$( (echo "$version"; cat scripts/linux/Dockerfile scripts/linux/install-swift.sh scripts/linux/swift-signing-keys.asc) | shasum -a 256 | cut -d' ' -f1)
built=$("$runtime" image inspect --format '{{ index .Config.Labels "com.daybyword.inputs" }}' "$image" 2>/dev/null || true)
if [ "$built" = "$inputs" ]; then
  echo "test-linux: using $image (unchanged)"
else
  echo "test-linux: preparing $image"
  mkdir -p build/logs
  if ! "$runtime" build --progress=plain --build-arg "SWIFT_VERSION=$version" \
    --label "com.daybyword.inputs=$inputs" --tag "$image" scripts/linux \
    >build/logs/linux-image.log 2>&1; then
    tail -n 60 build/logs/linux-image.log >&2
    echo "test-linux: building $image failed; the full log is build/logs/linux-image.log" >&2
    exit 1
  fi
fi

"$runtime" run --rm \
  --volume "$PWD:/src:ro" \
  --volume "daybyword-linux-build-$version:/scratch" \
  "$image" sh -euc '
    swift --version
    for package in ReadingEngine ReadingData CatalogCompiler; do
      echo "== $package"
      swift test --package-path "/src/Packages/$package" --scratch-path "/scratch/$package"
    done
  '
