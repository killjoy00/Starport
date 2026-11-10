#!/usr/bin/env bash
# A successful compile is not proof that embedded frameworks can start.
# The original TestFlight build crashed on launch due to missing AdMob Info.plist.
set -euo pipefail

app="${1:?Expected path to compiled Starport.app}"
test -d "$app"
bundle_id="pro.starport.story"

device=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
data=json.load(sys.stdin)["devices"]
for runtime in sorted(data,reverse=True):
    for d in data[runtime]:
        if d.get("isAvailable") and "iPhone" in d["name"]:
            print(d["udid"])
            sys.exit(0)
sys.exit("No available iPhone simulator on runner")
')
echo "Using simulator $device"
xcrun simctl boot "$device" || true
xcrun simctl bootstatus "$device" -b
xcrun simctl install "$device" "$app"

echo "Launching $bundle_id"
if ! launch=$(xcrun simctl launch "$device" "$bundle_id" 2>&1); then
    echo "::error::Starport failed to launch: $launch"
    exit 1
fi
echo "$launch"
pid=$(printf '%s' "$launch" | sed -nE 's/^.*: ([0-9]+)$/\1/p' | tail -n1)
if [ -z "$pid" ]; then
    echo "::error::Could not extract Starport PID from simulator launch."
    exit 1
fi

sleep 8
if ! xcrun simctl spawn "$device" ps -p "$pid" -o pid= | grep -Eq "[0-9]+"; then
    echo "::error::Starport crashed or exited within 8 seconds of launch."
    xcrun simctl spawn "$device" log show --last 45s --style compact \
      --predicate 'process == "Starport"' 2>/dev/null | tail -n 65 || true
    exit 1
fi
echo "Starport remained running 8 seconds after cold launch (PID $pid)."
