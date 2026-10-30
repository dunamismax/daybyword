#!/bin/sh
# Builds the app for the simulator, boots the simulator scripts/sim-destination.sh
# picks (or SIM_DEVICE), installs the app, and launches it. Arguments after the
# script name are passed to the app, for example: scripts/run-app.sh -today 2027-01-01
set -eu
cd "$(dirname "$0")/.."

udid=$(scripts/sim-destination.sh --udid)
echo "run: $(scripts/sim-destination.sh --name)"

scripts/xcodebuild.sh build-simulator -destination "platform=iOS Simulator,id=$udid" build

xcrun simctl boot "$udid" 2>/dev/null || true
# Show the simulator: Xcode 27 calls the app DeviceHub; earlier Xcodes, Simulator.
open -b com.apple.dt.Devices 2>/dev/null || open -b com.apple.iphonesimulator 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
xcrun simctl install "$udid" build/DerivedData/Build/Products/Debug-iphonesimulator/DayByWord.app
xcrun simctl launch --terminate-running-process "$udid" com.daybyword.app "$@"
