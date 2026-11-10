# Stuffy Land — pilot iOS app

Stuffy Land is a **second iOS app target inside the Starport repository**, not a separate Git repository. It shares the deterministic branching engine, reader, achievements infrastructure, local saves, StoreKit 2 and consent-gated AdMob controller with Starport. It has its **own iOS bundle ID**, story assets, catalog, remote story feed, purchase product identifier and on-device storage namespace.

## First playable pilot

**The Bell of Button Hill** is a draft, not established Stuffy Land canon. Pip, Mallow, Dot, Tansy and Wren are provisional characters until real-world story notes are provided. The story has 25 core decisions, 5 permanent endings and 12 rewindable false endings. Choices modify Curiosity, Courage and Friendship (implemented with the generic engine's Clues/Power/Trust stats); flags affect certain text and which endings can be chosen.

The first version uses native, lightweight placeholder artwork in the reader and on library cards rather than claiming that finished cover/scene illustrations exist.

## Two types of stories

Stuffy Land's library supports **interactive adventures** and **regular read-through books**:

- **Adventure** (existing format): branching `nodes`, decisions, stats, rewindable detours, multiple endings and achievements. Older catalog entries omit `kind`, which defaults to `adventure`.
- **Reader** (`"kind": "reader"` in `catalog.json`): a linear document with `id`, `contentVersion`, `title`, `subtitle`, optional `author`, and an ordered array of `pages`. Each page has a unique `id`, optional `heading`, and `paragraphs` (prose strings). Optional `illustration` objects contain the asset name and accessible alt text.

The library groups both formats into collections. Reader progress is saved per book/version. The e-reader has larger/smaller text, previous/next sections and **Read to me** playback (pause, resume, stop, speed control, automatic continuation). It uses the iPhone's built-in speech synthesis without recording, server upload, or AI voice charges, and narration stops when leaving the reader.

**The Button at the Window** is a seven-section demonstration book, not established Stuffy Land canon. Both pilot stories are placeholders until the actual user-provided Stuffy Land stories arrive. Future books can be added as content-only JSON updates without recompiling after the first version ships.

## Separate publishing and safety decisions

The initial build retains a **13+ age gate** and teen non-personalized ad behavior as conservative development defaults. This is **not an audience decision** for Stuffy Land: confirm its actual intended age range, children's privacy design, App Store classification and ad suitability **before TestFlight or release**. Do not enable live AdMob or the real Remove Ads product until the Stuffy Land app's own IDs and disclosures are reviewed. The App Store product placeholder is `pro.stuffyland.stories.remove_ads`.

## Building

Select the `StuffyLand` shared Xcode scheme in `Starport.xcodeproj` on Xcode 16+. The shared `Starport` target remains independent. App-local content is bundled from `StuffyLand/Content/`. A new adventure is added by pairing its JSON file with an entry in `catalog.json`, incrementing `contentVersion` when changing it. Once the foundation PRs are merged to `main`, the Stuffy Land "Check for new adventures" action can load more packs from `StuffyLand/Content/` on that branch.

Run `python3 scripts/validate_stuffyland.py` to check catalog, all links, endings and illustration coverage. GitHub Actions also builds both iOS schemes separately.

## Next editorial steps

- Replace pilot characters/places with the actual Stuffy Land canon.
- Edit and playtest story branches so each choice feels consequential rather than just altering the same path.
- Expand into a real library of separately titled adventures, recurring characters and series.
- Commission/generate final app icon, cover illustrations, and scene art, then perform iPhone accessibility and age/privacy review.
