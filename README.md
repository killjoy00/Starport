# Starport & Stuffy Land

This repository contains **two distinct iOS apps** using one shared branching-adventure engine. `Starport` is the science-fiction adventure shelf. `StuffyLand` is a separately installed, independently branded storybook app with its own catalog, achievements, save keys, App Store configuration and ad/purchase IDs.

The current first Stuffy Land story is a **provisional pilot**, not established Stuffy Land canon. See [StuffyLand/README.md](StuffyLand/README.md) for story contents, target setup and the age/privacy release blockers.

Both apps have their own Xcode schemes in `Starport.xcodeproj`. Choose `Starport` or `StuffyLand`. They share files from `Starport/Core`, `Starport/App` and `Starport/UI`, but bundle different content resources. Run `python3 scripts/validate_stuffyland.py` for the Stuffy Land graph validation; CI also builds both targets.

---

## Starport

**Starport** is a native iOS adventure library intended **only for people ages 13 and older**. It has a 13+ self-declaration gate before the library, stories, ads, or purchase UI becomes accessible. No birth date, name, or account is required.

**Editorial distinction:** The adventures use the prose length, vocabulary, pacing, and science-fiction sensibility of strong middle-grade books (roughly a 10–12-year-old *reading level*). **The product is not intended for children aged 10–12.** Do not market it as an under-13 app or put it in Apple's Kids category. In App Store Connect, accurately answer the content questions and use **Override to Higher Age Rating → 13+** if Apple's calculated rating is lower. Self-declaration is not independent proof of age.

## Story library

Starport is a container for multiple separately packaged adventures. The app boots with one story and a **Check for new adventures** action. New stories can be published as JSON data in `Starport/Content/` on `main`, without an iOS binary change (the reader executes no downloaded code). A cached, previously validated version works offline.

The manifest `Starport/Content/catalog.json` lists an adventure's stable ID, version, filename, title, genre, symbol, summary, and duration. The `AdventureRepository` downloads the manifest and new stories from the public GitHub repo, validates all story graphs, and atomically activates the catalog. Only safe filenames and validated JSON are permitted. It is intentionally *opt-in*: no background refresh or automatic downloads.

To add an adventure, add a validated story `<story_name>.json`, include its entry in `catalog.json`, and merge both to `main`. Increase `contentVersion` when changing a published story, because saved games are versioned per adventure.

## Episode 01 — The Door That Opens Tomorrow

A ship scheduled for tomorrow sends a warning today. Read the evidence, work with the crew, and decide how to guide the Wren through a glass storm.

- **36 story decisions plus a final decision**, so each route to a permanent ending is **37 decisions long**. The validator enforces a minimum of 30.
- **Five permanent endings**, individually ranked from **1 (best) to 5 (worst)**. No rewind is permitted once one is reached. A new run begins at the opening scene, while the endings collection is retained.
- **Twelve false endings** that can be immediately unwound, restoring the prior scene, Clues, Power, Trust, choice history, and decision count. Discovered detours persist as collectibles.
- Resources and flags change choice availability, follow-up text, and the ending options. Different choices along a shared scene spine have persistent mechanical consequences.
- **25 achievements**: one per true ending, recoverable detours, unusual clues, story allies, resource milestones, and completion challenges. Achievements persist across new runs and are displayed on an offline trophy shelf.

The story is suspenseful, character-driven, and age-appropriate, with no graphic violence. A poor outcome can be sad without becoming graphic.

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

The bundle ID is currently `pro.starport.story`. Set your Apple signing team and confirm bundle ID availability before publishing. This repository is **not yet a signed TestFlight build or an App Store submission**.

### Project structure

- `Starport/Core/` — Codable models, pure adventure engine, story validation, achievement definitions
- `Starport/Content/` — editable data-only story packs, manifest, privacy declaration
- `Starport/App/` — state, offline cache, StoreKit, AdMob/UMP controls
- `Starport/UI/` — library, reader, 13+ gate, achievements, light/dark settings, ad banner
- `StarportTests/` — story-graph reachability and progress tests
- `.github/workflows/ios.yml` — test and simulator-build gates

This is an early playable foundation. Experience, writing quality, purchasing and privacy must be reviewed on real iPhone hardware before release.
