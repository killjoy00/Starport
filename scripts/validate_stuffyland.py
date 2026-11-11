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
    kind = listing.get("kind", "adventure")
    assert kind in {"adventure", "reader"}, ("Unknown story format", listing["id"])
    if kind == "reader":
        pages = book["pages"]
        assert 1 <= len(pages) <= 500, ("Bad reader page count", listing["id"])
        assert len({p["id"] for p in pages}) == len(pages), "Duplicate reader page IDs"
        for page in pages:
            assert page["id"], "Empty page ID"
            assert 1 <= len(page["paragraphs"]) <= 40
            assert all(isinstance(p, str) and p.strip() and len(p) <= 15000
                       for p in page["paragraphs"]), "Blank/invalid page text"
            if "illustration" in page:
                assert page["illustration"]["asset"]
                assert page["illustration"]["alt"].strip()
        print(f"PASS {listing['title']}: {len(pages)} read-through pages")
        continue

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

    # Explore actual available choices, including every relevant stat/flag state.
    # Prepared endings are allowed to be locked on other routes, but every
    # ending must be attainable and no reachable decision may strand a player.
    required_flags = {r["flag"] for n in nodes.values() for c in n.get("choices", [])
                      for r in c.get("requirements", []) if "flag" in r}
    pending = [(book["start"], (0, 3, 1), frozenset())]
    seen_states, earned = set(), set()
    keys = ["clues", "power", "trust"]
    while pending:
        current, values, flags = pending.pop()
        key = (current, values, flags)
        if key in seen_states:
            continue
        seen_states.add(key)
        node = nodes[current]
        if "ending" in node:
            if node["ending"]["kind"] == "final":
                earned.add(current)
            continue
        stats = dict(zip(keys, values))
        available = [c for c in node["choices"] if all(
            ("stat" not in r or stats[r["stat"]] >= r["atLeast"])
            and ("flag" not in r or r["flag"] in flags)
            for r in c.get("requirements", []))]
        assert available, ("Reachable dead end", current, values, flags)
        for choice in available:
            updated, new_flags = dict(stats), set(flags)
            for effect in choice.get("effects", []):
                if "stat" in effect:
                    k = effect["stat"]
                    updated[k] = max(0, min(5, updated[k] + effect["delta"]))
                if effect.get("flag") in required_flags:
                    new_flags.add(effect["flag"])
            pending.append((choice["to"], tuple(updated[k] for k in keys), frozenset(new_flags)))
    assert earned == {n["id"] for n in finals}, ("Unattainable ending", earned)

    print(f"PASS {listing['title']}: {len(nodes)} nodes, {len(finals)} finals, {len(detours)} detours")
print(f"PASS Stuffy Land catalog: {len(seen_ids)} total stories (both formats)")

# Verify the visible collection accounts for every recovered story once.
root = content.parents[1]
provenance = json.loads((root / "StuffyLand/Editorial/story-provenance.json").read_text())
assert {p["id"] for p in provenance["stories"]} == seen_ids
assert len(seen_ids) == 15
assert sum(x.get("kind") == "reader" for x in catalog["adventures"]) == 12
assert sum(x.get("kind") == "adventure" for x in catalog["adventures"]) == 3
sundae = json.loads((content / "sundae_switch.json").read_text())
sundae_scenes = [node for node in sundae["nodes"] if not node.get("ending")]
sundae_art = [node["illustration"]["asset"] for node in sundae_scenes if "illustration" in node]
assert len(sundae_scenes) == 18, "Sundae Switch must have 18 main story scenes"
assert len(sundae_art) == 9 and len(set(sundae_art)) == 9, "Exactly half the main scenes must have distinct artwork"
assert len([node for node in sundae["nodes"] if node.get("ending", {}).get("kind") == "final"]) == 5
assert len([node for node in sundae["nodes"] if node.get("ending", {}).get("kind") == "detour"]) == 10
original = (root / "StuffyLand/Editorial/source/giggle_games.txt").read_text().strip().split("\n\n")
giggles = json.loads((content / "giggle_games.json").read_text())
assert [p for page in giggles["pages"] for p in page["paragraphs"]] == original[1:], "Original Giggle Games text changed"
# The user's long read-along must be reproduced in full with no prose edits.
wobble_source = (root / "StuffyLand/Editorial/source/wobble_palooza.md").read_text(encoding="utf-8").strip().split("\n\n")
wobble = json.loads((content / "wobble_palooza.json").read_text())
wobble_listing = next(entry for entry in catalog["adventures"] if entry["id"] == wobble["id"])
assert wobble["id"] == "stuffy-wobble-palooza"
assert wobble["title"] == wobble_source[0].removeprefix("**").removesuffix("**")
assert wobble_listing["kind"] == "reader" and wobble_listing["estimatedMinutes"] == 24
assert len(wobble["pages"]) == 19
assert [p["id"] for p in wobble["pages"]] == [f"page_{i+1:02}" for i in range(19)]
assert all("heading" not in p and "choices" not in p for p in wobble["pages"])
assert [para for page in wobble["pages"] for para in page["paragraphs"]] == wobble_source[1:], "Original Wobble-Palooza text changed"
assert sum(len(p.split()) for p in wobble_source[1:]) == 3447, "Original Wobble-Palooza was truncated"
assert next(x for x in provenance["stories"] if x["id"] == wobble["id"])["status"] == "user_supplied_original"
print("PASS user-supplied Wobble-Palooza prose preserved word-for-word across 19 reader sections")
project = (root / "Starport.xcodeproj/project.pbxproj").read_text()
resource_phase = project.split("/* Begin PBXResourcesBuildPhase section */")[1].split("/* End PBXResourcesBuildPhase section */")[0]
for entry in catalog["adventures"]:
    assert entry["filename"] + ".json in Stuffy Resources" in resource_phase, ("Story not bundled", entry["filename"])
    book = json.loads((content / (entry["filename"] + ".json")).read_text())
    illustrations = [p["illustration"] for p in book.get("pages", book.get("nodes", [])) if "illustration" in p]
    for art in [entry["coverAsset"]] + [i["asset"] for i in illustrations]:
        folder = root / "StuffyLand/Assets.xcassets" / (art + ".imageset")
        meta = json.loads((folder / "Contents.json").read_text())
        assert (folder / meta["images"][0]["filename"]).is_file(), ("Missing art", art)
print("PASS provenance, verbatim original, bundled resource membership, and artwork files")
