#!/bin/sh
# Exports build/DayByWord.xcarchive for App Store Connect and uploads it, using
# the Apple ID that Xcode is signed in with (D33). App Store Connect then
# processes the build for TestFlight (docs/release.md).
set -eu
cd "$(dirname "$0")/.."

if [ ! -d build/DayByWord.xcarchive ]; then
  echo "testflight: no archive; run make archive first" >&2
  exit 1
fi

mkdir -p build/logs
rm -rf build/export
xcodebuild -exportArchive \
  -archivePath build/DayByWord.xcarchive \
  -exportOptionsPlist apple/Config/ExportOptions.plist \
  -exportPath build/export \
  -allowProvisioningUpdates >build/logs/testflight.log 2>&1 || {
  grep -E 'error|Error' build/logs/testflight.log >&2 || true
  echo "testflight: upload failed; the full log is build/logs/testflight.log" >&2
  exit 1
}
grep -E 'Upload succeeded|EXPORT SUCCEEDED|Uploaded' build/logs/testflight.log || true
echo "testflight: uploaded; App Store Connect will email when the build has been processed"
