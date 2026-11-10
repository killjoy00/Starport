#!/usr/bin/env python3
"""Verify the *built* .app contains required startup and privacy config.

The source Xcode INFOPLIST_KEY_* build settings were silently excluded from a
previous TestFlight .app and caused an immediate Google Mobile Ads SDK crash.
"""
import plistlib
import sys
from pathlib import Path

SAMPLE_ID = "ca-app-pub-3940256099942544~1458002511"
BUNDLE = "pro.starport.story"

def verify(app: Path, bundle: str = BUNDLE) -> None:
    info_path = app / "Info.plist"
    if not info_path.is_file():
        raise SystemExit("Compiled app has no Info.plist")
    info = plistlib.loads(info_path.read_bytes())
    if info.get("CFBundleIdentifier") != bundle:
        raise SystemExit("Compiled app has an unexpected bundle identifier")
    app_id = info.get("GADApplicationIdentifier")
    if not isinstance(app_id, str) or not app_id.startswith("ca-app-pub-"):
        raise SystemExit("Compiled app is missing GADApplicationIdentifier: AdMob may crash on launch")
    banner = info.get("STARPORT_BANNER_UNIT_ID")
    if not isinstance(banner, str) or not banner.startswith("ca-app-pub-"):
        raise SystemExit("Compiled app is missing STARPORT_BANNER_UNIT_ID")
    flag = info.get("STARPORT_ADS_LIVE_APPROVED")
    if flag != "NO":
        raise SystemExit("StarPort beta must keep production advertising disabled")
    if app_id != SAMPLE_ID:
        raise SystemExit("Initial TestFlight may only use the Google sample app identifier")
    print("Compiled StarPort app config OK: AdMob ID is present, live ads are disabled.")

if __name__ == "__main__":
    if len(sys.argv) not in (2, 3):
        raise SystemExit("Usage: check_release_plist.py <path/to/Starport.app>")
    verify(Path(sys.argv[1]), sys.argv[2] if len(sys.argv) == 3 else BUNDLE)
