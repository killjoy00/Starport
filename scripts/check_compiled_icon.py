#!/usr/bin/env python3
"""Require a primary app icon in the *compiled* .app, not just source assets."""
import plistlib
import sys
from pathlib import Path

def verify(app: Path) -> None:
    info = plistlib.loads((app / "Info.plist").read_bytes())
    for key in ("CFBundleIcons", "CFBundleIcons~ipad"):
        config = info.get(key, {}).get("CFBundlePrimaryIcon", {})
        if config.get("CFBundleIconName") != "AppIcon":
            raise SystemExit(f"Missing AppIcon primary declaration in {key}")
        if not config.get("CFBundleIconFiles"):
            raise SystemExit(f"Missing {key} icon file references")
    if not (app / "Assets.car").is_file():
        raise SystemExit("Missing compiled Assets.car")
    icons = sorted(app.glob("AppIcon*.png"))
    if not icons:
        raise SystemExit("No compiled AppIcon PNGs in the .app")
    for png in icons:
        content = png.read_bytes()
        if len(content) < 1000 or content[:8] != bytes([137,80,78,71,13,10,26,10]):
            raise SystemExit(f"Invalid icon data: {png.name}")
    print("Compiled app icon verified:", ", ".join(x.name for x in icons))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: check_compiled_icon.py <path/to/StarPort.app>")
    verify(Path(sys.argv[1]))
