# Starport & Stuffy Land

This repository contains **two distinct iOS apps** using one shared branching-adventure engine. `Starport` is the science-fiction adventure shelf. `StuffyLand` is a separately installed, independently branded storybook app with its own catalog, achievements, save keys, App Store configuration and ad/purchase IDs.

The current first Stuffy Land story is a **provisional pilot**, not established Stuffy Land canon. See [StuffyLand/README.md](StuffyLand/README.md) for story contents, target setup and the age/privacy release blockers.

Both apps have their own Xcode schemes in `Starport.xcodeproj`. Choose `Starport` or `StuffyLand`. They share files from `Starport/Core`, `Starport/App` and `Starport/UI`, but bundle different content resources. Run `python3 scripts/validate_stuffyland.py` for the Stuffy Land graph validation; CI also builds both targets.

---

## Starport

**Starport** is a native iOS adventure library intended **only for people ages 13 and older**. It has a small one-time 13+ confirmation before library access, ads or purchases. It no longer presents a full-screen age lecture. No birth date, name, or account is required.

**Editorial distinction:** The adventures use the prose length, vocabulary, pacing, and science-fiction sensibility of strong middle-grade books (roughly a 10–12-year-old *reading level*). **The product is not intended for children aged 10–12.** Do not market it as an under-13 app or put it in Apple's Kids category. In App Store Connect, accurately answer the content questions and use **Override to Higher Age Rating → 13+** if Apple's calculated rating is lower. Self-declaration is not independent proof of age.

## Story library

Starport is a container for multiple separately packaged adventures. The app ships with two stories and a **Check for new adventures** action. New stories can be published as JSON data in `Starport/Content/` on `main`, without an iOS binary change (the reader executes no downloaded code). A cached, previously validated version works offline.

The manifest `Starport/Content/catalog.json` lists an adventure's stable ID, version, filename, title, genre, symbol, summary, and duration. The `AdventureRepository` downloads the manifest and new stories from the public GitHub repo, validates all story graphs, and atomically activates the catalog. Only safe filenames and validated JSON are permitted. It is intentionally *opt-in*: no background refresh or automatic downloads.

To add an adventure, add a validated story `<story_name>.json`, include its entry in `catalog.json`, and merge both to `main`. Increase `contentVersion` when changing a published story, because saved games are versioned per adventure. When the story changes substantially, preserve discovered ending collections while restarting a run that can no longer safely resume. See [the episode branching map](docs/episode-one-branching.md).

## Episode 01 — The Door That Opens Tomorrow

A ship scheduled for tomorrow sends a warning today. Read the evidence, work with the crew, and decide how to guide the Wren through a glass storm.

- **36 story decisions plus a final decision**, so each route to a permanent ending is **37 decisions long**. The validator enforces a minimum of 30.
- **Five permanent endings**, individually ranked from **1 (best) to 5 (worst)**. No rewind is permitted once one is reached. A new run begins at the opening scene, while the endings collection is retained.
- **Twelve false endings** that can be immediately unwound, restoring the prior scene, Clues, Power, Trust, choice history, and decision count. Discovered detours persist as collectibles.
- **Genuine route splits:** five major narrative forks (archive vs outer hull, engineers vs pilot, live radio vs echo, crew council vs solo rescue, synchronized signal vs manual mirror) and two more forks within the alternative routes. The expanded edition contains **81 nodes, 64 interactive scenes, and about 16,900 words across all possible routes**. Only the scenes on the chosen path appear during one run.
- **Irreversible consequences:** learning with Juno unlocks a flight-safe ending; choosing the echo path prevents the coordinated best ending; a manual override can open a high-risk landing outcome. Clues, Power, Trust and earlier commitments determine which options remain open.
- **Story updates:** edition 4 expands the existing scenes and preserves active edition-3 runs, ending discoveries and detours because the decision graph is unchanged. Changes that alter the graph still restart incompatible runs while keeping discoveries.
- **25 achievements**: one per true ending, recoverable detours, unusual clues, story allies, resource milestones, and completion challenges. Achievements persist across new runs and are displayed on an offline trophy shelf.

## Episode 02 — The Thirteenth Car

The star train Marigold has twelve cars on its list and thirteen on the track. Find out what is singing behind the door with no handle, who the grey-sailed "pirates" really are, and what is following the train through the dark.

- **Routes of different lengths:** 51 to 56 decisions. `minimumDecisions` is 50 and the validator enforces it on every route.
- **Seven permanent endings**, ranked 1 (best) to 7 (worst), and **twelve false endings** that can be rewound. The manuscript has **91 nodes, 72 interactive scenes and roughly 12,800 words** across all routes.
- **Two mid-story forks** send the reader through different scenes: under the floors (4 scenes) or over the roofs (6), then the brass key (4) or the tail lamp (5).
- **Three endgames that exclude each other.** The Song needs the lantern song, which must be learned earlier. The Skiff needs a reader who has worked outside the train with Wick. The Coupling is always open. Endings 1, 2 and 4 to 7 each belong to exactly one endgame, so no single run can reach them all.
- Most choices after the first act are trade-offs between Clues, Power and Trust, and some unlock only with a flag earned earlier.
- **32 achievements of its own** (IDs prefixed `car13_`): seven endings, route and character discoveries, and mastery goals such as finishing by all three endgames. The trophy shelf is grouped per adventure, and each story only awards its own achievements.
- **A cover and eight interior scenes** on 37 of the 72 interactive pages. The scenes are drawn by `scripts/generate_car_thirteen_art.py` and the cover by `scripts/generate_car_thirteen_cover.py` (Pillow and numpy; the cover also uses the Caladea and Inter fonts). Re-run either to change a picture.

Both stories are suspenseful, character-driven, and age-appropriate, with no graphic violence. A poor outcome can be sad without becoming graphic.

## Appearance

Dark mode is the default. Settings offers **Dark**, **Light**, and **System**, saved locally. Colors automatically adapt; text uses iOS Dynamic Type where possible.

## Ads and Remove Ads

- The fixed, clearly labelled **Google AdMob banner** appears in a separate bottom safe-area inset and does not cover the story choices.
- A **non-consumable StoreKit 2 in-app purchase** removes banner ads across all adventures, includes a Restore Purchases action, and remains tied to the purchaser's Apple Account.
- Google ad requests are set to **teen** age treatment, **general** creative rating, and **non-personalized** ads. UMP consent is checked before requesting ads. Users must confirm age 13+ before either SDK is prepared.
- **Debug builds** use Google's published test App ID and test banner unit ID. **Release ads are deliberately disabled** until the application and ad unit IDs are replaced with the publisher's real IDs, `STARPORT_ADS_LIVE_APPROVED` is set to `YES`, AdMob's consent messages are configured, and the app's age/region/privacy obligations are verified.
- The non-consumable product `pro.starport.story.remove_ads` **must be created in App Store Connect** before the purchase button will show a price. Test with StoreKit testing or the App Store sandbox; don't claim a live purchase until the product is approved.
- Before App Store submission, complete the App Privacy disclosures based on Google's **current SDK data-collection documentation**, supply a privacy policy, verify age-based ad protections and regional consent, and test failure/restore/refund flows.

**No real paid ad or purchase is live from this PR.** The screen, SDK integration, request safety configuration, and StoreKit 2 entitlement flow are wired for release configuration.

## Build and test

1. Open `Starport.xcodeproj` in Xcode 16 or later and resolve the Google Mobile Ads Swift Package dependency.
2. Select the `Starport` scheme and an iOS 17+ simulator.
3. Run `swift test` to validate the story model, all five ending routes, rewind behavior, catalog safety, and achievements.
4. GitHub Actions runs Swift package tests and a simulator build on PRs.

The bundle ID is currently `pro.starport.story`. Set your Apple signing team and confirm bundle ID availability before publishing. Starport has an existing signed TestFlight build and App Store Connect draft listing. Each future change needs a new signed TestFlight build after CI; no public App Store submission is implied by merging code.

### Project structure

- `Starport/Core/` — Codable models, pure adventure engine, story validation, achievement definitions
- `Starport/Content/` — editable data-only story packs, manifest, privacy declaration
- `Starport/App/` — state, offline cache, StoreKit, AdMob/UMP controls
- `Starport/UI/` — library, reader, 13+ gate, achievements, light/dark settings, ad banner
- `StarportTests/` — story-graph reachability and progress tests
- `.github/workflows/ios.yml` — test and simulator-build gates

This is an early playable foundation. Experience, writing quality, purchasing and privacy must be reviewed on real iPhone hardware before release.
