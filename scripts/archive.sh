#!/bin/sh
# Builds a signed Release archive of the app with the release-checked catalog,
# from a clean, committed working tree, numbered by the commit count of HEAD
# (docs/release.md).
set -eu
cd "$(dirname "$0")/.."

if [ ! -f apple/Config/Secrets.xcconfig ] || ! grep -Eq '^DEVELOPMENT_TEAM *= *[A-Z0-9]+' apple/Config/Secrets.xcconfig; then
  echo "archive: set DEVELOPMENT_TEAM in apple/Config/Secrets.xcconfig (see Secrets.example.xcconfig)" >&2
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "archive: commit or stash your changes first; an archive is built from a committed state" >&2
  exit 1
fi

build_number=$(git rev-list --count HEAD)
commit=$(git rev-parse --short HEAD)
echo "archive: build $build_number from $commit"

make generate RELEASE=1
rm -rf build/DayByWord.xcarchive
scripts/xcodebuild.sh archive \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath build/DayByWord.xcarchive \
  -allowProvisioningUpdates \
  CURRENT_PROJECT_VERSION="$build_number" \
  archive
echo "archive: build/DayByWord.xcarchive (build $build_number, $commit)"
