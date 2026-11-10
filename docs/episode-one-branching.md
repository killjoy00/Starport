# Episode 01 — The Door That Opens Tomorrow: branching audit

This is a map of the actual **first_signal.json, contentVersion 4** story, not just planned design.

## Decision structure

A successful run makes 36 narrative decisions and one irreversible final decision: **37 decisions total**, on every main-ending route. The 12 false endings are additional short detours that can be rewound immediately. There are 64 interactive scenes, 5 permanent endings, and 12 detours among 81 total nodes.

| Decision | Route A | Route B | What becomes exclusive |
|---|---|---|---|
| Scene 6 | Archive records (scenes s07–s11) | Outer-hull investigation (b07–b11) | Paper maps and timestamps vs physical evidence from outside |
| Scene 12 | Engine repair (s13–s17) | Juno's flight training (b13–b17) | Juno's training is the prerequisite for the slow, safe landing |
| Scene 18 | Speak to Mika live (s19–s23) | Explore the signal echo (b19–b23, c22) | Live contact is a prerequisite for the best coordinated outcome |
| Scene 24 | Crew council (s25–s29) | Under-shutter expedition (b25–b29, c28) | Shared bridge coordination vs access to manual machinery |
| Scene 30 | Synchronized blue light (s31–s35) | Manual mirror rescue (b31–b35) | The manual plan sacrifices access to the synchronized best result |

There are **two additional internal forks**: in the echo route (b21), the reader follows either Mika's cockpit (b22) or the missing passenger/cargo pulse (c22); in the under-shutter route (b27), the reader takes the electrical floor (b28) or the voice in the ventilation shaft (c28). Each route rejoins the main storyline at the next act, but consequences remain in the reader's stats and flags.

## Five outcomes, intentionally not all available at once

1. **Tomorrow arrives safely (best).** Requires clues, trust and power, a live conversation with Mika, the crew council, a coordinated-signal route, and the synchronized count. **Choosing the signal echo or manual rescue closes this ending.**
2. **The long way home (great).** Requires training with Pilot Juno, learning the old instrument-only route and adequate clues/trust. **Taking the engine-repair route instead closes this ending.**
3. **A hard landing (mixed).** Requires access to the manual mirror override and sufficient power. Earlier engineering decisions can make this possible; insufficient power can close it.
4. **The empty docking bay (poor).** Available when the reader has enough trust to order a safe retreat.
5. **The light that lied (worst).** Always available as a dangerous final choice.

All five are reachable. Automated engine tests explore **every distinct relevant combination of node, resources, and ending-required flags** and verify that all reachable permanent-ending paths consist of exactly 37 decisions. Tests also assert both route-exclusive scenes and locked endings caused by previous commitments.

## Editorial approach

The original draft used two very short paragraphs on nearly every screen, and both ordinary choices on scenes 1–36 led to the same next scene. This edition deepens the existing scenes to approximately 125–330 words per interactive scene, with varied pacing and more conversations, physical details and consequences. The earlier narrative forks and ending requirements are unchanged. The full multi-route manuscript is about **16,900 words**, but readers encounter only the portion on their chosen path. The 13+ product audience is unchanged; the prose remains an accessible middle-grade style.

The story retains original artwork on more than one third of the interactive pages, along with the cover, app icon, achievement collection, and Dark/Light/System modes.

## Save compatibility

The catalog and story use `contentVersion: 4`. Edition 4 adds prose while retaining edition 3's choices, effects and scene IDs, so StarPort readers keep their active v3 run and discovered endings. Older or structurally incompatible editions restart the active run but keep discovered endings and detours. The separate Stuffy Land app's content and behavior remain untouched.
