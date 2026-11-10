# Starport

A native, offline choose-your-own-adventure iOS app with original science fiction for readers around ages **11–13**.

## Episode 01: The Door That Opens Tomorrow

A ship due tomorrow sends a warning today. Explore Starport Nine, gather clues, choose who to trust, and decide how to guide the ship through a glass storm.

**This MVP includes:** 26 scenes, 52 choices, six distinct endings, conditional choices based on Clues / Power / Trust, persistent progress, ending discovery, and an accessible SwiftUI reading interface.

## Play and build

- Open `Starport.xcodeproj` in Xcode 16 or later.
- Select the **Starport** scheme and an iOS 17+ simulator.
- Press **Run**. No API keys or server are required.
- To run the cross-platform story engine tests: `swift test`.
- GitHub Actions runs story tests and a simulator build for each pull request.

The Xcode project currently uses the placeholder bundle identifier `com.starport.story`. Choose your own unique identifier and Apple Developer signing team before distributing to devices or TestFlight. **This code is not yet a signed or App Store-published build.**

## How the story works

- `Starport/Content/first_signal.json` holds scenes, choices, conditional requirements, and effects. This can be edited to expand the story without rewriting the UI.
- `Starport/Core/` loads and validates the story and applies choices.
- `Starport/UI/` holds the visual interface.
- `StarportTests/` tests the real graph, including whether *all six endings* can be reached with valid choices.
- Every decision is saved locally through `UserDefaults`. Restarting a run retains discovered endings.

Stats are deliberately simple and transparent:
- **Clues** unlock sophisticated solutions.
- **Power** is spent operating old station hardware.
- **Trust** determines whether other people help.

Locked options explain their requirements. No ending leads to explicit violence or harm; failures still move the story forward.

## Editorial guide for future episodes

Write directly to the reader in the second person, with clear language, specific sensory details, and character-driven humor. Keep scenes short enough to read on a phone. Make at least two choices at meaningful crossroads and honor earlier discoveries in later decisions. Keep stakes high without gore or gratuitous cruelty. Story text is original; avoid reproducing existing science-fiction universes or passages.

## Privacy and scope

The MVP has **no login, ads, analytics, chat, notifications, AI-generated responses, or network requests**. Progress stays on the device. It requires no personal information from children. Keep this privacy posture in mind when adding future features.

The app includes a privacy manifest declaring local UserDefaults use. Apple still requires App Store Connect privacy and age-rating information before submission; the target reader age (11–13) is not itself an App Store rating.

This is a first playable episode, not yet a complete multi-episode game, a TestFlight build, or an App Store submission.
