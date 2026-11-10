#!/usr/bin/env python3
"""Offline integrity checks for Stuffy Land's bundled data-only story packs."""
import json
from collections import deque
from pathlib import Path

content = Path(__file__).resolve().parents[1] / "StuffyLand" / "Content"
catalog = json.loads((content / "catalog.json").read_text())
assert catalog["formatVersion"] == 1
assert 1 <= len(catalog["adventures"]) <= 120
seen_ids = set()

for listing in catalog["adventures"]:
    assert listing["id"] not in seen_ids, "Duplicate catalog ID"
    seen_ids.add(listing["id"])
    book = json.loads((content / (listing["filename"] + ".json")).read_text())
    assert book["id"] == listing["id"]
    assert book["contentVersion"] == listing["contentVersion"]
    nodes = {node["id"]: node for node in book["nodes"]}
    assert len(nodes) == len(book["nodes"])
    finals = [n for n in nodes.values() if n.get("ending", {}).get("kind") == "final"]
    detours = [n for n in nodes.values() if n.get("ending", {}).get("kind") == "detour"]
    assert len(finals) >= 5, "At least five substantive endings required"
    assert len(detours) >= 10, "At least ten rewindable detours required"
    assert sorted(n["ending"]["rank"] for n in finals) == list(range(1, len(finals) + 1))
    decision_nodes = [n for n in nodes.values() if "ending" not in n]
    assert sum("illustration" in n for n in decision_nodes) * 3 >= len(decision_nodes)

    # Verify all nodes are reachable and that the story is acyclic. Memoize
    # shared branches so we never expand an exponential number of paths.
    visited, visiting = set(), set()
    def visit(node_id):
        assert node_id in nodes, ("Broken scene ID", node_id)
        assert node_id not in visiting, ("Choice cycle", node_id)
        if node_id in visited:
            return
        visiting.add(node_id)
        node = nodes[node_id]
        if "ending" not in node:
            choices = node.get("choices", [])
            assert len(choices) >= 2
            assert len({c["id"] for c in choices}) == len(choices)
            for choice in choices:
                assert choice["to"] in nodes
                visit(choice["to"])
        visiting.remove(node_id)
        visited.add(node_id)
    visit(book["start"])
    assert visited == nodes.keys(), ("Unreachable nodes", nodes.keys() - visited)

    depths = {book["start"]: 0}
    queue = deque([book["start"]])
    while queue:
        current = queue.popleft()
        for choice in nodes[current].get("choices", []):
            nxt = choice["to"]
            proposed = depths[current] + 1
            if proposed < depths.get(nxt, 1_000_000):
                depths[nxt] = proposed
                queue.append(nxt)
    assert all(depths[n["id"]] >= book["minimumDecisions"] for n in finals)

    # An all-helpful route must allow all five endings so none is accidentally
    # locked by a mis-typed requirement or flag. Other choices still matter.
    stats = {"clues": 0, "power": 3, "trust": 1}
    flags = set()
    current = book["start"]
    while "ending" not in nodes[current]:
        choices = nodes[current]["choices"]
        if all("ending" in nodes[c["to"]] for c in choices):
            available = [
                c["to"] for c in choices
                if all(
                    (req.get("stat") is None or stats[req["stat"]] >= req["atLeast"])
                    and (req.get("flag") is None or req["flag"] in flags)
                    for req in c.get("requirements", [])
                )
            ]
            assert {n["id"] for n in finals} == set(available), "A permanent ending is unreachable"
            break
        choice = choices[0]
        for effect in choice.get("effects", []):
            if "flag" in effect:
                flags.add(effect["flag"])
            if "stat" in effect:
                key = effect["stat"]
                stats[key] = max(0, min(5, stats[key] + effect["delta"]))
        current = choice["to"]

    print(f"PASS {listing['title']}: {len(nodes)} nodes, {len(finals)} finals, {len(detours)} detours")
print(f"PASS Stuffy Land catalog: {len(seen_ids)} adventure(s)")
