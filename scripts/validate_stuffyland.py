#!/usr/bin/env python3
"""Offline integrity checks for Stuffy Land's bundled data-only adventure catalog."""
import json
from pathlib import Path

content = Path(__file__).resolve().parents[1] / "StuffyLand" / "Content"
catalog = json.loads((content / "catalog.json").read_text())
assert catalog["formatVersion"] == 1
assert 1 <= len(catalog["adventures"]) <= 120
seen = set()
for listing in catalog["adventures"]:
    assert listing["id"] not in seen
    seen.add(listing["id"])
    story = json.loads((content / (listing["filename"] + ".json")).read_text())
    assert story["id"] == listing["id"]
    assert story["contentVersion"] == listing["contentVersion"]
    nodes = {node["id"]: node for node in story["nodes"]}
    assert len(nodes) == len(story["nodes"])
    finals = [n for n in nodes.values() if n.get("ending", {}).get("kind") == "final"]
    detours = [n for n in nodes.values() if n.get("ending", {}).get("kind") == "detour"]
    assert len(finals) >= 5, (listing["id"], "too few permanent endings")
    assert len(detours) >= 10, (listing["id"], "too few short detours")
    assert sorted(n["ending"]["rank"] for n in finals) == list(range(1, len(finals) + 1))
    assert sum("illustration" in n for n in story["nodes"]) * 3 >= len(
        [n for n in story["nodes"] if "ending" not in n]
    )
    visited = set()
    visiting = set()
    def walk(node_id, depth):
        assert node_id in nodes
        assert node_id not in visiting, ("cycle", node_id)
        node = nodes[node_id]
        if "ending" in node:
            if node["ending"]["kind"] == "final":
                assert depth >= story["minimumDecisions"], (node_id, depth)
            return
        visited.add(node_id)
        visiting.add(node_id)
        assert len(node["choices"]) >= 2
        for choice in node["choices"]:
            assert choice["to"] in nodes
            walk(choice["to"], depth + 1)
        visiting.remove(node_id)
    walk(story["start"], 0)
    reachable = set()
    queue = [story["start"]]
    while queue:
        node_id = queue.pop()
        if node_id in reachable:
            continue
        reachable.add(node_id)
        queue.extend(c["to"] for c in nodes[node_id].get("choices", []))
    assert reachable == nodes.keys(), (listing["id"], "unreachable", nodes.keys() - reachable)
    print(f"PASS {listing['title']}: {len(nodes)} nodes, {len(finals)} finals, {len(detours)} detours")
print(f"PASS Stuffy Land catalog: {len(seen)} adventure(s)")
