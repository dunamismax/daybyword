#!/bin/sh
# Makes the App Store's screenshots (BUILD.md P16.7, docs/app-store/README.md)
# on the newest 6.9-inch iPhone (a Pro Max) and 13-inch iPad (an iPad Pro
# 13-inch) simulators, in light and dark, through the AppStoreScreenshots UI
# test. The status bar shows 9:41 on the screenshots' day (Friday 5 March 2027;
# the iPad shows the date), full bars and a full battery while it runs.
# The PNGs go to screenshots/app-store/iphone/ and ipad/ (gitignored).
set -eu
cd "$(dirname "$0")/.."

out="$PWD/screenshots/app-store"
mkdir -p "$out"

# The newest available simulator whose name matches, on the newest iOS runtime.
newest() {
  xcrun simctl list devices available --json | PATTERN="$1" python3 -I -c '
import json, os, re, sys
devices = json.load(sys.stdin)["devices"]
pattern = re.compile(os.environ["PATTERN"])
best = None
for runtime, entries in devices.items():
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not match:
        continue
    version = tuple(int(part) for part in match.groups())
    for device in entries:
        found = pattern.search(device["name"])
        if not found:
            continue
        key = (version, int(found.group(1)))
        if best is None or key > best[0]:
            best = (key, device["udid"])
if best is None:
    sys.exit("no simulator matches " + os.environ["PATTERN"])
print(best[1])
'
}

# 9:41 local time on the screenshots' day, which simctl takes in UTC (with
# milliseconds) and shows in the Mac's zone.
seconds=$(date -j -f "%Y-%m-%d %H:%M" "2027-03-05 09:41" +%s)
time=$(date -u -r "$seconds" +%Y-%m-%dT%H:%M:%S.000Z)

for kind in iphone ipad; do
  case $kind in
    iphone) udid=$(newest '^iPhone (\d+) Pro Max$') ;;
    ipad) udid=$(newest '^iPad Pro 13-inch \(M(\d+)\)$') ;;
  esac
  echo "app-store-screenshots: $kind on $udid"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl status_bar "$udid" override --time "$time" --dataNetwork wifi --wifiMode active \
    --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
  status=0
  TEST_RUNNER_DBW_APP_STORE_SCREENSHOTS="$out" scripts/xcodebuild.sh "app-store-$kind" \
    -destination "platform=iOS Simulator,id=$udid" \
    -only-testing:AppUITests/AppStoreScreenshots test || status=$?
  xcrun simctl status_bar "$udid" clear
  [ "$status" -eq 0 ] || exit "$status"
done
ls "$out"/iphone "$out"/ipad
