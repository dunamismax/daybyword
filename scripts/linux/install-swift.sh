#!/bin/sh
# Installs a Swift toolchain release for Ubuntu 24.04 into <prefix>/<version>,
# after checking its signature against swift.org's public signing keys kept
# beside this script (swift-signing-keys.asc). Used by the Linux test image,
# CI, and the server, so all three run the compiler pinned in .swift-version
# (docs/decisions.md E22). Needs curl, gpg, and tar; the toolchain's own
# system packages are installed separately (scripts/linux/Dockerfile lists them).
#
#   install-swift.sh 6.4.2 /opt/swift   # then /opt/swift/6.4.2/usr/bin/swift
set -eu

version=${1:?usage: install-swift.sh <version> [prefix]}
prefix=${2:-/opt/swift}
keys="$(cd "$(dirname "$0")" && pwd)/swift-signing-keys.asc"

case $(uname -m) in
  x86_64) platform=ubuntu2404 suffix=ubuntu24.04 ;;
  aarch64 | arm64) platform=ubuntu2404-aarch64 suffix=ubuntu24.04-aarch64 ;;
  *) echo "install-swift: unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac

release="swift-$version-RELEASE"
url="https://download.swift.org/swift-$version-release/$platform/$release/$release-$suffix.tar.gz"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
GNUPGHOME="$work/gnupg"
export GNUPGHOME
mkdir -m 700 "$GNUPGHOME"

gpg --batch --quiet --import "$keys"
curl -fsSL --retry 3 -o "$work/swift.tar.gz" "$url"
curl -fsSL --retry 3 -o "$work/swift.tar.gz.sig" "$url.sig"
gpg --batch --verify "$work/swift.tar.gz.sig" "$work/swift.tar.gz"

rm -rf "${prefix:?}/$version"
mkdir -p "$prefix/$version"
tar -xzf "$work/swift.tar.gz" -C "$prefix/$version" --strip-components=1
"$prefix/$version/usr/bin/swift" --version
