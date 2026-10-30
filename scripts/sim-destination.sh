#!/bin/sh
# Prints an xcodebuild destination for the newest available iPhone simulator:
# the newest iOS runtime, then the newest iPhone generation in it, preferring
# the standard model, then Pro, Pro Max, Air, and "e". SIM_DEVICE overrides
# the choice with a simulator name or UDID. Never hard-code a device
# (AGENTS.md §7).
#
#   scripts/sim-destination.sh          # platform=iOS Simulator,id=<udid>
#   scripts/sim-destination.sh --udid   # <udid>
#   scripts/sim-destination.sh --name   # iPhone 17 (iOS 27.2)
set -eu

format=${1:-destination}

xcrun simctl list devices available --json | SIM_DEVICE="${SIM_DEVICE:-}" python3 -I -c '
import json, os, re, sys

devices = json.load(sys.stdin)["devices"]
wanted = os.environ.get("SIM_DEVICE", "").strip()

def runtime_version(runtime):
    match = re.search(r"iOS-(\d+)-(\d+)(?:-(\d+))?", runtime)
    return tuple(int(part or 0) for part in match.groups()) if match else None

candidates = []
for runtime, entries in devices.items():
    version = runtime_version(runtime)
    if version is None:
        continue
    for device in entries:
        if not device.get("isAvailable", True):
            continue
        candidates.append((version, device))

def describe(version, device):
    text = "%d.%d" % version[:2] + (".%d" % version[2] if version[2] else "")
    return device["udid"], "%s (iOS %s)" % (device["name"], text)

if wanted:
    matches = [(v, d) for v, d in candidates if wanted in (d["udid"], d["name"])]
    if not matches:
        sys.exit("sim-destination: no available simulator named or with UDID %r" % wanted)
    matches.sort(key=lambda item: item[0], reverse=True)
    chosen = matches[0]
else:
    model_order = ["", "Pro", "Pro Max", "Air", "e"]
    def rank(item):
        version, device = item
        match = re.fullmatch(r"iPhone (\d+)(?: (.+))?", device["name"])
        if not match:
            return None
        generation = int(match.group(1))
        model = match.group(2) or ""
        preference = model_order.index(model) if model in model_order else len(model_order)
        return (version, generation, -preference)
    ranked = [(rank(item), item) for item in candidates if rank(item) is not None]
    if not ranked:
        sys.exit("sim-destination: no available iPhone simulator; install an iOS runtime in Xcode")
    ranked.sort(key=lambda pair: pair[0], reverse=True)
    chosen = ranked[0][1]

udid, name = describe(*chosen)
print(udid)
print(name)
' > "${TMPDIR:-/tmp}/sim-destination.$$"

udid=$(sed -n 1p "${TMPDIR:-/tmp}/sim-destination.$$")
name=$(sed -n 2p "${TMPDIR:-/tmp}/sim-destination.$$")
rm -f "${TMPDIR:-/tmp}/sim-destination.$$"

case $format in
  --udid) echo "$udid" ;;
  --name) echo "$name" ;;
  *) echo "platform=iOS Simulator,id=$udid" ;;
esac
