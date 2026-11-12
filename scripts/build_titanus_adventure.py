#!/usr/bin/env python3
"""Build "Opal and TITANUS" as a branching Stuffy Land adventure.

An interactive retelling of the complete story the author supplied, which is
kept unchanged in StuffyLand/Editorial/source/titanus.md. This script is the
editable source for StuffyLand/Content/titanus.json and for the planned
illustration list in StuffyLand/Design/titanus-art-plan.json.

    python3 scripts/build_titanus_adventure.py

Shape: a shared opening, two forks with routes of different lengths, then
three endgames that earlier discoveries unlock or close:

  * Bring the little star home  - needs the star's story and the last golden piece
  * Send the tiny team to the bell - needs the tiny door into the bell
  * Let The Annoyings handle it    - always open

Every run is 22 to 25 choices long and ends at one of seven endings.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "StuffyLand" / "Content" / "titanus.json"
PLAN = ROOT / "StuffyLand" / "Design" / "titanus-art-plan.json"

STAT = {"cur": "clues", "cou": "power", "fri": "trust"}
STAT_NAME = {"clues": "Curiosity", "power": "Courage", "trust": "Friendship"}
nodes = []


def smart(text):
    """Straight quotes to the curly quotes the rest of Stuffy Land uses."""
    text = text.replace("'", "’")
    out, open_quote = [], True
    for ch in text:
        if ch == '"':
            out.append("“" if open_quote else "”")
            open_quote = not open_quote
        else:
            out.append(ch)
    return "".join(out)


def paras(text):
    return [smart(" ".join(p.split())) for p in re.split(r"\n\s*\n", text.strip()) if p.strip()]


def effects(spec):
    out = []
    for tok in spec.split():
        if tok.startswith("f:"):
            out.append({"flag": tok[2:]})
        else:
            out.append({"stat": STAT[tok[:3]], "delta": int(tok[3:])})
    return out


def need(*specs):
    out = []
    for s in specs:
        if s.startswith("f:"):
            flag, hint = s[2:].split("|")
            out.append({"flag": flag, "hint": hint})
        else:
            stat, n = STAT[s[:3]], int(s[3:])
            out.append({"stat": stat, "atLeast": n, "hint": f"Build up {n} {STAT_NAME[stat]} along the way."})
    return out


def C(label, to, fx="", needs=()):
    return {"label": smart(label), "to": to, "fx": fx, "needs": needs}


def D(label, n):
    return {"label": smart(label), "to": f"detour_{n:02d}", "fx": "", "needs": (), "detour": True}


ART = {}


def scene(sid, act, title, text, choices, echoes=(), art=None):
    built, k = [], 0
    for c in choices:
        if c.get("detour"):
            cid = f"{sid}_detour"
        else:
            k += 1
            cid = f"{sid}_choice_{k}"
        item = {"id": cid, "label": c["label"], "to": c["to"]}
        if c["fx"]:
            item["effects"] = effects(c["fx"])
        if c["needs"]:
            item["requirements"] = need(*c["needs"])
        built.append(item)
    node = {"id": sid, "act": act, "title": smart(title), "paragraphs": paras(text)}
    if art:
        node["illustration"] = {"asset": art, "alt": ART[art]["alt"]}
    if echoes:
        node["conditionalParagraphs"] = [
            {"requirement": {"flag": f, "hint": "Something you did earlier."}, "text": smart(t)} for f, t in echoes]
    node["choices"] = built
    nodes.append(node)


def detour(n, title, text):
    nodes.append({"id": f"detour_{n:02d}", "act": "A little detour", "title": smart(title),
                  "paragraphs": paras(text),
                  "ending": {"id": f"detour_{n}", "kind": "detour", "title": smart(title),
                             "note": "Everyone is safe. Try another way from the last choice."}})


def ending(rank, title, text, teaser=None):
    body = paras(text)
    if teaser:
        body += paras(teaser)
    nodes.append({"id": f"final_{rank}", "act": "A Stuffy Land memory", "title": smart(title),
                  "paragraphs": body + ["The End."],
                  "ending": {"id": f"final_{rank}", "kind": "final", "rank": rank, "title": smart(title),
                             "note": "This ending is saved in your memory book. You can return to the story and discover another way."}})


# ───────────────────────── planned illustrations ─────────────────────────
# Asset names the scenes already point at. Until each picture is added to
# StuffyLand/Assets.xcassets, the app shows its drawn storybook placeholder.

STYLE = ("Landscape Stuffy Land storybook illustration, 1200x720. Textured, painterly children's fantasy with "
         "tactile plush fabric and stitched seams, warm amber light, plum, lavender and gold palette. "
         "Human Opal is a young girl with shoulder-length dirty-blonde curls. Lolo is exactly one slender "
         "gray-and-tan sloth lovey with a cream-tan face and dark eye patches, never a bear. Langston is "
         "Opal's visibly taller, bigger older brother in a blanket cape and saucepan helmet. Every Aphmau "
         "plush is clearly a cat. Include only the named characters, once each. No words, labels or watermarks.")

ART.update({
    "titanus-scene-tree": dict(
        alt="Langston dangles upside down from a tree by one foot while Coatl gently lowers the branch and Opal and Lolo watch, laughing.",
        scenes="Upside down in a tree",
        prompt="A bright morning meadow with marshmallow clouds. Langston hangs upside down from a tree branch by one foot, his blanket cape wrapped round his head and his saucepan helmet dangling from a smaller branch. Coatl, a gentle giant turtle with his shell on his back, gently lowers the branch. Opal holds Lolo and giggles; Axey, a pink axolotl plush, bounces nearby."),
    "titanus-scene-arrival": dict(
        alt="The giant Titanus leans over the mountains with glowing purple eyes, a crown of crystals and a golden bell, while the tiny friends look up from the meadow.",
        scenes="I AM TITANUS",
        prompt="The sky has gone dark. Titanus, an enormous stone giant taller than the mountains, with stone shoulders, glowing purple eyes, arms like bridges, dark armour and a crown of jagged crystals, leans over the mountains. A giant golden bell hangs round his neck. Far below in the meadow, a glowing heart-shaped crystal floats above a small pedestal. Tiny Opal holding Lolo, Langston in his saucepan helmet, and Coatl look up. Awe, not terror: he is grand and a little sad-eyed."),
    "titanus-scene-float": dict(
        alt="Opal hugs Lolo as friends float up into the sky, and a glowing moon-shaped shield gathers them together while Coatl stays planted on the ground.",
        scenes="Everybody floats",
        prompt="After the giant bell rings, Stuffy Land friends float into the air above the meadow: Opal hugging Lolo, Langston holding Frosted Kitty (a donut cat), Finley holding Stella (two fluffy white doodle girls). Nebula Johnny, a cosmic cat, spreads a glowing moon-shaped shield bubble around them. Coatl stays firmly planted below. Whimsical, gentle, a little silly."),
    "titanus-scene-waterfall": dict(
        alt="Behind a waterfall, Opal, Lolo, Coatl, Finley and Stella study old carvings of a giant protecting a little star.",
        scenes="Behind the waterfall",
        prompt="Inside a cave behind a shimmering waterfall, ancient carvings glow faintly on the stone: a giant holding a small glowing star, protecting many tiny creatures; the giant standing alone; a golden bell. Opal and Lolo study them. Coatl's underside buttons glow softly. Finley holds a detective notebook; Stella sniffs a gold fragment on the floor."),
    "titanus-scene-lullaby": dict(
        alt="Through a fortress window at dusk, Axey and Aaron-y watch Titanus sitting beside an empty stone cradle, humming a sad lullaby.",
        scenes="A song in the fortress",
        prompt="Dusk. Through a tall purple-glowing window of a mountain fortress, we see Titanus sitting on the floor beside an empty stone cradle, his huge head bowed, humming. In the foreground, peeking over the window ledge: Axey the pink axolotl and Aaron-y, a gray-and-black wolf-like spy cat in a black hoodie with red ear and tail highlights. Tender and quiet."),
    "titanus-scene-river": dict(
        alt="Opal, Lolo and friends ride a raft up a sparkling river that flows uphill toward a mountain fortress.",
        scenes="A river that goes uphill",
        prompt="A sparkling magical river flows UPHILL toward a mountain fortress with purple windows. Water Kitty and Mermaid Kitty guide it. On a leaf raft: Opal holding Lolo, Langston, Axey, Finley and Stella. Stella points her nose at a golden glint under the water. Joyful and adventurous."),
    "titanus-scene-bell": dict(
        alt="The Dragon Couple carries Opal and Lolo around a giant cracked golden bell at the top of the fortress tower.",
        scenes="The crack in the bell",
        prompt="High above the clouds, the Dragon Couple fly together: an entirely purple boy dragon-cat and a dark-blue girl dragon-cat with a light-blue gem. Opal, holding Lolo, rides on one. They circle a gigantic golden bell at the top of a fortress tower; a long crack runs down the bell and a tiny round door sits near its base. Windswept and wondrous."),
    "titanus-scene-throne": dict(
        alt="Titanus sits on a stone throne holding the glowing Heart of Stuffy Land, with an empty stone cradle behind him, as Opal steps forward.",
        scenes="The throne and I have no heart of my own",
        prompt="A vast throne room inside the mountain fortress. Titanus sits on a giant stone throne, cupping the glowing heart-shaped crystal of Stuffy Land in both enormous hands. Behind the throne, an empty stone cradle in a dark alcove. Small Opal steps forward holding Lolo, with Coatl and Langston behind her. Purple light, a hint of loneliness in the giant's face."),
    "titanus-scene-lever": dict(
        alt="Crumb-sized Onion Ring Kitty and rainbow Caterpillar Kitty pull together on a small golden lever inside the giant bell.",
        scenes="The tiny team",
        prompt="Inside the brass workings of a giant bell, enormous gears all around. Onion Ring Kitty, shrunk to crumb size, and Caterpillar Kitty, a tiny cat with rainbow segments each a different colour, wrap around a small golden lever and pull with all their might. A sliver of light from a tiny round door behind them. Heroic and tiny."),
    "titanus-scene-donut": dict(
        alt="Langston in his saucepan helmet and Frosted Kitty point up at a giant donut that has landed on Titanus's shoulder.",
        scenes="HEY, GIANT!",
        prompt="Throne room. A giant pink-frosted donut decoy has landed on Titanus's enormous shoulder and he stares at it, baffled. Below, Langston in a saucepan helmet and blanket cape points up triumphantly beside Frosted Kitty, a donut cat. Evil Queen Kitty, a purple cat with silver tiara and royal cape, stands on a broken piece of throne mid-speech. Comic and lively."),
    "titanus-scene-star": dict(
        alt="Friends stand in a glowing circle around a stone cradle as a tiny star rises toward Titanus's open hand.",
        scenes="Everybody, bring your light!",
        prompt="A circle of Stuffy Land friends stands round an empty stone cradle, each glowing with their own light: Opal with a glowing gemstone pendant and Lolo holding her hand, Coatl, Langston and Frosted Kitty, the Dragon Couple, and as many of the Aphmau cats as fit, each once. A tiny golden star rises out of the cradle toward Titanus's enormous open hand. A single huge golden tear on his cheek. The emotional climax: warm, golden, hopeful."),
})
COVER = dict(asset="titanus-cover",
             prompt="Portrait 900x1350 storybook cover. Titanus, a gentle-eyed stone giant with a crystal crown and a golden bell, leans down over the mountains of Stuffy Land; small Opal holding Lolo looks up at him from the meadow, with Langston in his saucepan helmet beside her. A tiny star glows near the giant's shoulder. Leave clear space at the top for the title.")


# ───────────────────────── ACT 1: A perfectly ordinary morning ─────────────────────────
A1 = "A perfectly ordinary morning"

scene("s01", A1, "Upside down in a tree", """
It was a beautiful morning in Stuffy Land. The birds were singing, the flowers were sparkling, and the clouds looked like giant marshmallows.

And Langston was stuck upside down in a tree.

"OPAL!" he bellowed. "I HAVE A VERY IMPORTANT ANNOUNCEMENT!"

Opal looked up from her breakfast. Lolo, her slender gray-and-tan sloth, was snuggled beside her. "Are you stuck?"

"THAT IS COMPLETELY UNRELATED!"

Outside, Langston dangled from a branch by one foot. His blanket cape was wrapped round his head, and his saucepan helmet hung from a smaller branch like a very serious Christmas ornament.

Axey, the pink axolotl, bounced over. "How did you get up there?"

"I was testing a new troll climbing technique," said Langston with dignity. "I climbed successfully. Then I kept climbing."

Lolo giggled. Opal tried very hard not to. Her big brother was the tallest, bravest, most trolly person she knew, and right now he was swinging gently in the breeze.
""", [
    C("Ask Coatl to lower the branch", "s02", "fri+1 f:coatl_helped"),
    C("Send Axey up to untangle the cape", "s02", "cur+1 f:axey_climbed"),
    D("Throw pancakes up to Langston", 1),
], art="titanus-scene-tree")

scene("s02", A1, "The sky goes black", """
Langston landed on his feet, mostly. "Thank you. I meant to do that."

Finley and Stella came racing across the grass, two fluffy white doodle girls with their ears flying. Finley flipped open her detective notebook. Stella gave Langston's saucepan helmet a long, thoughtful sniff.

"Case closed," Langston declared. "The tree attacked me."

Axey had a theory that the tree was jealous. Finley wrote TREE: SUSPICIOUS in her notebook, then crossed it out and wrote TREE: PROBABLY FINE. Stella lay down at Langston's feet and leaned against his leg, which is what Stella does when somebody has had a long morning, even if it is only nine o'clock.

Opal laughed. It was going to be a perfectly ordinary day.

Then the sky turned black.

Not nighttime black. Not storm-cloud black. ENORMOUS, SOMETHING-IS-COMING black.

The birds stopped singing. The flowers folded their petals. The ground shook.

THUUUUUUUM.

A ripple ran across the lake. Then another.

THUUUUUUUM.

Opal felt it through her feet first: a deep rumble, like the biggest drum in the world being played very slowly, very far away, and getting closer.

Lolo's paw found Opal's hand and held on tight.
""", [
    C("Gather everyone in the meadow", "s03", "fri+1"),
    C("Climb Lookout Hill to see what is coming", "s03", "cur+1 f:saw_footprints"),
    D("Hide under the breakfast table", 2),
], echoes=[
    ("axey_climbed", "Axey was still halfway up the tree when the sky changed. \"Opal!\" she squeaked. \"Something is walking over the mountains. Something BIG.\""),
    ("coatl_helped", "Coatl lifted his great head. The buttons on the underside of his shell had begun to glow, slow and purple, the way they only did when something powerful was near."),
])

scene("s03", A1, "I AM TITANUS", """
A gigantic shadow slid across the sun.

Something was coming over the mountains. Something so big its head was higher than the tallest peak. Something so big its footsteps made the lakes ripple. Something so big that even Langston stopped talking.

The giant had enormous stone shoulders, glowing purple eyes and arms like bridges. A crown of jagged crystals stretched across his head. Round his neck hung a golden bell the size of a house. Wherever he stepped, he left a glowing footprint in the ground.

He leaned down until his face filled the whole sky.

"I AM TITANUS," he said, and the words rumbled through every corner of Stuffy Land. "THE GREATEST GIANT IN ALL THE REALMS. I HAVE COME FOR THE HEART OF STUFFY LAND."

He pointed at the middle of the meadow, where a beautiful crystal floated above a little pedestal. The Heart of Stuffy Land. Its gentle glow was the magic that connected every stuffy, every adventure and every friendship.

Langston raised his hand. "Question. Do you have snacks?"

"SILENCE, TINY TROLL!"

Langston lowered his hand. "Okay. Definitely a bad guy."
""", [
    C("Ask Titanus why he wants the Heart", "s04", "cur+1 f:asked_why"),
    C("Stand in front of the Heart with Coatl", "s04", "cou+1 f:guarded_heart"),
    D("Let Langston ask one more question", 3),
], echoes=[
    ("saw_footprints", "From Lookout Hill you had seen his footprints glowing in a long line behind him, all the way back to a fortress carved into the farthest mountain."),
], art="titanus-scene-arrival")

scene("s04", A1, "DOOOOOOOONG!", """
Opal gathered everyone in the meadow as fast as she could.

Cherryberry led the Aphmau kitties in at a run. Cinny was clutching a cinnamon-roll snack. The Dragon Couple swooped overhead, purple boy and dark-blue girl side by side. Nebula Johnny floated above the crowd with his moon shield, and Frosted Kitty rolled straight to Langston. "Annoying team meeting?" "The Annoyings are officially on duty," said Langston.

Titanus lifted one enormous foot and brought it down beside the meadow.

KABOOOOOOOM!

A wave of dirt and leaves rolled toward them. Coatl stepped forward, planted his feet, and the buttons under his shell blazed. A dome of warm light spread round everyone, and the wave rolled harmlessly past.

"INTERESTING," said Titanus. He raised his golden bell.

DOOOOOOOOOONG!

Every flower folded. Every tree bent. And every stuffy in the meadow began to float.

"WHOA!" yelled Axey, drifting past Opal's nose.

Opal grabbed Lolo. Langston grabbed Frosted Kitty. Finley grabbed Stella. Only Coatl stayed put, his legs planted like tree trunks.

"MY BELL CONTROLS GRAVITY!" boomed Titanus. "SOON YOUR WHOLE LAND WILL FLOAT INTO MY HANDS!"
""", [
    C("Call for Nebula Johnny's moon shield", "s05", "cou+1 f:moon_shield"),
    C("Link everyone into a friendship chain", "s05", "fri+1 f:friend_chain"),
    D("Flap your arms like a bird", 4),
], echoes=[
    ("asked_why", "As the bell rang, Opal remembered how his voice had wobbled when she asked why. Bad guys didn't usually wobble."),
    ("guarded_heart", "Coatl had not moved one step from the Heart. It hung safely in its little glow behind him, for now."),
], art="titanus-scene-float")

scene("s05", A1, "A very formal complaint", """
Nebula Johnny's moon shield spread round the floating friends like a glowing bubble. Water Kitty made a gentle stream that carried everyone downward. Fire Kitty warmed the air beneath them so the landing would be soft, and the Dragon Couple swooped round to catch anyone who drifted too far. Spirit Kitty sang a breezy little song that nudged the last few friends back toward Coatl.

Everyone landed safely, in a heap, on the grass.

Langston stood up, straightened his cape, and pointed at the mountains. "I would like to formally complain about the giant."

Titanus had stomped back toward his fortress, laughing. But the Heart was still on its pedestal. For now.

"How are we supposed to stop something THAT big?" asked Axey.

Lolo looked at the glowing footprints. "Maybe," she said quietly, "we should find out why he wants the Heart first."

Finley was already nose-down in the nearest footprint. She came up with something tiny and golden in her mouth. Coatl looked at it, and his buttons flickered faster than Opal had ever seen.

There were two ways to find out more.
""", [
    C("Follow Coatl to the mountains", "a1", "f:route_mountain"),
    C("Spy on Titanus with Axey and Aaron-y", "b1", "f:route_spy"),
], echoes=[
    ("friend_chain", "Nobody had let go of anybody the whole time. Cherryberry said it was the best friendship chain in Stuffy Land history, and Onion Ring Kitty, riding on her shoulder, agreed."),
])

# ───────────────────────── ROUTE A: The waterfall secret (5 scenes) ─────────────────────────
RA = "The waterfall secret"

scene("a1", RA, "Golden pieces", """
Finley dropped the golden thing into Opal's hand. It was a curved little piece of metal, warm as toast, with a pattern pressed into it: a tiny star inside a bell.

Stella found another piece in the next footprint, and Finley found a third. Finley wrote in her notebook: GOLD. CURVY. NOT A COOKIE. She underlined NOT A COOKIE twice, which suggested she had checked.

Opal turned one of the pieces over. It was smooth on one side and rough on the other, as if it had snapped off something much bigger. When she held it up to the light, the tiny star in the pattern seemed to twinkle, just for a second. Lolo saw it too. Neither of them said anything, but Lolo's paw tightened round Opal's hand.

"They look like bits of a bell," said Axey. "An old one."

Axey was already peering into the next giant footprint, which was so deep she could have used it as a swimming pool.

Coatl stared at the star-in-a-bell pattern. Then he turned his great head toward the tallest mountain, where a thin silver waterfall tumbled down the rocks, and began to walk.

Coatl did not talk much. When he walked like that, it meant: follow me.
""", [
    C("Collect every golden piece you can find", "a2", "cur+1 f:pieces_collected"),
    C("Ask Finley and Stella to sniff out the trail", "a2", "fri+1"),
    D("Let Stella taste one, just to be sure", 5),
])

scene("a2", RA, "The wobbly bridge", """
The path up the mountain was steep and twisty. Halfway up, it stopped at a rope bridge strung across a rushing river. The bridge swayed. It creaked. It made a noise that sounded a lot like "nope."

Langston peered over the edge. "I would like everyone to know I am very brave and also not looking down."

Finley tested the first plank with one paw, sniffed it, and wrote BRIDGE: WOBBLY, VERY in her notebook. Stella sat down on the path and looked at Opal with her calm brown eyes, as if to say: whatever you decide, I'll come too.

Axey was already bouncing on the first plank. Lolo clung to Opal's shoulder. Far below, the river sparkled and roared.

Coatl looked at the bridge, then at his friends, then at the wide, flat top of his own shell.

Opal looked at the bridge, and the river, and her friends. Being brave didn't always mean going first. Sometimes it meant choosing the way that got everybody across.
""", [
    C("Cross the bridge one at a time, holding the ropes", "a3", "fri+1"),
    C("Ride across on Coatl's shell", "a3", "cou+1"),
], echoes=[
    ("pieces_collected", "Opal's pocket clinked with golden pieces. Every one had the same tiny star pressed into it."),
])

scene("a3", RA, "Behind the waterfall", """
At the top, the waterfall poured down like a silver curtain. Coatl stepped right through it. Opal held her breath and followed.

Drops of water pinged softly somewhere in the dark, and the air smelled of wet stone. Coatl's buttons glowed, lighting the walls with a soft golden light.

Behind the water was a cave, and the cave walls were covered in pictures carved into the stone.

The first picture showed a giant holding a small glowing star. Below him were hundreds of little creatures, and the giant's arms curled round them like a roof. He was protecting them.

The second picture showed the same giant standing alone. The star was gone.

The third picture showed a golden bell hanging round his neck.

Opal's breath made a little cloud in the cool air. "That's Titanus," she whispered.

Lolo studied the pictures for a long time. "I think," she said, "he used to be a guardian. And I think he lost his star."

Axey pressed her face right up to the second picture, the giant standing all alone. "He looks so lonely," she said. Coatl made a low, rumbling sound, the closest thing to a sigh a turtle can make.
""", [
    C("Study every carving closely", "a4", "cur+1 f:knows_star f:titan_carvings"),
    C("Ask Lolo what she thinks happened", "a4", "fri+1 f:knows_star f:titan_carvings"),
], art="titanus-scene-waterfall")

scene("a4", RA, "The secret message", """
Under the last picture ran a line of strange markings. Aaron-y, the gray-and-black spy kitty in the black hoodie, had come along "for intelligence purposes." He tilted his head. Aphmau-y leaned in beside him, and together they traced the shapes with their paws, one symbol at a time.

"When the little lights disappear," Aaron-y read slowly, "the giant will seek the brightest heart."

Everyone went quiet.

Opal read the words again in her head. Little lights. The brightest heart. She thought of the Heart of Stuffy Land glowing above its pedestal, and the way it made everyone feel close even when they were far apart.

"The brightest heart," said Opal. "That's our Heart. He thinks it can bring his star back."

"Still doesn't give him permission to stomp round our house," said Langston, who had arrived soaking wet because he had walked through the waterfall very slowly on purpose.

"True," said Opal.

In the corner of the cave, Stella was sniffing at a crack in the rock, her tail wagging hard.
""", [
    C("Hurry back before Titanus does something", "a5", "cou+1"),
    C("Search the cave for one more golden piece", "a5", "cur+1 f:last_fragment"),
    D("Shout HELLO to hear the echo", 6),
], echoes=[
    ("pieces_collected", "Opal laid her golden pieces on the cave floor. They fitted together into most of a curved shape, like the rim of something. One piece was missing."),
], art="titanus-scene-waterfall")

scene("a5", RA, "We need to talk to him", """
They hurried back down the mountain as the sun began to sink.

Opal thought the whole way. A giant who used to protect little creatures. A star that went missing. A bell. A message about the brightest heart.

Lolo walked beside her without saying anything, which is one of the things Lolo is best at. Every now and then she looked up, and Opal knew she was wondering the same thing: what would it feel like to lose your very best friend, and look for them for hundreds of years?

"Maybe Titanus thinks taking our Heart will bring something back," she said at last.

Axey bounced. "AN ANCIENT MYSTERY!"

"A mystery with very big feet," said Langston.

Back in the meadow, everyone crowded round to hear. When Opal told them about the giant who used to protect little creatures, Cherryberry's ears drooped, and Turtle Kitty came all the way out of her shell to listen.

Opal smiled. "We need to talk to him. And if he won't listen, we need a plan good enough that he has to."
""", [
    C("Tell everyone what the carvings mean", "s11", "fri+1"),
    C("Draw the carvings in Finley's notebook", "s11", "cur+1 f:drawn_carvings"),
], echoes=[
    ("last_fragment", "In Opal's hand was the piece Stella had found in the crack. It wasn't curved like the others. It was star-shaped, and it was very slightly warm, as if something inside it was waiting."),
])

# ───────────────────────── ROUTE B: Spies in the dark (4 scenes) ─────────────────────────
RB = "Spies in the dark"

scene("b1", RB, "The spy team", """
Aaron-y pulled up the hood of his black hoodie. "This calls for a stealth mission."

The spy team was small: Axey, who was fearless; Aaron-y, who was sneaky; and Caterpillar Kitty, whose rainbow segments could each wiggle a different way, which is very useful for squeezing into places. The Dragon Couple offered to fly them close.

Caterpillar Kitty packed her sticky goo, just in case. Aaron-y packed a walkie-talkie, tiny binoculars and three cinnamon rolls from Cinny, for energy. Axey packed nothing, because explorers travel light, and then went back for a snack anyway.

Opal and Lolo stayed behind to keep the Heart safe, but Opal gave Axey her best walkie-talkie and a very serious look. "Be careful. Find out WHY."

As the sun went down, the team set off toward the fortress carved into the farthest mountain, its windows glowing purple in the dusk.
""", [
    C("Fly over with the Dragon Couple", "b2", "cou+1"),
    C("Sneak through the forest with Aaron-y", "b2", "cur+1"),
    D("Disguise Axey in Langston's saucepan helmet", 7),
])

scene("b2", RB, "A song in the fortress", """
The fortress was enormous. Its doors were taller than a hundred trees. But one window, low down, had a crack wide enough for a small axolotl to peek through.

Axey peeked. Aaron-y peeked. Caterpillar Kitty peeked with three of her segments at once.

Inside, the fortress was quiet. No guards. No other giants. No clanking machines. Just a huge, echoing room lit by purple windows, and the sound of one very big creature breathing slowly.

Titanus was not laughing anymore. He was sitting on the floor beside a giant cradle made of stone. The cradle was empty.

And he was humming. A slow, soft tune, the kind you hum to someone small at bedtime. Between the notes he whispered, so quietly that it only shook the window a little: "Little star. Where did you go?"

Axey's walkie-talkie crackled. "Opal," she whispered. "I think the giant is sad."

Back in the meadow, on the other end of the walkie-talkie, Opal was quiet for a long moment. Lolo leaned close to listen too.
""", [
    C("Stay and listen to the whole song", "b3", "fri+1 f:knows_star f:titan_lullaby"),
    C("Count the doors and the guards", "b3", "cur+1 f:counted_doors"),
], art="titanus-scene-lullaby")

scene("b3", RB, "The tiny door", """
Caterpillar Kitty tugged Aaron-y's sleeve and pointed up.

High on the fortress wall, right under the tower where the golden bell hung, was a door. A tiny round door, no bigger than a cookie. A thin golden light shone round its edges, and from inside came a soft tick, tick, tick, like the inside of a clock.

Aaron-y raised his binoculars. Behind the tiny door, gears were turning, big ones and small ones, and right in the middle of them something golden glinted.

"The bell's machinery," breathed Aaron-y. "Everything that makes the bell work is behind that door."

"Too small for anyone," said Axey.

Caterpillar Kitty wiggled all her rainbow segments in a way that clearly meant: not too small for everyone.

Axey shook her head admiringly. "You," she told Caterpillar Kitty, "are the bravest wiggle I know."
""", [
    C("Mark the tiny door on the map", "b4", "cur+1 f:tiny_door"),
    C("Let Caterpillar Kitty peek inside", "b4", "cou+1 f:tiny_door f:bell_crack"),
    C("Leave before Titanus hears you", "b4", "fri+1"),
], echoes=[
    ("counted_doors", "Axey had counted: one enormous front door, one water gate, eleven windows and zero guards. Titanus lived here all by himself."),
], art="titanus-scene-lullaby")

scene("b4", RB, "Home before dark", """
The spy team got home just as the first stars came out. Opal was waiting at the edge of the meadow with Lolo and a blanket for everyone.

Axey told the whole story at once, very fast, bouncing the entire time. Aaron-y told it again slowly, with diagrams.

Finley studied the diagrams very seriously, then added a drawing of a cookie in the corner, for morale. Stella curled up beside Axey, who was so excited she was still bouncing even while lying down.

When they had finished, Lolo was quiet for a moment. "He isn't stomping because he's mean," she said. "He's stomping because he's looking for someone."

Opal nodded slowly. "Then maybe we don't have to beat him. Maybe we have to help him find it. Without giving away our Heart."

Langston crossed his arms. "I still want a formal apology about the tree."
""", [
    C("Hear the report again, slowly", "s11", "fri+1"),
    C("Draw a map of the fortress", "s11", "cur+1 f:fortress_map"),
    D("Let Langston retell it as a movie trailer", 8),
], echoes=[
    ("knows_star", "Opal couldn't stop thinking about the empty cradle, and the giant humming beside it."),
    ("tiny_door", "Caterpillar Kitty kept tapping the tiny door on the map, then tapping her own chest. She wanted that job."),
])

# ───────────────────────── SHARED: Everybody gets a job ─────────────────────────
A2 = "Everybody gets a job"

scene("s11", A2, "Everybody gets a job", """
Opal climbed onto a mushroom so everyone could see her. "Okay. Titanus is enormous. His bell makes things float. And he wants our Heart. So we need a plan where everybody does the thing they're best at."

Hands, paws and one rainbow segment went up all over the meadow.

Unique Pink began crafting glowing ribbons. Snowy practised a snowstorm. Water Kitty and Mermaid Kitty planned a sparkling water path. Vanilla-y and Swirly agreed to build a giant dessert-shaped decoy, then immediately argued about the flavour. Poison Kitty mixed a harmless pretend potion that would make it smell like a giant strawberry. Cinny packed snacks. Evil Queen Kitty insisted on being in charge of the royal distraction.

Onion Ring Kitty, who was so tiny she rode on Cherryberry's shoulder, raised her paw for the smallest job of all.

Langston stared at her. "You? Brave tiny warrior." He saluted. Then he turned to Frosted Kitty. "The Annoyings are ready. Let's go annoy a giant."
""", [
    C("Keep the team small and quick", "s12", "cou+1"),
    C("Give every single friend a job", "s12", "fri+1 f:whole_team"),
], echoes=[
    ("knows_star", "Opal added one more job, just for herself: find out what happened to the little star."),
    ("tiny_door", "Onion Ring Kitty and Caterpillar Kitty were given the tiny door. They shook paws on it, which took a while, because Caterpillar Kitty has a great many paws."),
    ("drawn_carvings", "Finley held up her notebook so everyone could see the waterfall carvings: the giant, the star, the bell."),
    ("fortress_map", "Aaron-y's fortress map was pinned to the mushroom, and everybody crowded round it."),
])

scene("s12", A2, "The empty pedestal", """
Everyone was so busy planning that nobody noticed the meadow had gone quiet.

Then Stella whined. Just once.

Opal turned round.

The little pedestal in the middle of the meadow was empty. The Heart of Stuffy Land was gone. Where it had floated there was only a faint glow, and leading away from it, all the way to the farthest mountain, was a line of enormous purple footprints.

"He took it," Opal whispered. "While we were getting ready."

Langston's fists clenched. For once he didn't make a joke. He just stepped in front of Opal, the way big brothers do, and stared at the mountain as if he could stare it down.

Without the Heart, the colours of Stuffy Land already looked a little paler, like a picture left too long in the sun.

Lolo squeezed Opal's hand. "Then we go and get it back. Together."

There were two ways up to the fortress.
""", [
    C("Ride the sparkling river with Water Kitty and Mermaid Kitty", "c1", "f:route_river"),
    C("Fly with the Dragon Couple", "d1", "f:route_sky"),
    D("Check under the pedestal in case the Heart is hiding", 9),
])

# ───────────────────────── ROUTE C: The sparkling river (3 scenes) ─────────────────────────
RC = "The sparkling river"

scene("c1", RC, "A river that goes uphill", """
Water Kitty touched the meadow fountain and whispered something to it. Mermaid Kitty dived in and swam a loop. The water rose up out of the fountain, curled into a long sparkling ribbon, and began to flow.

Uphill.

All the way up the mountain, toward the fortress.

Unique Pink tied a raft together out of giant leaves and glowing ribbon. Everybody climbed aboard: Opal and Lolo at the front, Langston in his saucepan helmet at the back "for steering," and everybody else squashed in the middle.

"Rivers aren't supposed to do this," said Axey happily.

"Giants aren't supposed to steal hearts," said Opal. "Today is a weird day."

Fish swam past them going uphill too, looking extremely confused. Finley tried to write it all down, but the pages kept getting splashed, so in the end she just wrote WET and underlined it.
""", [
    C("Keep everyone together in the middle of the raft", "c2", "fri+1"),
    C("Paddle faster", "c2", "cou+1"),
], art="titanus-scene-river")

scene("c2", RC, "Something shiny in the water", """
Halfway up, Stella went stiff and pointed her nose straight down at the water. She barked once, which for calm, gentle Stella was practically a shout.

Something was glinting on the riverbed. Something golden.

The river was deep here, quick and full of bubbles. The glint sat right at the bottom, wedged between two smooth stones, flickering every time the water moved.

Mermaid Kitty flicked her tail. "Want me to get it?"

"The fortress is right there," said Langston. "The Heart is in there. We can't stop for every shiny thing."

He wasn't wrong. Up ahead, the fortress windows glowed brighter, and every minute the Heart was gone, the colours of Stuffy Land got a tiny bit paler. Lolo touched Opal's arm. She didn't say what to do. She just waited, the way she always did, so Opal could think.

Opal looked at the glint. It was star-shaped.
""", [
    C("Ask Mermaid Kitty to fetch it", "c3", "cur+1 f:last_fragment"),
    C("Leave it; the Heart matters more", "c3", "cou+1"),
], echoes=[
    ("pieces_collected", "Opal felt the golden pieces in her pocket. The glint in the water was exactly the same colour."),
    ("knows_star", "A star-shaped piece. Opal thought of the little star Titanus had lost."),
], art="titanus-scene-river")

scene("c3", RC, "The front doors", """
The river carried them all the way to the fortress and stopped, politely, at the front doors.

The doors were taller than a hundred trees. The windows glowed purple. At the very top of the tower hung the golden bell, swaying a little in the wind.

Up close, the doors were covered in carvings: stars, little creatures, and a giant with his arms open wide. Most of them had been scratched out, as if someone had been very angry, or very sad, and hadn't wanted to look at them anymore.

Langston looked up at the doors. Then down at his hand. "I'm going to need a bigger knock."

Water Kitty pointed to the side, where the river slipped under the wall through a low stone arch. "There's a water gate," she said. "Quieter. But wetter." "Everything today is wetter," said Finley.
""", [
    C("Knock politely anyway", "s17", "fri+1"),
    C("Slip in through the water gate", "s17", "cur+1"),
], echoes=[
    ("last_fragment", "Mermaid Kitty had brought up the golden piece. It was star-shaped and warm, and it hummed very faintly, as if it knew where it was going."),
])

# ───────────────────────── ROUTE D: Over the clouds (4 scenes) ─────────────────────────
RD = "Over the clouds"

scene("d1", RD, "Dragon wings", """
The Dragon Couple landed in the meadow side by side, as they always did. The purple boy dragon kitty let Opal and Lolo climb on. The dark-blue girl dragon kitty, her light-blue gem shining, took Axey and Langston, who insisted he was "co-pilot."

Nebula Johnny wrapped everyone else in a moon-shield bubble and towed it behind them like a balloon.

Then the dragons spread their wings and leapt.

The meadow fell away. The wind roared. Lolo held on to Opal, and Opal held on to the dragon, and Langston held on to his saucepan helmet and yelled "WHEEEEE" in a very manly way.

Below them, Stuffy Land looked like a patchwork quilt: green meadows, silver lakes, and a long line of glowing purple footprints leading straight to the mountains.
""", [
    C("Fly high above the clouds", "d2", "cur+1"),
    C("Fly low and fast", "d2", "cou+1"),
])

scene("d2", RD, "The crack in the bell", """
The fortress rose out of the clouds, carved right into the mountain. At the very top of its tower hung the golden bell.

Up close, Opal saw something nobody in the meadow could have seen. A long, jagged crack ran down the side of the bell. And golden pieces were missing from its rim, like bites out of a cookie.

"That's why it makes everything float," Opal breathed. "It's broken."

Lolo looked at the missing pieces. "Maybe it didn't break by accident," she said quietly. "Maybe he rang it so hard, for so long, looking for someone, that it cracked."

The girl dragon's gem began to glow. Its light pointed at the base of the bell, where there was a tiny round door, no bigger than a cookie, with a golden glow round its edges.
""", [
    C("Land beside the tiny door", "d3", "cur+1 f:tiny_door"),
    C("Circle the bell to count every crack", "d3", "cur+1 f:bell_crack"),
], art="titanus-scene-bell")

scene("d3", RD, "Purple windows", """
They glided down past the fortress windows. Through the biggest one, Opal could see a huge room with a stone throne.

Titanus was there. He was holding the Heart of Stuffy Land in both his enormous hands, and he was looking at it very carefully. Almost gently. Like someone holding a baby bird.

Then he set it on the arm of his throne and turned toward an empty stone cradle behind him, and his huge shoulders slumped.

"He's not taking it to be powerful," whispered Lolo. "Look at his face."

Opal felt something twist inside her. It was very hard to be cross with someone who looked that sad. It was also very hard to forgive someone who had just stolen your Heart. She decided she could feel both at once.
""", [
    C("Wave, so he knows you're here", "d4", "fri+1"),
    C("Hide behind a cloud and keep watching", "d4", "cur+1"),
    D("Let Langston shout HEY GIANT right now", 10),
], art="titanus-scene-bell")

scene("d4", RD, "Through the roof", """
There was an opening in the roof of the throne room, round and open to the sky. The dragons folded their wings and dropped through it, gentle as falling leaves, and landed on a stone beam high above the floor.

From up here the throne room looked even bigger. Clouds drifted lazily under the ceiling. The Heart of Stuffy Land sat on the arm of the throne like a nightlight, and the empty stone cradle waited in the shadows behind it. Langston adjusted his saucepan helmet and whispered, "I have prepared a speech." "Please don't," whispered Lolo.

Below them, Titanus turned round.

"WHO IS THERE?"

Opal took a deep breath. It was time.
""", [
    C("Climb down quietly", "s17", "cur+1"),
    C("Make a grand entrance", "s17", "cou+1"),
])

# ───────────────────────── SHARED: Titanus's fortress ─────────────────────────
A3 = "Titanus's fortress"

scene("s17", A3, "The throne", """
The throne room was so big that clouds drifted near the ceiling. Titanus sat on a stone throne as tall as a hill, and in his hands, glowing softly, was the Heart of Stuffy Land.

"YOU HAVE COME," he said, "TO WITNESS MY GREATNESS."

Opal stepped forward. Her knees were wobbling, but her voice didn't. "We've come for our Heart."

Titanus laughed, a sound like rocks rolling down a hill. "TINY GIRL. TINY TURTLE. TINY TROLL WITH A POT ON HIS HEAD."

"It's a saucepan," said Langston, "and I'm not tiny. I'm tall for a troll."

Behind her, Lolo held her hand. Coatl stood at her back like a wall. Langston stood beside her, holding his saucepan helmet in front of him like a shield, which it was not.
""", [
    C("Ask him why he really wants it", "s18", "fri+1"),
    C("Tell him to give it back right now", "s18", "cou+1"),
], echoes=[
    ("route_river", "Water dripped from everyone's fur onto the stone floor. The river had brought them right to his door."),
    ("route_sky", "The dragons perched on the beam above, ready to swoop."),
    ("knows_star", "Opal looked past the throne. There it was: the empty stone cradle."),
], art="titanus-scene-throne")

scene("s18", A3, "I have no heart of my own", """
Titanus leaned closer. His purple eyes were enormous, and for a moment they didn't look angry at all.

"BECAUSE I HAVE NO HEART OF MY OWN."

The room went quiet.

He pointed to the dark space behind his throne. "LONG AGO I WAS THE GUARDIAN OF THE LITTLE STAR. IT WAS MY FRIEND. MY LIGHT. MY ONLY COMPANION." His voice grew softer, which for Titanus was still very loud. "THE STAR DISAPPEARED. I SEARCHED FOR CENTURIES. THEN I FOUND YOUR HEART, AND I THOUGHT IT COULD REPLACE MINE."

Lolo stepped forward, small and brave. "But it can't replace your friend."

Opal saw it then, just for a moment. Behind all the stone and crystal and booming, the giant's eyes were wet.

Titanus's eyes flashed. "THEN I WILL TAKE IT ANYWAY!"
""", [
    C("Tell him you're sorry he lost his friend", "s19", "fri+1"),
    C("Look closely at the empty cradle", "s19", "cur+1"),
], echoes=[
    ("asked_why", "\"You said it in the meadow too,\" said Opal. \"Your voice wobbled when I asked you why.\""),
    ("last_fragment", "In Opal's pocket, the star-shaped golden piece grew warm."),
    ("bell_crack", "Opal thought of the long crack down the bell. A bell for calling someone home, she realised. Only broken."),
], art="titanus-scene-throne")

scene("s19", A3, "DOOOOOOOONG!", """
Titanus raised his golden bell.

DOOOOOOOOOONG!

The whole fortress shook. Everyone floated up off the floor, again.

"NOW!" shouted Opal.

The plan began. The Dragon Couple swooped round Titanus's head, too quick to swat. Nebula Johnny threw his moon shield round his friends. Snowy's snowstorm piled up round the giant's feet, and Water Kitty and Mermaid Kitty sent a wave sloshing across the floor.

Spirit Kitty sang, and her song whirled round the giant's ankles. Fire Kitty lit a warm glowing path so nobody would get lost in the snow. Cherryberry shouted directions, Cinny handed out snacks for energy, and Unique Pink's glowing ribbons tied floating friends together so nobody drifted away.

Titanus stumbled. THUUUUUUUM! He crashed into the wall. The Heart wobbled in his fingers.

For one breath, everything hung in the air: friends, snowflakes, Langston's cape, and a very surprised Turtle Kitty.
""", [
    C("Hold on tight to Coatl's shell", "s20", "fri+1"),
    C("Swim through the air toward the throne", "s20", "cou+1"),
    D("Try to ride the bell rope", 11),
], echoes=[
    ("moon_shield", "Nebula Johnny's shield was faster this time. He had practised in the meadow."),
    ("friend_chain", "Everyone grabbed a paw without even being asked. The friendship chain was back."),
])

scene("s20", A3, "One chance", """
Everyone was shouting ideas at once. Langston wanted to try something annoying. Aaron-y wanted to try something sneaky. Lolo, very quietly, wanted to try something kind.

Titanus was getting up. The bell was swinging. There was time for one plan, and only one.

Opal looked round at all of them: Coatl, steady as a mountain; Langston, ready to be ridiculous; Lolo, holding her hand; Axey, bouncing even while floating. Every plan they had made in the meadow was here in this room, waiting.

She thought about everything they had found on the way. Some plans were only possible because of what they had discovered. Some weren't possible at all.

Everybody looked at Opal.
""", [
    C("Bring the little star home", "e1", "", needs=("f:knows_star|Learn what Titanus lost first.",
                                                   "f:last_fragment|Find the star-shaped golden piece.")),
    C("Send the tiny team to the bell", "h1", "", needs=("f:tiny_door|Find the tiny door into the bell.",)),
    C("Let The Annoyings handle it", "x1", ""),
    D("Ask Titanus for a time-out", 12),
], echoes=[
    ("knows_star", "Opal thought about the empty cradle, and the little star, and what a giant might do if he got his best friend back."),
    ("tiny_door", "Onion Ring Kitty was already nibbling a crumb off her own edge, getting ready to shrink."),
])

# ───────────────────────── ENDGAME: The little star (4 scenes + choice) ─────────────────────────
AE = "The little star"

scene("e1", AE, "The cradle", """
Opal ran for the empty cradle.

Titanus saw her. "DO NOT TOUCH THAT!" One enormous hand swept down.

Coatl stepped in front of her. Every button under his shell blazed gold, and a wall of warm light rose between them. The giant's hand stopped against it. It pushed. The light held.

Coatl didn't say a word. He never did, when it mattered. He just dug his feet into the stone floor and held on, and his buttons grew brighter and brighter, the way a lighthouse shines brightest when the storm is worst.

"Thank you, Coatl!" Opal gasped, and slid the last few steps on her knees.

Behind her, Langston had planted himself beside Coatl with both arms up, helping push against the wall of light. It didn't help much. But it helped Coatl feel less alone, and that helped a lot.
""", [
    C("Trust Coatl to hold on", "e2", "fri+1"),
    C("Run faster than you've ever run", "e2", "cou+1"),
])

scene("e2", AE, "The golden piece", """
The cradle was cold stone, carved with tiny stars. In the middle was a little notch, exactly the shape of a star.

Opal took out the golden piece and pressed it in. It fitted perfectly. Click.

Nothing happened.

She turned it. Nothing. She tapped it. Nothing.

Opal's heart sank. She had been so sure. The golden piece sat in its notch, perfectly fitted and perfectly still, like a key in a door that didn't want to open.

Titanus had stopped pushing against Coatl's wall. He was watching her, very still.

"IT IS NO USE," he rumbled, but softly. "I HAVE TRIED EVERYTHING. FOR A THOUSAND YEARS." Axey floated down beside the cradle and put both paws on its rim. "Have you tried everything with friends?" she asked.
""", [
    C("Ask Lolo what the old message meant", "e3", "fri+1"),
    C("Think about the carving's words again", "e3", "cur+1"),
], echoes=[
    ("drawn_carvings", "Finley held up her notebook, open at the drawing of the waterfall carvings."),
])

scene("e3", AE, "The brightest heart", """
"When the little lights disappear," said Lolo softly, "the giant will seek the brightest heart."

Opal looked at the Heart of Stuffy Land, glowing in Titanus's hand. Then at the empty cradle. Then at all her friends, floating and holding on to each other.

"Maybe," she said slowly, "the star doesn't need a new heart. Maybe it needs all of us."

She looked up at the giant. "Titanus. Please. Bring the Heart to the cradle. Just for a moment. I promise we're trying to help."

For a long time, the giant didn't move.

Opal could hear her own heart thumping. She could hear Lolo breathing beside her. Somewhere behind her, Stella gave one small, hopeful wag. Titanus looked at the Heart in his hand, then at the cradle, then at the girl standing in front of it, who wasn't running away.
""", [
    C("Ask him again, gently", "e4", "fri+1"),
    C("Ask the Dragon Couple to carry the Heart down", "e4", "cou+1"),
])

scene("e4", AE, "Everybody, bring your light!", """
Slowly, very slowly, Titanus lowered the Heart until it hovered above the cradle. His hand was shaking.

Opal turned to her friends. "Everybody! Bring your light!"

They came. Cherryberry and Cinny. The Dragon Couple, glowing purple and blue. Aaron-y and Aphmau-y, holding paws. Unique Pink with her ribbons and Caterpillar Kitty with every rainbow segment shining. Water Kitty, Fire Kitty, Snowy and Mermaid Kitty. Nebula Johnny and Spirit Kitty. Vanilla-y and Swirly, who agreed to stop arguing for one whole minute. Turtle Kitty peeked out of her shell. Evil Queen Kitty raised her tiara. Onion Ring Kitty stood right at the front. Finley and Stella sat beside Coatl, and Axey bounced into the circle.

Lolo held Opal's hand. Opal's gemstone began to glow.

And Langston raised both arms.
""", [
    C("Call every last friend into the circle", "decide_circle", "fri+1"),
    C("Ask your closest friends to hold on tight", "decide_circle", "cur+1"),
], echoes=[
    ("whole_team", "Because every single friend had a job, every single friend was here. Nobody was missing from the circle."),
], art="titanus-scene-star")

scene("decide_circle", "Your call, Opal", "The biggest cheer", """
The Heart glowed brighter. The golden piece in the cradle began to hum. Something was trying to wake up.

Langston took a breath so big his saucepan helmet slid over his eyes. Lolo squeezed Opal's hand. Titanus held perfectly still.

There was just enough light. Opal had to decide how to use it.

Some friends were glowing bright. Some were glowing faintly. It would take everyone, all at once, to wake the star up properly. Or Opal could use the light she was surest of: her own, Lolo's and Coatl's.
""", [
    C("Ask everyone for the biggest trolly cheer in history", "final_1", "",
      needs=("f:whole_team|Give every friend a job when you make the plan.", "fri4", "cur3")),
    C("Light the cradle with Lolo and Coatl", "final_2", ""),
], art="titanus-scene-star")

# ───────────────────────── ENDGAME: The tiny team (3 scenes + choice) ─────────────────────────
AH = "The tiny team"

scene("h1", AH, "Crumb-sized", """
Onion Ring Kitty took one nibble of herself. Then another. With every nibble she got smaller, until she was crumb-sized: a brave little speck with whiskers.

Caterpillar Kitty wiggled up the wall beside her, and together they slipped through the tiny round door into the bell.

Inside was a world of enormous golden gears, ticking and turning. Right in the middle, glowing, was a small golden lever.

Every tick of the gears made the whole bell hum. Onion Ring Kitty's whiskers buzzed. Caterpillar Kitty's segments tingled one colour at a time: red, then orange, then yellow, all the way down to purple.

"We're in," said Caterpillar Kitty's voice over Aaron-y's walkie-talkie.

Out in the throne room, Opal pressed the walkie-talkie to her ear and held her breath.
""", [
    C("Guide them over the walkie-talkie", "h2", "cur+1 f:titan_crumb"),
    C("Cheer them on as loud as you can", "h2", "fri+1 f:titan_crumb"),
], art="titanus-scene-lever")

scene("h2", AH, "The golden lever", """
Onion Ring Kitty grabbed the lever and tugged.

Nothing.

She tugged harder. Still nothing.

Caterpillar Kitty wrapped her rainbow segments round it, every colour pulling at once. The lever creaked. It shivered. It did not move.

"It's stuck!" squeaked Onion Ring Kitty. "It's really, really stuck!" Caterpillar Kitty squeezed out a blob of sticky goo for a better grip, and Onion Ring Kitty braced her crumb-sized feet against a gear and pulled until her whiskers stood straight out.

Outside, Titanus was getting up. He hadn't noticed the tiny team yet. But he would.

Opal gripped the walkie-talkie. She had to help them, and she couldn't even fit through the door. But she could think.
""", [
    C("Tell them to pull together on the count of three", "h3", "cou+1"),
    C("Look for something else holding it stuck", "h3", "cur+1"),
], echoes=[
    ("bell_crack", "\"The crack!\" Opal said into the walkie-talkie. \"There's a crack in the bell. Is something caught in it?\" There was: a golden chip, wedged right against the lever."),
], art="titanus-scene-lever")

scene("h3", AH, "CLICK!", """
CLICK!

The lever moved. The bell's glow flickered. Everyone who had been floating dropped a little bit, then a little bit more.

Aaron-y spotted the change at once. "Aphmau-y! The control panel!" They raced to a panel in the wall, and Unique Pink's glowing ribbons wrapped round the loose wires to hold them still.

Titanus noticed. "WHO DARES TOUCH MY BELL?"

Evil Queen Kitty climbed onto a broken piece of throne. "ATTENTION, TITANUS! YOU ARE HEREBY ORDERED TO STOP BEING SO ENORMOUSLY RUDE!"

"WHO DARES?"

"I DO!" He reached toward her, and she ducked behind Coatl. "ROYAL STRATEGIC RETREAT!"
""", [
    C("Hold the bell switched off", "decide_heist", "cou+1"),
    C("Turn the bell down softly instead", "decide_heist", "cur+1"),
])

scene("decide_heist", "Your call, Opal", "The lever", """
The bell was half asleep now. Titanus was standing in the middle of his throne room, staring at it, with the Heart still in his hand.

Inside the bell, Onion Ring Kitty and Caterpillar Kitty were holding the lever with everything they had. "We can hold it," Onion Ring Kitty squeaked over the walkie-talkie. "For a little while."

What should they do with that little while?

Opal looked up at the giant. He wasn't stomping. He wasn't shouting. For the first time all day, he was just standing still, listening to his bell go quiet.
""", [
    C("Hold the lever while Opal talks to Titanus", "final_3", "", needs=("cou4", "cur3")),
    C("Yank the lever all the way down", "final_4", ""),
])

# ───────────────────────── ENDGAME: The Annoyings (3 scenes + choice) ─────────────────────────
AX = "The Annoyings"

scene("x1", AX, "HEY, GIANT!", """
Langston and Frosted Kitty raced toward the throne.

"HEY, GIANT!" Langston yelled, his saucepan helmet back on his head. "YOU HAVE SOMETHING ON YOUR SHIRT!"

Titanus looked down.

Frosted Kitty hurled the giant donut decoy as hard as she could. It sailed through the air and landed, SPLOT, right on Titanus's shoulder.

Titanus blinked at it. "What is this?"

"IT'S A DONUT OF DISTRACTION!" shouted Langston.

Titanus touched the donut very carefully with one enormous finger. It was squishy. It had sprinkles. Some of the sprinkles fell into his ear. "WHY," he said slowly, "IS THERE A DONUT?" "THAT," said Frosted Kitty, "IS EXACTLY WHAT WE WANT YOU TO WONDER."

Behind his back, Evil Queen Kitty was climbing onto a broken piece of throne with her purple cape flapping, and every Aphmau kitty in the room was getting ready for the next part of the plan.
""", [
    C("Keep the donuts coming", "x2", "cou+1 f:titan_donut"),
    C("Start the royal speech with Evil Queen Kitty", "x2", "fri+1 f:titan_donut"),
], art="titanus-scene-donut")

scene("x2", AX, "The dessert decoy", """
Vanilla-y and Swirly rolled in their giant dessert decoy. It smelled exactly like an enormous strawberry, thanks to Poison Kitty's harmless pretend potion. Titanus sniffed. He couldn't help it.

C danced across the floor, her two bows sparkling, and the giant's eyes went swirly watching her. Jellyfish Kitty bounced up and plopped a wobbly jellyfish right on top of his crystal crown.

Titanus's mouth twitched.

"Is he...?" whispered Axey.

"I think," said Lolo, "he's trying not to laugh."

Langston, who believed very strongly that laughing was the most powerful magic in Stuffy Land, cupped his hands round his mouth. "KNOCK KNOCK!" he bellowed.
""", [
    C("Make him laugh properly", "x3", "fri+1"),
    C("Ask Snowy to get ready, just in case", "x3", "cou+1"),
], art="titanus-scene-donut")

scene("x3", AX, "The wobble", """
"WHO'S THERE?" rumbled Titanus, before he could stop himself.

"Interrupting troll!"

"INTERRUPTING TR..."

"HELLOOOOO!" yelled Langston.

Titanus's shoulders began to shake. His crown wobbled. The jellyfish wobbled. The donut wobbled.

"HO," said Titanus. "HO. HO HO."

It was the biggest, rumbliest, most surprised laugh in the history of Stuffy Land, and it shook dust from the ceiling. And as he laughed, his fingers loosened round the Heart.

It began to slip.

Opal saw it. Coatl saw it. Every single friend in the throne room saw it, and every single one of them moved at once.
""", [
    C("Catch the Heart with Coatl", "decide_distraction", "fri+1"),
    C("Ask him what's so funny", "decide_distraction", "cur+1"),
])

scene("decide_distraction", "Your call, Opal", "While he's laughing", """
The Heart dropped, and Coatl caught it on his shell with a soft bonk. Safe.

Titanus didn't even reach for it. He was too busy laughing, wiping his eyes and laughing again. When he finally caught his breath, he looked almost embarrassed. "I HAVE NOT LAUGHED," he said, "IN A VERY LONG TIME."

Titanus wiped his eyes with a finger the size of a log. He was still giggling. Snowy was waiting in the corner, paws ready. Langston was holding a fresh donut.

Opal had one chance to decide how this ended.
""", [
    C("Offer Titanus a snack and a seat", "final_5", "", needs=("fri3",)),
    C("Ask Snowy to build an igloo round him", "final_6", "", needs=("cou3",)),
    C("Grab the Heart and run for home", "final_7", ""),
])

# ───────────────────────── Endings ─────────────────────────

ending(1, "The Biggest New Friend", """
"EVERYBODY GIVE THE BIGGEST TROLLY CHEER YOU HAVE!" Langston shouted.

Everyone cheered. The Heart blazed. Opal's gemstone gathered all their light into one warm golden beam and poured it into the cradle. The golden piece rose into the air, and a tiny star appeared. Then another. Then hundreds, swirling together until they were one little star again.

It had been hiding inside the Heart of Stuffy Land all along, waiting for someone to bring it back together.

The little star floated up and landed on Titanus's hand. For the first time, the giant smiled. A single golden tear rolled down his cheek and landed with a splash, like a little pond.

"That's a big tear," said Langston.

"Some feelings are big," said Opal.

"I AM SORRY," said Titanus. His dark armour softened to warm golden stone, and his bell went quiet. He set the Heart back on its pedestal himself, very carefully. "A heart becomes stronger when it is shared."

That night there was a giant-sized party. Titanus tried Langston's obstacle course and got two fingers stuck in the tiny tunnel. POP! The tunnel landed on Langston's head. "THE TUNNEL HAS CHOSEN ME." Titanus laughed so hard the clouds wiggled, and the little star sparkled brighter with every laugh.

"Even the biggest creature in the world needs friends," said Titanus.

"And snacks," said Langston.

"AND SNACKS."
""", teaser="""
Much later, as the little star settled beside Titanus's shoulder, something even bigger moved far beyond the mountains. A gigantic shadow. A second bell. And a voice that whispered, "TITANUS HAS FOUND HIS STAR. NOW I SHALL FIND MINE."

But that was an adventure for another day.
""")

ending(2, "A Star for Two", """
Opal held one of Lolo's paws and put her other hand on Coatl's shell. Coatl's buttons glowed. Opal's gemstone glowed. Their light poured into the cradle together.

A tiny star blinked awake. Just one, small and faint, like a candle in a big dark room. It drifted up and landed on Titanus's fingertip, and the giant went completely still.

"MY STAR," he whispered. "IT IS SO SMALL."

"It's been waiting a long time," said Lolo. "It needs more light to grow."

Titanus put the Heart back in Opal's arms, very gently. Then he made a promise: every evening he would carry the little star to the edge of the meadow, and anyone who wanted to could come and share a little of their light with it.

On the first night, three friends came. On the second, eleven. Langston brought snacks. The star is still small, but it is growing, and the giant has stopped stomping.
""")

ending(3, "The Quiet Bell", """
Onion Ring Kitty and Caterpillar Kitty held the lever. The bell went silent. Every floating friend drifted gently down to the floor.

In the quiet, Opal walked right up to Titanus's enormous foot and looked up. "You can't take something that belongs to everyone just because you miss something," she said. "But we'll help you look for your star. Properly. Together."

The giant looked down at her for a long time. Without his bell ringing, he looked less like a monster and more like someone who was very, very tired. Slowly, he knelt and placed the Heart in her arms.

"TOGETHER," he said, as if he was trying out a new word.

The bell is quiet now, and Onion Ring Kitty has been promoted to Official Bell Keeper. The little star is still lost somewhere. But tomorrow there will be a search party, and for the first time in centuries, Titanus won't be searching alone.
""")

ending(4, "The Upside-Down Fortress", """
"PULL!" Onion Ring Kitty and Caterpillar Kitty yanked the lever all the way down.

The bell gave a strange, wobbly BWOOOONG, and gravity in the fortress flipped completely over.

Everyone fell up. Titanus fell up. The donuts fell up. They all landed on the ceiling, which was now the floor, and the Heart rolled straight into Coatl's arms, because Coatl always knows where things are going to land.

Titanus sat on his upside-down ceiling, looking embarrassed and confused. Then he grabbed his bell, climbed out of a window, and stomped away over the mountains without saying goodbye.

The Heart is back on its pedestal, and Stuffy Land is safe. But somewhere beyond the mountains is a lonely giant with a broken bell, still looking for his star. Opal hasn't stopped thinking about him.
""")

ending(5, "The Snack Truce", """
"Titanus," said Opal, "would you like a snack?"

The giant stopped laughing and stared at her. "A... SNACK?"

Cinny rolled out her cinnamon rolls. Cookie brought cookies. Snow Cone Kitty set up her snow-cone stand. Titanus sat down very carefully on the floor of his own throne room, and Langston handed him a donut the size of a tyre.

He took one bite. Then he told them, slowly, about the little star he used to guard, and how it vanished, and how he had looked for it for longer than anyone could remember.

Nobody fixed it that night. The star is still lost. But Titanus has agreed to a Snack Truce, which Langston wrote on a napkin and everyone signed, and the giant now visits the meadow for snacks every Saturday. Lolo says that's how friendships start. Langston says it's how snack empires start.
""")

ending(6, "An Igloo for a Giant", """
"Snowy, now!"

Snowy waved her paws, and a snowstorm swirled round the giant until, with a soft crunch, he was sitting inside an enormous igloo with one round window. Snowy's igloos are impossible for villains to get out of. It was cosy in there, but Titanus couldn't leave.

Coatl carried the Heart home, and Stuffy Land's colours came back bright.

But Opal kept looking over her shoulder at the little round window, where two purple eyes were watching them go.

The next morning she went back with Lolo, a blanket and a thermos of hot cocoa. She sat down outside the window. "When you're ready to talk," she said, "we'll be here." Titanus hasn't said anything yet. But last night, for the first time, he said "thank you" for the cocoa.
""")

ending(7, "Everybody Floats", """
Coatl tucked the Heart under his shell and ran for the door. Everyone ran after him.

Titanus wiped his eyes and rang his bell one last time. DOOOOOOOOONG!

Everybody floated up, out of the window, and drifted all the way home inside Nebula Johnny's moon shield, like a bubble full of friends. Water Kitty's river carried them gently down to the meadow. The Heart went back on its pedestal, safe.

But the bell's ring had gone into everything. Now the pillows in Stuffy Land float up to the ceiling every night, and Langston has to eat his breakfast upside down, which he says is "the correct way anyway."

Far away in his fortress, Titanus still rings his bell sometimes, looking for his star. Opal can hear it on quiet nights. One day, she's going to go back and find out why.
""")

# ───────────────────────── Detours ─────────────────────────

detour(1, "Pancake Rescue", """
You throw a pancake up to Langston. He catches it in his mouth. You throw another. He catches that too. Soon he is still upside down, but he is very full. "This is going great," he says. Maybe try something that actually gets him down.
""")
detour(2, "Breakfast Bunker", """
You hide under the breakfast table with Lolo. It is cosy. It has syrup. It does not stop the ground from shaking, and Finley has just found you and written HIDING in her notebook. Better go and see what's coming.
""")
detour(3, "Ding Dong", """
"Can I ring your bell?" asks Langston. Before anyone can stop him, he jumps for the rope. DONG. He floats gently up into a marshmallow cloud and sticks there. "I regret nothing," says the cloud. Try a different question.
""")
detour(4, "Flap Harder", """
You flap your arms like a bird. You float upside down. Lolo floats past you, also upside down, looking at you very patiently. Flapping is not a plan. Try something that keeps everyone together.
""")
detour(5, "Not a Cookie", """
Stella gives the golden piece a careful lick, then looks at Finley with great disappointment. Finley writes NOT A COOKIE in her notebook for the second time and underlines it. The trail is getting cold. Try another way.
""")
detour(6, "Echo, Echo", """
"HELLO!" you shout. "HELLO, HELLO, HELLO!" says the cave. Then the waterfall says it too, and it is so loud that everyone gets splashed and Langston's helmet fills with water. Everyone is fine, but very damp. Try something quieter.
""")
detour(7, "Clang", """
Axey puts on Langston's saucepan helmet as a disguise. It covers her whole body. She looks like a saucepan with legs. Every step goes CLANG. Even Titanus, very far away, says "WHAT WAS THAT?" Try a sneakier disguise. Or no disguise.
""")
detour(8, "Coming Soon", """
"IN A WORLD," says Langston in a deep voice, "WHERE ONE GIANT... HAS ONE BELL..." The trailer takes eleven minutes and includes three dramatic slow-motion runs. Nobody learns anything new. Hear the real report instead.
""")
detour(9, "Snail Surprise", """
You check under the pedestal. The Heart is not there. A very small snail is there, and it would like you to know that it was having a nap. Sorry, snail. The footprints are still leading away. Try another way.
""")
detour(10, "Too Soon", """
"HEY, GIANT!" yells Langston, from the dragon's back, before the plan is ready. The dragons get such a fright they do three loop-the-loops, and all the mission snacks fall into a cloud. Everyone is safe, but hungry. Try waiting for the right moment.
""")
detour(11, "Bell Ringer", """
You grab the bell rope. DONG. You float up. DONG. You float down. DONG. You are now a very small, very confused part of the bell. Lolo gently pulls you back. Try something that helps the plan.
""")
detour(12, "Time-Out", """
"Can we have a time-out?" asks Opal. To everyone's surprise, Titanus says, "VERY WELL," and sits down on a mountain for exactly one minute. Then he stands up and rings the bell again. Time-outs only work once. Pick a real plan.
""")


def main():
    book = {
        "id": "stuffy-titanus",
        "contentVersion": 1,
        "title": "Opal and TITANUS: The Biggest Bad Guy Stuffy Land Had Ever Seen",
        "subtitle": smart("A giant with a gravity bell wants the Heart of Stuffy Land. Find out why before everything floats away."),
        "start": "s01",
        "minimumDecisions": 22,
        "nodes": nodes,
    }
    OUT.write_text(json.dumps(book, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    plan = {
        "story": "stuffy-titanus",
        "status": "pending",
        "note": ("Planned illustrations. The scenes already reference these asset names; the app shows its drawn "
                 "storybook placeholder until each image is added to StuffyLand/Assets.xcassets as "
                 "<asset>.imageset/<asset>.jpg (1200x720 for scenes)."),
        "style": STYLE,
        "cover": COVER,
        "scenes": [{"asset": k, "scene": v["scenes"], "alt": v["alt"], "prompt": v["prompt"],
                    "usedBy": [n["id"] for n in nodes if n.get("illustration", {}).get("asset") == k]}
                   for k, v in ART.items()],
    }
    PLAN.write_text(json.dumps(plan, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT.relative_to(ROOT)} ({len(nodes)} nodes) and {PLAN.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
