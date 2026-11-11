# Stuffy Land

Stuffy Land is a separate iOS app inside the Starport repository. It shares the branching engine, reader, local bookmarks, built-in Read Aloud, and settings infrastructure, with its own target, bundle ID, content, icon, assets, and visual identity.

## Home screen

The Stuffy Land home is a compact **story shelf**, not a marketing splash screen: a small logo/title, an optional **Continue** card when a saved read-along has advanced or a branching adventure is in progress, a three-way All / Read-alongs / Adventures filter, and compact cover-and-title rows that open each story with one tap. Long subtitles, repeated editorial labels, oversized tent hero artwork, and age-rating notices are intentionally absent from the landing screen. Source/provenance notes remain under **About these stories**.

## Opening and illustration style

Stuffy Land starts with a brief, six-frame storybook animation: the
galaxy tent lights up, the Stuffy Land title appears, and Opal and Lolo
arrive before the story shelf. It is skippable immediately, bypassed
with Reduce Motion, and does not replay when returning from a story.
It changes neither StarPort's opening nor the direct-to-story shelf.

**Opal and the Great Sundae Switch** now uses nine approved, textured
storybook illustrations rather than the original flat Pillow-rendered
scenes. Its 18-scene choice graph, five endings, ten detours, saves and
achievements remain unchanged. The illustration manifest pins the nine
art assets and intro atlas to the reviewed artwork.

## The collection

The real Opal universe replaces the provisional Button Hill shelf. There are **14 stories**:

- Two adventures adapted from the recovered archive: **Opal and the Great Pillow-Fort Mystery** and **Opal and the Great Snore-Snatcher**. Each has 36 scenes, 17 decisions per completed route, four pairs of distinct investigation/action branches, five endings, and ten rewindable detours. Clues and promises affect later prose and available endings.
- One **new original interactive adventure**, **Opal and the Great Sundae Switch**. The reader makes choices across 18 main story scenes, with five endings and ten rewindable detours. Nine of the 18 scenes have individually composed illustrations (50%). This new story is separate from recovered source material.
- Eleven regular books with saved places, adjustable text, and Read Aloud. **The Giggle Games** preserves the complete recovered wording. Nine stories expand surviving summaries. **The Treasure of the Thousand Traps** is new fiction inspired by a surviving title and premise, because its original plot and ending were unavailable.

Reader pages have no added chapter headings. Provenance appears on cards, in the reader, and in “About these stories.” Complete source prose and new adaptations are kept separately in `Editorial/`. The two DOCX uploads were byte-identical and are counted once. Old pilot fixtures remain for compatibility tests, but are absent from the visible shelf and ignored when an older cached catalog is combined with the current collection.

## Creative reference

- [Style guide](Editorial/STYLE_GUIDE.md)
- [Universe and all 31 kitty characters](Editorial/UNIVERSE.md)
- [Story provenance](Editorial/story-provenance.json)
- [Art direction and image prompts](Design/ART_DIRECTION.md)

The shelf uses the purple galaxy tent, golden Friendship Star, lavender cushioned cards, stitched seams, warm serif titles, and a Lolo-and-storybook icon. Stuffy Land has its own illustrated home; Starport keeps its space presentation. New illustrations interpret source references without importing their duplicate characters, incorrect labels, or unrelated fantasy poster.

## Build and validation

Select `StuffyLand` in `Starport.xcodeproj` on Xcode 16+. Bundle ID: `pro.stuffyland.stories`.

```sh
python3 scripts/build_stuffyland_collection.py
python3 scripts/validate_stuffyland.py
swift test
```

The builder deterministically paginates the editorial sources and builds both adventure graphs. The Python validator checks every stat/flag state relevant to ending availability, every ending and detour, original-text preservation, provenance, asset files, and Xcode resource membership. Swift tests decode every published JSON document using the real app models, explore both adventures, restore completed saves, rewind detours, and check story-specific ending memories. CI builds and launches both iOS apps and saves native dark/light shelf screenshots.

**Age-rating presentation:** Stuffy Land opens directly to Opal's story shelf. The app does not ask readers to confirm their age and does not display 13+ messaging in its shelf or settings. Its distribution age classification is managed separately in App Store Connect; this is not an in-app age-verification system. Starport retains its own confirmation screen. Advertising remains disabled in release builds, and the underlying teen/general-rated, non-personalized ad safeguards are unchanged.
