#!/bin/sh
# Runs xcodebuild for the Day by Word project, keeps the full log in
# build/logs/, prints only errors, warnings, and test results, and fails if
# the build printed a warning (AGENTS.md §7: zero warnings in touched targets).
#
#   scripts/xcodebuild.sh <log-name> <xcodebuild arguments…>
set -eu
cd "$(dirname "$0")/.."

name=$1
shift
mkdir -p build/logs
log="build/logs/$name.log"

status=0
xcodebuild -project apple/DayByWord.xcodeproj -scheme DayByWord -derivedDataPath build/DerivedData "$@" >"$log" 2>&1 || status=$?

# Summarize: compiler diagnostics, test outcomes, and the final verdict.
grep -E '(error|warning):|✔ Test run|✘|Test Case .*(passed|failed)|Executed [0-9]+ test|\*\* .* \*\*' "$log" |
  grep -v 'appintentsmetadataprocessor' || true

if [ "$status" -ne 0 ]; then
  echo "xcodebuild failed; the full log is $log" >&2
  exit "$status"
fi

# The App Intents metadata tool reports "no AppIntents.framework dependency"
# as a warning until the app uses App Intents (BUILD.md P8.9); it is not a
# compiler warning.
if grep -E 'warning:' "$log" | grep -v 'appintentsmetadataprocessor' | grep -q .; then
  echo "xcodebuild printed warnings; the full log is $log" >&2
  exit 1
fi
