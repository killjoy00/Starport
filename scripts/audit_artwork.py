#!/usr/bin/env python3
"""Validate the actual iOS assets and inline-art coverage without third-party deps."""
from __future__ import annotations
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Starport/Assets.xcassets"
CONTENT = ROOT / "Starport/Content"


def image_file(asset: str) -> Path:
    directory = ASSETS / f"{asset}.imageset"
    info = json.loads((directory / "Contents.json").read_text())
    filename = info["images"][0]["filename"]
    path = directory / filename
    if not path.is_file() or path.stat().st_size < 15_000:
        raise AssertionError(f"Missing or unusually small illustration: {path}")
    return path


def audit() -> None:
    story = json.loads((CONTENT / "first_signal.json").read_text())
    catalog = json.loads((CONTENT / "catalog.json").read_text())
    nodes = story["nodes"]
    scenes = [n for n in nodes if n.get("ending") is None]
    art = [n for n in nodes if n.get("illustration") is not None]
    scene_art = [n for n in scenes if n.get("illustration") is not None]
    assert len(art) * 3 >= len(nodes), "Art on less than 1/3 of story nodes"
    assert len(scene_art) * 3 >= len(scenes), "Art on less than 1/3 of choice pages"

    for node in art:
        illustration = node["illustration"]
        assert illustration["alt"].strip(), f"Missing alt text on {node['id']}"
        image_file(illustration["asset"])

    for listing in catalog["adventures"]:
        if cover := listing.get("coverAsset"):
            image_file(cover)

    icon_folder = ASSETS / "AppIcon.appiconset"
    contents = json.loads((icon_folder / "Contents.json").read_text())
    icon = icon_folder / contents["images"][0]["filename"]
    with icon.open("rb") as handle:
        header = handle.read(24)
    assert header[:8] == bytes([137, 80, 78, 71, 13, 10, 26, 10]), "App icon must be PNG"
    assert struct.unpack(">II", header[16:24]) == (1024, 1024), "App icon must be 1024 x 1024"

    print(f"Artwork OK: {len(art)}/{len(nodes)} nodes; "
          f"{len(scene_art)}/{len(scenes)} story decision pages; "
          f"{len({n['illustration']['asset'] for n in art})} unique interior assets; "
          "cover and 1024px app icon present.")


if __name__ == "__main__":
    audit()
