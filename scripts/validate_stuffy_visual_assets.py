#!/usr/bin/env python3
"""Regression guard for Stuffy Land's approved story art and skippable opening.

No network or third-party dependencies. The artwork hashes are pinned to the
approved illustration package so a stale flat-art generator cannot overwrite
the scene assets without an intentional manifest update.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "StuffyLand/Assets.xcassets"
MANIFEST = ROOT / "StuffyLand/Design/sundae-art-manifest.json"
SCENES = [1, 3, 5, 7, 9, 11, 13, 15, 17]


def jpeg_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    assert data[:2] == b"\xff\xd8", f"Not a JPEG: {path}"
    pos = 2
    while pos < len(data) - 8:
        if data[pos] != 255:
            pos += 1
            continue
        while pos < len(data) and data[pos] == 255:
            pos += 1
        marker = data[pos]
        pos += 1
        if marker in (0xD8, 0xD9) or 0xD0 <= marker <= 0xD7:
            continue
        if marker in (0xC0, 0xC1, 0xC2):
            height = int.from_bytes(data[pos + 3:pos + 5], "big")
            width = int.from_bytes(data[pos + 5:pos + 7], "big")
            return width, height
        if pos + 2 >= len(data):
            break
        segment_length = int.from_bytes(data[pos:pos + 2], "big")
        assert segment_length >= 2, path
        pos += segment_length
    raise AssertionError(f"No JPEG size marker: {path}")


def verify() -> None:
    expected_names = {f"sundae-scene-{number:02d}" for number in SCENES}
    catalog = json.loads((ROOT / "StuffyLand/Content/sundae_switch.json").read_text())
    main_scenes = [n for n in catalog["nodes"] if "ending" not in n]
    art_names = [n["illustration"]["asset"]
                 for n in main_scenes if "illustration" in n]
    assert len(main_scenes) == 18
    assert len(art_names) == 9
    assert set(art_names) == expected_names

    manifest = json.loads(MANIFEST.read_text())
    assert manifest["opening_frames"] == 6
    assert manifest["opening_grid"] == {
        "columns": 3, "rows": 2, "frame_width": 370, "frame_height": 996
    }
    expected_files = {f"{name}.imageset/{name}.jpg" for name in expected_names}
    expected_files.add("stuffy-intro-frames.imageset/stuffy-intro-frames.jpg")
    assert set(manifest["files"]) == expected_files

    for rel, digest in manifest["files"].items():
        path = ASSETS / rel
        assert path.is_file() and path.stat().st_size > 100_000, path
        assert hashlib.sha256(path.read_bytes()).hexdigest() == digest, rel
        folder = path.parent
        contents = json.loads((folder / "Contents.json").read_text())
        assert contents["images"][0]["filename"] == path.name, rel
        expect_size = ((1110, 1992) if rel.startswith("stuffy-intro")
                       else (1200, 720))
        assert jpeg_dimensions(path) == expect_size, rel

    root_view = (ROOT / "Starport/UI/StarportRootView.swift").read_text()
    assert "AppBrand.current.isStuffyLand && showingStuffyOpening" in root_view
    assert "StuffyOpeningSequence" in root_view
    assert 'UIImage(named: "stuffy-intro-frames")' in root_view
    assert 'Button(action: onFinish)' in root_view
    assert 'accessibilityLabel("Skip Stuffy Land opening")' in root_view
    assert "if reduceMotion || Self.frames.count != 6" in root_view
    assert "guard !Task.isCancelled else { return }" in root_view
    assert root_view.count("Task.sleep(nanoseconds:") >= 2
    assert "StuffyLandShelf(" in root_view
    assert "AgeGateView(onConfirm13Plus:" in root_view  # StarPort only
    print("PASS 9/18 painterly Sundae scenes, six animation frames,"
          " asset integrity, skip/Reduce Motion and separate StarPort gate")


if __name__ == "__main__":
    verify()
