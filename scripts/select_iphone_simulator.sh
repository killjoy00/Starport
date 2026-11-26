#!/usr/bin/env bash
# Choose the same iPhone simulator for both native launch smoke tests.
set -euo pipefail
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
printf '%s\n' "$device"
