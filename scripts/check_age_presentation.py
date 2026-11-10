#!/usr/bin/env python3
"""Ensure Stuffy Land uses store-managed age classification, not an age prompt.

This is a source-level regression guard for the shared SwiftUI entry point.
It intentionally does *not* claim to verify the App Store Connect rating;
that remains a separate distribution setting.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
brand = (ROOT / "Starport/App/AppBrand.swift").read_text()
root = (ROOT / "Starport/UI/StarportRootView.swift").read_text()
settings = (ROOT / "Starport/UI/SettingsScreen.swift").read_text()
ads = (ROOT / "Starport/App/AdsController.swift").read_text()

assert "var requiresInAppAgeConfirmation: Bool { !isStuffyLand }" in brand
assert "private var canOpenLibrary: Bool { !AppBrand.current.requiresInAppAgeConfirmation || ageConfirmed }" in root
assert "if !canOpenLibrary {" in root
assert "AgeGateView(onConfirm13Plus:" in root, "Keep Starport's separate gate."
assert ".task(id: canOpenLibrary)" in root, "Stuffy Land must prepare services without an age prompt."
assert "if canOpenLibrary, purchases.entitlementsLoaded" in root
assert "STUFFY LAND · FOR READERS AGES 13+" not in root
# The first screen should be the actual shelf, not a welcome/marketing panel.
assert 'Text("A little wonder.\\nA lot of friends.")' not in root
assert 'Text("Settle in with a story' not in root
assert 'Image("stuffy-tent")' not in root
assert 'Text("Your story shelf")' not in root
assert 'private var unfinishedStory: AdventureListing?' in root
assert 'engine.progress.started, !engine.isComplete' in root
assert 'game.readerBook != nil && game.readerPageIndex > 0' in root
assert 'Text("Continue")' in root
assert 'Button { onOpen(unfinishedStory) }' in root
assert 'ForEach(filtered) { entry in' in root
assert 'storyRow(entry)' in root
assert 'Button { onOpen(entry) } label:' in root
assert 'Text(entry.subtitle)' not in root[root.index("/// Stuffy Land's compact bookshelf."):]
assert 'Text("Read-alongs").tag(1)' in root
assert 'Text("Adventures").tag(2)' in root

assert "Stuffy Land currently has a 13+ development age gate" not in settings
assert 'if AppBrand.current.isStuffyLand {' in settings
assert "configuration.ageRestrictedTreatment = .teen" in ads
assert "configuration.maxAdContentRating = .general" in ads
assert "configuration.publisherPrivacyPersonalizationState = .disabled" in ads
print("PASS Stuffy Land opens directly to a minimal one-tap story shelf; Starport gate and ad safeguards remain.")
