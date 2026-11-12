# Stuffy Land art direction

The icon and illustrations were made with the built-in ImageGen tool, using the supplied story pictures as design references. Final image assets live in `StuffyLand/Assets.xcassets/` and are consumed by the app. Image dimensions and encoding were adjusted for the asset catalog; the creative imagery was generated with ImageGen.

## Icon and logo

Final paths: `AppIcon.appiconset/AppIcon.png` and `stuffy-logo.imageset/stuffy-logo.jpg`.

Prompt: Create a production square opaque app icon, full bleed with no external corner mask. Lolo, a gray-and-tan sloth lovey with cream-tan face and dark eye markings, peeks over an open lavender storybook. A golden five-point Friendship Star hovers above the book. Deep midnight plum background, tactile plush fabric, embroidered seams, chunky silhouette readable at small sizes. Slightly narrow sloth face; no bear/cat ears. Exactly one sloth, one book, one star. No humans, other animals, lettering, labels, border, or watermark.

Initial reference was transcript image 4. A second ImageGen pass corrected the fur toward gray and tan when the expanded character bible arrived. The app uses the corrected result.

## Galaxy tent home

Final path: `stuffy-tent.imageset/stuffy-tent.jpg`.

Prompt: Landscape Stuffy Land storybook illustration. Exactly one Opal, a young girl with shoulder-length dirty-blonde curls, purple star pajamas, and a gemstone pendant, reading an open lavender book while holding exactly one Lolo, a slightly slender gray-and-tan sloth lovey with cream-tan face and dark eye patches. Purple galaxy blanket tent, sewn golden stars, lavender cushions, amber lantern, distant understated castle through the flap. Warm Friendship Star above the book. Tactile fabric, painterly children's fantasy, quiet welcoming composition. No extra humans, animals, words, labels, or watermarks.

Reference: transcript image 4. A second pass corrected Lolo's fur and Opal's hair length/color against the expanded archive. This is general welcome art and is not labeled as a literal illustration of every read-along's plot.

## Snore-Snatcher

Final path: `stuffy-snore.imageset/stuffy-snore.jpg`.

Prompt: Landscape illustration of a sleepy enormous purple pillow creature, Duke Dozington, with curled mustache and floppy nightcap, beside a brass trumpet-vacuum machine in a purple cushion castle. Golden musical notes escape the chamber. Exactly one Opal in purple star pajamas holds exactly one gray-and-tan sloth Lolo; her taller brother Langston in a blue hoodie performs a ridiculous dance, his pumpkin helmet nearby. Warm amber light, plum and lavender fabric, tactile plush storybook rendering. Silly and approachable. No additional people, dogs, cats, labels, words, or watermarks.

Reference: transcript image 7 for Duke's appearance, with written character facts controlling the remaining cast. The machine's design is a new visual interpretation. Some of Duke's arms can be hidden by his body/cushions in the scene; prose retains his four-arm canon.

## Usage

Use the icon as the small masthead mark. Use the tent image as welcome art and Pillow-Fort's representative image, and Snore-Snatcher art for that adventure. Reader cards have distinct symbols and typography instead of pretending the same image is a different bespoke cover for each book. Keep source images as editorial references rather than shipping their known continuity errors.


## Opal and the Great Sundae Switch — nine illustrated scenes

The original code-rendered vector scene illustrations have been replaced with **nine
individual, richly textured storybook illustrations** generated with ImageGen.
They use the established Stuffy Land palette of plum, lavender, warm gold,
cushioned fabrics, twinkling stitched stars and soft glowing lanterns.

The illustrated scenes remain **1, 3, 5, 7, 9, 11, 13, 15 and 17**
(exactly half the 18 main story pages). They depict nine distinct story moments:
the floating dessert, the difficult Swirly conversation, the mystery trail,
Swirly's confession, the reversed route mechanism, the big chase, the rescue
planning, the sundae landing, and the shared first spoonful.

The source images were reviewed alongside the established Stuffy Land
illustrations rather than redrawn as code-drawn shapes. Optimized 1200×720
JPEG derivatives are installed in the existing asset-catalog paths. The exact
approved bytes are hashed in `sundae-art-manifest.json` to guard against an
accidental return to the old flat artwork.

The opening sequence uses **six individually illustrated frames** from the
approved opening animation, assembled into a 3×2 atlas named
`stuffy-intro-frames.imageset` (each source frame 370×996). The app plays
these frames once per launch, then fades into the compact shelf; the user can
skip immediately, and Reduce Motion bypasses playback. There is no animated
hero or distracting loop on the story shelf itself.

These are new commissioned illustrations for the interactive story,
not recovered archive images. Canon character details continue to be
defined by `../Editorial/UNIVERSE.md`, not by incidental image-generation
details. The older code-drawn generator has been retired and must not be run
against the approved image assets.


## Opal and TITANUS: planned illustrations

Status: **pending**. The adventure is published without its own art. Its
scenes already point at eleven planned asset names, so each picture appears
as soon as it is added, with no story change. Until then the app shows its
drawn storybook placeholder, and the shelf uses the tent cover.

`titanus-art-plan.json` holds the shared style line, each image's prompt,
alt text and the scenes that use it, plus a portrait cover prompt
(`titanus-cover`). Make them as textured, painterly storybook scenes in the
Sundae Switch style, not with a code-drawn generator. Save each as
`StuffyLand/Assets.xcassets/<asset>.imageset/<asset>.jpg` (1200×720 for scenes)
with a matching `Contents.json`. When the cover exists, change the catalog's
`coverAsset` for `stuffy-titanus` in `scripts/build_stuffyland_collection.py`
and rebuild.

The eleven scenes are: Langston upside down in the tree; Titanus arriving over
the mountains; everybody floating in the moon shield; the carvings behind the
waterfall; Titanus's lullaby by the empty cradle; the river that flows uphill;
the Dragon Couple circling the cracked bell; the throne room; the tiny team at
the golden lever; the Donut of Distraction; and everybody bringing their light
to the cradle. `scripts/validate_stuffyland.py` allows only these planned
assets to be missing and reports them as pending art.
