#!/bin/sh
# Fails unless the Swift compiler on the PATH is the version pinned in
# .swift-version, so this Mac, CI, and the server build with the same
# toolchain (BUILD.md P1.6).
set -eu
cd "$(dirname "$0")/.."

pinned=$(cat .swift-version)
found=$(swift --version 2>/dev/null | sed -nE 's/.*Swift version ([0-9]+(\.[0-9]+)*).*/\1/p' | head -n 1)

if [ "$found" != "$pinned" ]; then
  echo "check-toolchain: .swift-version pins Swift $pinned, but swift is ${found:-missing}" >&2
  echo "check-toolchain: on macOS select the Xcode that ships it (xcode-select); on Linux run swiftly install" >&2
  exit 1
fi
echo "check-toolchain: Swift $found"
