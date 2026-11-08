#!/bin/sh
# Fails unless the Swift compiler on the PATH is the version pinned in
# .swift-version, so this Mac, CI, and the server build with the same
# toolchain (BUILD.md P1.6), and that Node and npm are the versions
# .node-version and web/package.json pin (PM.13).
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
npm_pinned=$(sed -nE 's/.*"packageManager": "npm@([0-9.]+)".*/\1/p' web/package.json)
npm_found=$(npm --version 2>/dev/null)
if [ "$npm_found" != "$npm_pinned" ]; then
  echo "check-toolchain: web/package.json pins npm $npm_pinned, but npm is ${npm_found:-missing}" >&2
  exit 1
fi
echo "check-toolchain: Node $node_found, npm $npm_found"
