#!/bin/sh
# Fails unless the Swift compiler on the PATH is the version pinned in
# .swift-version, so this Mac and CI build with the same
# toolchain (BUILD.md P1.6), and that Node and pnpm are the versions
# .node-version and web/package.json pin (the host's web platform contract).
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

node_pinned=$(cat .node-version)
node_found=$(node --version 2>/dev/null | sed 's/^v//')
if [ "$node_found" != "$node_pinned" ]; then
  echo "check-toolchain: .node-version pins Node $node_pinned, but node is ${node_found:-missing}" >&2
  echo "check-toolchain: install it from nodejs.org or with a version manager that reads .node-version" >&2
  exit 1
fi
pnpm_pinned=$(sed -nE 's/.*"packageManager": "pnpm@([0-9.]+)".*/\1/p' web/package.json)
pnpm_found=$(cd web && pnpm --version 2>/dev/null)
if [ "$pnpm_found" != "$pnpm_pinned" ]; then
  echo "check-toolchain: web/package.json pins pnpm $pnpm_pinned, but pnpm is ${pnpm_found:-missing}" >&2
  echo "check-toolchain: install that pnpm (a native executable; no Corepack)" >&2
  exit 1
fi
echo "check-toolchain: Node $node_found, pnpm $pnpm_found"
