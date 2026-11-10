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

Nine distinct 1200×720 illustrations are bundled in the `sundae-scene-XX.imageset` directories, for interactive scenes **1, 3, 5, 7, 9, 11, 13, 15 and 17**. They are *original code-rendered felt-and-paper illustrations*, not recovered story paintings, ImageGen outputs, app screenshots or unaltered source material. They are produced deterministically by `scripts/generate_sundae_art.py` using Pillow. Do not confuse the new source with the older ImageGen work documented above.

Continuity is based on the universe bible: Opal has shoulder-length dirty-blonde curls and purple star pajamas; Lolo is a thin gray-and-tan **sloth** lovey; Swirly is a chocolate-brown ice-cream **cat**, Vanilla-y a pale vanilla cat, Axey a pink axolotl, Langston a visibly taller boy in a blue hoodie, and Finley and Stella exactly two fluffy white doodle dogs. Coatl's shell belongs on his back. Character groupings vary by scene. The nine artworks show different events rather than relabeling one illustration.

| Scene | Composition |
| --- | --- |
| 1 | The flying cherry, Langston, Frosted Kitty, Opal and Lolo in the galaxy tent |
| 3 | Opal talks cautiously to Swirly; Lolo listens |
| 5 | Axey and the two white doodle detectives follow the cushion tunnel |
| 7 | Swirly confides in Opal with Lolo close by |
| 9 | The upside-down route spinner behind the reading pillows |
| 11 | A giant floating sundae races toward the village |
| 13 | Opal coordinates a real rescue plan with the specialist friends |
| 15 | Swirly, Vanilla-y, Coatl and Axey guide the giant sundae to safety |
| 17 | Opal and Swirly share a quieter moment beside the rescued dessert |

The story shelf uses scene 1 as this adventure's unique cover art. Its illustrations are purely visual and contain no printed text, labels or UI.
