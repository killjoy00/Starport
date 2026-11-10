#!/usr/bin/env python3
"""Build the data-only Stuffy Land collection from checked-in editorial sources."""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EDITORIAL = ROOT / 'StuffyLand/Editorial'
CONTENT = ROOT / 'StuffyLand/Content'


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def paragraphs(text):
    return [p.strip() for p in text.strip().split('\n\n') if p.strip()]


def req(flag, hint):
    return {'flag': flag, 'hint': hint}


def choice(id, label, to, stat=None, flag=None, requirements=None):
    result = {'id': id, 'label': label, 'to': to}
    effects = []
    if stat:
        effects.append({'stat': stat, 'delta': 1})
    if flag:
        effects.append({'flag': flag})
    if effects:
        result['effects'] = effects
    if requirements:
        result['requirements'] = requirements
    return result


def adventure(filename, title, subtitle, art, stages, branches, detours, endings, echoes):
    nodes = []
    for i, (heading, text, first, second) in enumerate(stages):
        nodeid = f's{i+1:02}'
        nxt = f's{i+2:02}' if i+1 < len(stages) else 'resolution'
        n = {'id': nodeid, 'act': 'An Opal adventure', 'title': heading, 'paragraphs': paragraphs(text),
             'illustration': {'asset': art, 'alt': 'Opal and Lolo inside their warm purple galaxy tent.' if art == 'stuffy-tent' else 'Opal, Lolo, and Langston face the purple, mustached Duke beside his trumpet machine.'}}
        n['choices'] = []
        for j, (label, stat, flag) in enumerate([first, second]):
            target = f'{nodeid}_{j+1}' if i in branches else nxt
            n['choices'].append(choice(f'{nodeid}_choose_{j+1}', label, target, stat, flag))
            if i in branches:
                bh, bt, a, b = branches[i][j]
                nodes.append({'id': target, 'act': 'Your plan unfolds', 'title': bh, 'paragraphs': paragraphs(bt),
                              'illustration': n['illustration'], 'choices': [
                                  choice(f'{target}_continue', a, nxt, 'trust'),
                                  choice(f'{target}_notice', b, nxt, 'clues')]})
        if i < len(detours):
            dh, dt, dl = detours[i]
            target = f'detour_{i+1}'
            n['choices'].append(choice(f'{nodeid}_detour', dl, target))
            nodes.append({'id': target, 'act': 'A little detour', 'title': dh, 'paragraphs': paragraphs(dt),
                          'ending': {'id': target, 'kind': 'detour', 'title': dh,
                                     'note': 'Everyone is safe. Try another way from the last choice.'}})
        if nodeid in echoes:
            n['conditionalParagraphs'] = [{'requirement': req(f, 'A clue from your earlier plan.'), 'text': t}
                                           for f, t in echoes[nodeid]]
        nodes.append(n)
    nodes.append({'id': 'resolution', 'act': 'The last choice', 'title': 'What will you carry home?',
                  'paragraphs': [subtitle, 'Opal looks at the friends beside her. The discoveries and promises you made have opened different ways to finish.'],
                  'choices': [choice(f'finish_{i+1}', e[0], f'final_{i+1}', requirements=e[3])
                              for i, e in enumerate(endings)]})
    for i, (label, heading, text, requirements) in enumerate(endings):
        nodes.append({'id': f'final_{i+1}', 'act': 'A Stuffy Land memory', 'title': heading,
                      'paragraphs': paragraphs(text) + ['The End.'],
                      'ending': {'id': f'final_{i+1}', 'kind': 'final', 'rank': i+1,
                                 'title': heading, 'note': 'This ending is saved in your memory book. You can return to the story and discover another way.'}})
    book = {'id': 'stuffy-' + filename.replace('_', '-'), 'contentVersion': 1, 'title': title,
            'subtitle': subtitle, 'start': 's01', 'minimumDecisions': len(stages) + len(branches) + 1, 'nodes': nodes}
    write(CONTENT / (filename + '.json'), book)
    return book


pillow_stages = [
('An adventure delivered', '''The galaxy tent paints stars across Opal's blanket, but her head feels heavy and her nose is sniffly. Lolo, her gray-and-tan sloth lovey, tucks herself beside her.

“I wanted an adventure,” Opal says.

Langston bursts in, notices her tissues, and lowers his voice to a very loud whisper. “THE ADVENTURE DELIVERY SERVICE IS OPEN!”

You help Opal decide how to lead from her resting place. On every route, she stays tucked up and her friends do the exploring.''', ('Ask Lolo to help make a cozy plan', 'trust', 'rest_plan'), ('Ask Langston to gather the adventure crew', 'power', 'crew_call')),
('Build the resting castle', '''Axey brings his explorer bag. Finley arrives with her notebook, and Stella drags a blanket almost as big as she is. Coatl carries smooth stones for the corners.

Langston drops an enormous pillow. FWOOOMP.

“Important equipment,” he announces. The friends begin building Opal's Royal Resting Castle. Where should the first team work?''', ('Have Coatl steady a little cushion tower', 'clues', 'steady_tower'), ('Ask Unique Pink to make a blanket doorway', 'trust', 'ribbon_door')),
('The golden map', '''Cherryberry arrives with the kitty friends. Unique Pink brings a crown; Cinny brings a cinnamon-roll pillow. Inside the fort, a golden spark unfolds into a map.

THE LOST STAR OF STUFFY LAND.

The star on the map shifts when Axey walks past it. Opal leans forward, then settles back when Lolo offers her water.

“We can investigate from here,” Lolo says.''', ('Study how the star moves on the map', 'clues', 'map_rule'), ('Ask Finley to inspect the tracks around the fort', 'clues', 'paw_clue')),
('A commander needs a crew', '''Axey raises his paw. “I volunteer for exploring!”

Finley opens her notebook. Stella tests a cushion by lying on it. Coatl waits beside the tower, solid as a small hill.

Opal can send the first search party in two directions. Neither requires her to leave the blankets.''', ('Send Axey through the cushion tunnel', 'power', 'tunnel_team'), ('Send Finley and Stella around the blanket edge', 'trust', 'blanket_team')),
('The places not searched', '''The search party returns. The star on the map has slipped away again.

“It keeps moving whenever we look somewhere,” Opal says. “Maybe it shows where the star isn't.”

Langston arrives with mission cookies. “I have searched these extremely thoroughly.”

Lolo points out the only part of the fort that nobody has inspected: the high pillow tower.''', ('Compare the search notes with the map', 'clues', 'compared_map'), ('Ask Coatl to check the tower from below', 'power', 'tower_checked')),
('The tower wobbles', '''A gold sparkle peeks from the top cushion. Langston reaches toward it and the tower leans.

“Careful!” Opal calls.

He slides gently into a blanket pile. His pumpkin helmet rolls away. “I have discovered a very comfortable landing.”

Opal waits while he gets up, then plans a steadier way to reach the light.''', ('Plan a small explorer climb with Coatl holding the base', 'power', 'small_climb'), ('Ask Unique Pink to make a soft ribbon sling', 'clues', 'ribbon_sling')),
('Check every corner', '''Before anyone climbs, Finley checks the floor. Stella pushes the loose helmet out of the way. Coatl examines the seams between the cushions.

Lolo notices Opal rubbing her eyes. “We can take a little pause.”

The star is still there. The friends can make the next step ready while their commander rests.''', ('Rest while Cinny double-checks the team plan', 'trust', 'shared_plan'), ('Ask Lolo to read the next instructions aloud', 'clues', 'lolo_reader')),
('Bring down the star', '''The safe route is ready. Axey waits at the bottom of the tower and Unique Pink holds her ribbons.

“Small paws,” Opal says. “Slow movements.”

Langston salutes so carefully that he barely rustles the blanket roof. There is more than one way to get the star down without knocking over the fort.''', ('Send Axey up the supported cushion steps', 'power', 'axey_retrieval'), ('Have the ribbon team lower the star gently', 'trust', 'sling_retrieval')),
('A message in the light', '''The star arrives on a cushion beside Opal. Gold spreads across the fort, revealing a new message.

THE STAR SHINES BRIGHTEST WHEN EVERYONE SHARES ITS LIGHT.

Opal touches one point. It glows, but the rest stays dim. Lolo studies the message with her.

“What might sharing mean?” she asks.''', ('Invite every friend to lend a paw', 'trust', 'share_star'), ('Look for the constellation pattern on the map', 'clues', 'star_pattern')),
('Make room for everyone', '''The smallest kitty waits behind the larger cushions. The Dragon Couple stay together beside the entrance. Finley and Stella sit side by side.

“We can move closer to Opal,” Lolo suggests, “instead of asking Opal to move to us.”

Langston lifts one enormous cushion and suddenly there is room.''', ('Bring the whole circle to Opal’s bedside', 'trust', 'whole_circle'), ('Pass the star around on its soft cushion', 'power', 'star_pass')),
('The quiet part', '''The star shines warmly. Opal smiles, then yawns. Lolo draws the blanket up around her shoulders.

Langston sees a tiny golden cookie appear above his helmet. “THE STAR UNDERSTANDS ME!”

He catches Lolo's look and finishes the sentence in a whisper. Opal can decide what to do with the last of her energy.''', ('Let the crew finish while Opal rests', 'trust', 'rest_finish'), ('Ask Lolo to help explain the final pattern', 'clues', 'pattern_finish')),
('Choose a light to keep', '''The search is finished. The fort is steady, and the star is safe beside Opal's pillow. What happens next depends on how the friends have prepared to share it.

“You were our commander the whole time,” Axey whispers.

“Even when I needed a pause?”

“Especially then,” Lolo says.''', ('Gather the crew for a quiet thank-you', 'trust', 'crew_thanks'), ('Ask Finley to record the adventure in her notebook', 'clues', 'recorded')),
]
pillow_branches = {
2: [('The moving star', 'Opal asks Axey to walk around one cushion at a time. Each time he searches, the map slides its star elsewhere. Lolo holds the map where Opal can see it without sitting up. They have discovered a rule, not a broken map.', 'Mark the searched cushions for everyone', 'Ask how the rule points to an unsearched place'), ('The paw-print puzzle', 'Finley follows small prints under a hanging blanket. Stella finds a golden thread caught on the seam. Their clue leads upward, away from the floor. Opal keeps the thread where she can compare it with the map later.', 'Thank both detectives for their clue', 'Examine where the golden thread came from')],
3: [('Axey’s tiny expedition', 'Axey crawls into the tunnel with a ribbon tied loosely to his pack. Lolo holds the other end so he can find the entrance again. Inside, a sparkle on the ceiling shows that the tunnel passes beneath the high tower.', 'Let Lolo guide her best friend back', 'Have Axey sketch the ceiling sparkle'), ('The blanket-edge patrol', 'Finley and Stella walk the outside edge together. Behind a fold, they find an old star-shaped stitch that points toward the tower. Stella stays beside the fold while Finley brings the observation back to Opal.', 'Keep the two detectives working together', 'Compare the stitch with the tower’s position')],
5: [('The smallest climber', 'Coatl braces the tower. Axey tests the first cushion, then the second. Opal makes him stop whenever anything wobbles. Langston holds the loose blankets out of the way, giving his height a useful job.', 'Check that everyone knows their role', 'Ask Axey to test each next foothold'), ('A sling made of ribbons', 'Unique Pink knots wide ribbons around a soft cushion. Langston lifts one end while Coatl anchors the other. The sling can reach behind the top pillow without anyone climbing. Opal checks the knot from her blanket.', 'Let the crafters explain the knot together', 'Follow the ribbon’s route before lifting')],
7: [('Explorer above the pillows', 'Axey climbs slowly with Coatl steadying the base. At the top he finds a golden star caught behind a seam. He frees it with two careful paws and carries it back down. Langston provides a triumphant whisper.', 'Have Axey place it beside Opal', 'Ask which seam held the star'), ('The softest delivery', 'The ribbon sling rises beside the sparkle. Unique Pink tips it just enough to lift the star, then the team lowers it toward Opal. Langston tries to announce a delivery fee of one biscuit. Lolo raises an eyebrow.', 'Thank every friend holding the ribbons', 'Examine the star while it settles')]
}
pillow_detours = [
('The loud whisper', 'Langston demonstrates his quietest announcement. The fort roof flutters. Opal giggles, then asks for a truly quiet start. Lolo waits while everybody practices indoor voices.', 'Ask for Langston’s loudest delivery announcement'),
('The enormous entrance', 'Langston builds a doorway exactly his size. There are no pillows left for walls. Coatl looks at the empty basket. The friends will need a smaller design.', 'Use every cushion to make a troll-sized doorway'),
('The cookie map', 'Langston traces the star with cookie crumbs. Finley politely eats one and the map is no easier to understand. Opal decides to start again with a pencil.', 'Let Langston chart a route with mission cookies'),
('Everyone in one tunnel', 'The whole crew tries to enter the little tunnel together. There is a great deal of polite shuffling and no exploring at all. Nobody is stuck; everybody simply backs out.', 'Send the whole crew into the tiny tunnel'),
('An upside-down clue', 'Opal turns the map upside down. The star politely turns too. Lolo smiles. It seems the map needs an observation rather than a new direction.', 'Rotate the map until the answer looks obvious'),
('A magnificent leap', 'Langston announces that he will jump over the tower. Coatl asks him to try on the empty cushion mat first. He lands with a very impressive FWOOOMP. The star remains where it was.', 'Test Langston’s giant pillow leap'),
('The snack inspection', 'Langston checks every cookie for hidden starlight. None contains a star. Several contain less cookie than before. Cinny retrieves the real checklist.', 'Let Langston inspect the snack plate first'),
('A fishing expedition', 'A pretend fishing rod catches Langston’s cape instead of the star. He bows as though this was the plan. The friends untangle it and try a tool they can control.', 'Fish for the star with the pretend rod'),
('One very shiny helmet', 'The star rests on the pumpkin helmet and lights it like a lantern. It is beautiful, but the sharing message stays dim. Langston agrees that his head is not the whole crew.', 'Let Langston wear the star on his helmet'),
('The closed curtain', 'The friends draw a curtain around the star so it will look mysterious. Now nobody can see it. Stella nudges the curtain open again, and the crew reconsiders what sharing means.', 'Hide the star behind a fancy curtain'),
]
pillow_endings = [
('Make the Friendship Star together', 'A galaxy for everyone', 'Opal explains the map’s moving star, then invites every friend into the bedside circle. They touch the light together. Constellations bloom across the blanket roof, joining every paw with a golden line.\n\nSome days courage means exploring. Today it also meant resting and letting friends help. Langston hangs a NO TROLL SHOUTING sign outside. His goodnight is almost quiet. Lolo stays tucked against Opal as the Friendship Star shines.', [req('map_rule', 'Discover how the moving map works.'), req('share_star', 'Invite the friends to share the star.'), req('whole_circle', 'Make room for the whole circle beside Opal.')]),
('Carry the light from friend to friend', 'The traveling star', 'The star passes around on its cushion. Each friend adds a warm little spark, and Opal receives it last without leaving her blankets. It becomes a lantern for future story nights.\n\nThe roof stays a blanket rather than a galaxy, but nobody has to look at the light alone. Axey promises to draw the whole route in the morning. Lolo helps Opal close her eyes.', [req('star_pass', 'Choose to pass the star around safely.')]),
('Trace a constellation from the map', 'The mapmakers’ night', 'With Lolo beside her, Opal traces the star pattern on the map. Finley marks each place the crew searched. One small constellation appears above Opal’s pillow: a record of all their careful work.\n\nThey have not made the full Friendship Star tonight. Tomorrow they can invite more paws into the circle. For now, Opal rests beneath the gentle glow, and Langston finally whispers.', [req('star_pattern', 'Study the constellation pattern.')]),
('Save the star beside Opal’s pillow', 'A light for tomorrow', 'The friends place the star on a safe cushion beside Opal. There is no new galaxy tonight. Solving the search was quite enough for one sniffly commander.\n\nThey tidy quietly and promise to return when she feels better. Lolo keeps her paw in Opal’s hand. Outside, Langston turns his announcement sign around: RESTING IN PROGRESS.', []),
('Let the crew build a new resting fort', 'A smaller castle', 'The crew decides to move the cushions into a lower, simpler fort. The star slips into its soft sling while Coatl steadies the walls. It shines as one ordinary golden light.\n\nThe big tower and its mysterious pattern will wait. Opal has a safe place to sleep, and her friends have learned that an enormous castle is less useful than a comfortable one. Langston requests an equally comfortable snack corner.', []),
]
pillow_echoes = {'s05': [('map_rule', 'Because you tested the moving star, Opal can cross out the places already searched.'), ('paw_clue', 'Finley’s golden thread still points upward. The detectives have given Opal a different route to the same tower.')], 's08': [('small_climb', 'Coatl remembers the supported climbing plan and checks the base again.'), ('ribbon_sling', 'Unique Pink brings the sling you asked her to prepare.')], 's12': [('rest_finish', 'The crew has done the last work while Opal rests; her help never depended on leaving her blankets.')]}

snore_stages = [
('The missing giggle', '''Cherryberry tells a joke in the village square. Her mouth moves, but the punchline makes no sound. Above the fountain floats Duke Dozington, an enormous purple pillow creature with a curled mustache and a nightcap.

SHLUUUURP. His trumpet vacuum gathers a cloud of golden notes.

Langston is shouting something dramatic. For once, nobody can hear it. Opal takes Lolo's paw. They need a way to communicate before they investigate.''', ('Have Unique Pink make picture cards for the crew', 'trust', 'picture_cards'), ('Ask Finley to mark a clue trail in her notebook', 'clues', 'notebook_code')),
('The dropped controller', '''Near the tent, Finley finds purple feathers. Stella follows them to a small metal box. Its screen reads SNORE-SNATCHER 3000.

There are buttons marked GIGGLES, SONGS, and SNORES, plus one enormous red button marked EVERYTHING.

Opal studies it from a safe distance. They can learn about the controller without pressing a mystery button.''', ('Inspect the controller’s little diagrams', 'clues', 'controller_diagram'), ('Let Coatl detect the magic around it', 'power', 'magic_trace')),
('Into the Whispering Woods', '''A trail of purple feathers leads past glowing mushrooms and a wobbly bridge. Far ahead, a pillow castle rises above sleepy flowers.

Lolo stays beside Opal. Axey points out two possible ways to investigate: follow Duke's feather trail or climb a little overlook where they can study the castle first.''', ('Follow the feathers with Finley and Stella', 'clues', 'feather_route'), ('Let Axey scout the quiet overlook with Lolo', 'power', 'overlook_route')),
('The pillow moat', '''The castle ground sinks softly under Langston's first step. Coatl helps him back onto firm ground before he goes any deeper.

“I have been attacked by architecture,” Langston announces. His voice flickers as a little stolen sound escapes a wall cushion.

Each pillow contains a laugh, a song, or a sleepy sigh. The crew needs a reliable path to the door.''', ('Ask Coatl to brace a cushion crossing', 'power', 'safe_crossing'), ('Ask Unique Pink to mark the firm stepping spots', 'clues', 'marked_crossing')),
('Ask the important question', '''Duke waits above the doorway with his trumpet vacuum. “I LOVE QUIET!” he booms.

“You can't take everybody's sounds,” Opal tells him.

Lolo notices how tired he looks. The group can keep behind Coatl and still ask why Duke has chosen such an unhappy plan.''', ('Ask Duke what keeps him awake', 'trust', 'heard_duke'), ('Study the machine while Langston distracts Duke', 'clues', 'machine_route')),
('A heart full of sounds', '''Behind Duke stands the Ultimate Quiet Machine. Glowing pipes lead to a glass chamber and a huge purple pillow-heart.

Duke says that when it fills, every sound in Stuffy Land will disappear.

Lolo steps closer to Opal. “Even comforting a friend?”

Duke looks away. The crew cannot leave the stolen sounds inside, whatever he needs.''', ('Promise to help with quiet after the sounds return', 'trust', 'quiet_promise'), ('Ask Axey to map the switches that release the chamber', 'clues', 'switch_map')),
('Assign the rescue crew', '''The pillow-heart begins to rumble. Opal gives each friend a job. Coatl can steady the machine. Finley and Stella can inspect the chamber latch. Axey can reach the little switches.

Langston raises his hand. “I am available for extremely professional distraction.”

Lolo watches Duke as carefully as the crew watches the machine.''', ('Have Langston try the pumpkin troll dance', 'power', 'dance_plan'), ('Have Lolo keep Duke talking while Axey approaches', 'trust', 'talk_plan')),
('The first escaping note', '''A small golden note pops out of Duke's mustache. It floats toward the village before the machine pulls it back.

The friends notice that his grip loosens whenever he stops scowling. They can work with that discovery or concentrate on the chamber's release sequence.''', ('Find out whether laughter releases the stolen sounds', 'clues', 'laughter_clue'), ('Compare the release switches with the controller', 'clues', 'release_sequence')),
('Steady hands and paws', '''Coatl braces the machine. Finley finds the latch while Stella keeps the smaller kitties safely back. Axey waits for Opal's signal.

The room is full of flickering notes. A hasty tug could send them down the wrong pipe.

Opal's gemstone glows, showing the sound paths rather than solving the machinery for them.''', ('Match the switches to the glowing pipes', 'clues', 'matched_pipes'), ('Have the team count a steady rhythm together', 'trust', 'team_rhythm')),
('Open the sound chamber', '''Everything is ready. Langston has one more ridiculous dance move, Lolo has one more gentle question, and Axey can see the release lever.

“Everyone's sounds go home,” Opal says. “Then we can talk about what Duke needs.”

You choose which part of the plan takes the lead.''', ('Use the laughter and switch plan together', 'power', 'joined_rescue'), ('Lead a careful mechanical release with Coatl', 'clues', 'careful_release')),
('The sounds come home', '''The pillow-heart opens in a shower of gold. Laughter returns to the woods. Birds sing, the fountain splashes, and a very familiar HONK-SHOO escapes Langston's helmet.

“I WASN'T READY!” he says.

Duke settles among the cushions, looking small despite his enormous size. Everyone has their voice back. What happens after the rescue still matters.''', ('Ask Duke to help plan a proper quiet room', 'trust', 'quiet_room'), ('Help the village return its cushions and songs first', 'power', 'village_first')),
('A different kind of quiet', '''Opal sits beside Lolo while the crew tidies the castle. Duke's trumpet is switched off and the sound chamber stands open.

The friends have stopped the harm. Depending on what they learned and promised, they can also choose how much more to do together today.''', ('Invite Duke to listen while the friends explain their needs', 'trust', 'shared_needs'), ('Make a safe plan to return another day', 'clues', 'return_plan')),
]
snore_branches = {
2: [('The feather detectives', 'Finley follows the dropped feathers to a side doorway. Stella spots an OPEN WHEN NAPPING sign, showing that Duke has tried to warn visitors. The trail gives them both an entrance and a question to ask him.', 'Bring the sign’s meaning back to Opal', 'Check the doorway for a safe approach'), ('The quiet overlook', 'Axey and Lolo reach a low hill overlooking the castle. Birds sing directly above Duke’s bedroom window, and the humming mushrooms crowd its wall. Lolo sees why sleeping here could be difficult, though stealing sounds cannot be the answer.', 'Let Lolo explain what she noticed', 'Have Axey sketch the bedroom and machine')],
4: [('Four hundred years of bad naps', 'Duke waves all four arms. The birds, frogs, squirrels, wind, and even mushrooms keep him awake. When he asked for quiet, he felt laughed at. Opal listens without agreeing that he may take everyone’s voice. Lolo tells him needing help does not make him weak.', 'Tell Duke you heard his need for rest', 'Ask which sounds reach his bedroom first'), ('Behind the glowing pipes', 'Langston requests a detailed explanation of the castle’s snack policy. While Duke objects, Axey studies the exposed pipes. The little controller mirrors the chamber switches. A valve can return the sounds without aiming the trumpet at anyone.', 'Have Axey share the plan with the team', 'Mark the release valve on Finley’s drawing')],
7: [('The pumpkin troll experiment', 'Langston bends his knees, spins once, and lands on a soft cushion. Duke tries not to smile. Then he laughs, and three golden notes escape his mustache. Opal has found a way to loosen the machine’s hold while Axey works.', 'Invite Duke to laugh with Langston', 'Ask Finley to count the escaping notes'), ('The switchboard puzzle', 'Axey finds three small release switches and one large suction dial. The diagram shows that the switches must open before the dial closes. Opal repeats the order to Lolo, who repeats it to the rest of the team.', 'Let the whole crew confirm the sequence', 'Trace the sound path one last time')],
9: [('Laugh and release', 'Langston performs the Troll Tornado while Axey opens the switches. Coatl holds the rattling machine and Finley and Stella pull the latch together. Lolo stays beside Opal as her gemstone lights the last pipe. The chamber opens with a harmless golden pop.', 'Help the smallest sounds find the door', 'Check that no notes remain in the pipes'), ('The careful rescue', 'Opal signals one switch at a time. Axey opens each valve while Coatl prevents the chamber from tilting. Lolo reassures Duke that the group will stop the machine rather than hurt him. Finley and Stella open the latch, and the golden notes pour out.', 'Guide the sounds back toward the village', 'Ask the crew to check the empty chamber')]
}
snore_detours = [
('The louder announcement', 'Langston shouts harder. His silent face becomes very dramatic, but no one learns anything. Opal points to Finley’s notebook instead. They can communicate without winning a shouting contest.', 'Ask Langston to shout louder than the vacuum'),
('The everything button', 'Opal reaches toward EVERYTHING, then stops when Coatl’s warning lights glow. The unknown button might collect even more sounds. They set the controller down and choose a way to learn first.', 'Consider pressing the enormous mystery button'),
('A very obvious disguise', 'Langston hides beneath a blanket that leaves his legs showing. Duke immediately points at the moving knees. Nobody is caught; the crew simply waits for him to look away and rethinks the approach.', 'Have Langston sneak in disguised as a tiny pillow'),
('Architecture wins again', 'Langston tests the soft ground with one theatrical stomp. His boot sinks into a cushion, and Coatl helps him pull it free. They will need a crossing instead of another stomp.', 'Test the pillow moat with a magnificent stomp'),
('A shouting competition', 'Duke shouts that he wants quiet. Langston shouts that Duke is being loud. Opal holds up a picture of a listening ear. The argument is going nowhere, so they start with a different question.', 'Let Langston argue about who is loudest'),
('A helmet full of snores', 'Duke aims a brief puff at the pumpkin helmet. It begins snoring. Langston insists this is not his snore. Lolo raises one eyebrow. They set the helmet safely aside before planning the rescue.', 'Ask Duke to demonstrate the trumpet on a helmet'),
('An entire dance committee', 'Everybody begins explaining a different distraction at once. Duke looks baffled, Axey cannot hear the plan, and the machine keeps rumbling. Opal asks the team to choose one leader for this part.', 'Let everyone give Langston instructions at once'),
('Tickling the machinery', 'Langston tickles a pipe with a feather. It rattles but does not laugh. “A difficult audience,” he says. Opal decides the clue probably belongs to Duke rather than his plumbing.', 'Try making the machine laugh instead'),
('Backwards counting', 'Langston counts backward while Axey counts forward. The crew pauses before touching a switch. Stella taps a single slow rhythm so they can start together.', 'Let Langston invent his own counting system'),
('The snack lever', 'Langston mistakes the castle snack cupboard handle for a release lever. It opens onto crackers. Useful information, perhaps, but the stolen notes are still in the chamber. Opal points back to the real controls.', 'Follow Langston’s promising snack-cupboard theory'),
]
snore_endings = [
('Build Duke a quiet room with a shared agreement', 'A room for rest and a world of sound', 'Duke returns the last cushion of stolen sounds and helps build a room with thick soft walls, a big blanket, and a PLEASE KNOCK sign. He apologizes to the village. The friends agree on ways to ask for quiet without stealing anyone’s voice.\n\nA few days later, Duke invites Langston over to practice the pumpkin troll dance. He sleeps afterward while the rest of Stuffy Land enjoys its music. Opal and Lolo leave a lantern beside his door, then walk home with Axey.', [req('heard_duke', 'Ask what keeps Duke awake.'), req('quiet_promise', 'Promise to help after restoring the sounds.'), req('quiet_room', 'Plan a proper quiet room together.')]),
('Help Duke begin a quiet-room project', 'The first soft wall', 'The friends gather spare pillows for a better bedroom. Duke helps with the work and learns that asking for help is easier than maintaining a giant machine. There are still things to understand about his long, lonely naps.\n\nThey agree to talk again when he is rested. Lolo leaves a little space beside Opal for him at the next village gathering. Langston offers design advice about the snack cupboard.', [req('quiet_room', 'Choose to begin planning Duke’s quiet room.')]),
('Leave Duke a picture invitation to talk', 'An invitation after the rescue', 'Opal gives Duke a picture card showing a listening ear, a pillow, and an open door. He has returned the sounds, but explaining his needs will take practice.\n\nThey arrange another visit with Coatl nearby. Nobody must forgive before they are ready. Duke places the card beside his switched-off trumpet, where he will see it when he wakes.', [req('picture_cards', 'Prepare picture cards at the beginning.')]),
('Return the village’s sounds and come back later', 'Home before the next plan', 'The crew returns the cushions to the village. Duke stays in his castle with the machine safely switched off and its chamber open. Every stolen sound is home.\n\nThere is more to work out, but not all of it must happen today. Opal makes a plan to return with Coatl. Lolo reminds her that stopping harm and understanding somebody can take different amounts of time.', []),
('Make the castle safe and finish for today', 'The quiet castle', 'Coatl disconnects the trumpet from the empty machine while the friends check every last pillow for trapped notes. Duke has to find another way to rest. He does not become their friend that evening.\n\nOpal leaves the path clear for a future conversation and heads home beside Lolo. The village can sing again. Langston tries one very small dance, and Axey laughs all the way back to the tent.', []),
]
snore_echoes = {'s05': [('feather_route', 'Finley remembers the napping sign the detectives found by the side doorway.'), ('overlook_route', 'Lolo remembers the birds and humming mushrooms beside Duke’s bedroom.')], 's08': [('heard_duke', 'Opal remembers Duke’s sleeplessness; his tired eyes make more sense now.'), ('machine_route', 'Axey brings out the pipe diagram you gave him time to study.')], 's11': [('quiet_promise', 'Opal has not forgotten her promise to help Duke after everyone’s sounds are safe.')]}


def main():
    pillow = adventure('pillow_fort', 'Opal and the Great Pillow-Fort Mystery', 'Help Opal lead a search for the Lost Star without leaving her cozy blankets.', 'stuffy-tent', pillow_stages, pillow_branches, pillow_detours, pillow_endings, pillow_echoes)
    snore = adventure('snore_snatcher', 'Opal and the Great Snore-Snatcher', 'Recover the stolen sounds and decide how to help a very tired pillow villain.', 'stuffy-snore', snore_stages, snore_branches, snore_detours, snore_endings, snore_echoes)
    listings = []
    provenance = []
    for filename, book, symbol, art in [('pillow_fort', pillow, 'star.fill', 'stuffy-tent'), ('snore_snatcher', snore, 'moon.zzz.fill', 'stuffy-snore')]:
        listings.append({'id': book['id'], 'filename': filename, 'contentVersion': 1, 'kind': 'adventure', 'title': book['title'], 'subtitle': book['subtitle'], 'blurb': book['subtitle'], 'genre': 'Choose your adventure', 'symbol': symbol, 'estimatedMinutes': 20, 'coverAsset': art, 'collection': 'Choose an adventure', 'editorialNote': 'Interactive adaptation of a complete recovered story.'})
        provenance.append({'id': book['id'], 'status': 'interactive_adaptation', 'source': f'source/{filename}.txt', 'notes': 'New branching scenes and alternate endings; original source preserved separately.'})
    readers = [
        ('giggle_games', 'The whole cast joins Langston’s wonderfully ridiculous games.', 'figure.dance', 'original'),
        ('invisible_bracelet', 'An invisible adventure helps Opal understand being apart.', 'eye.slash', 'summary'),
        ('sneaky_troll', 'Langston discovers when a prank stops being fun.', 'theatermasks', 'summary'),
        ('monster_disguise', 'Opal’s secret challenge teaches her something unexpected.', 'pawprint', 'summary'),
        ('heart_monster', 'A blue-and-black kitty discovers friendship cannot be collected.', 'heart.fill', 'summary'),
        ('concert', 'A concert goes wrong until Opal listens beyond the fence.', 'music.mic', 'summary'),
        ('gigglequake', 'A giant cloud tangles up Opal’s ability to care.', 'cloud.fill', 'summary'),
        ('inside_out', 'A strange storm unfolds the world in all the wrong directions.', 'tornado', 'summary'),
        ('impossible_birthday', 'A time storm turns birthday memories into a treasure hunt.', 'birthday.cake', 'summary'),
        ('star_eater', 'A disappearing sky leads to a surprising act of compassion.', 'sparkles', 'summary'),
        ('thousand_traps', 'A new expedition inspired by the surviving treasure-hunt premise.', 'map.fill', 'premise'),
    ]
    for filename, subtitle, symbol, status in readers:
        src = EDITORIAL / ('source' if status == 'original' else 'stories') / (filename + '.txt')
        parts = paragraphs(src.read_text())
        title, body = parts[0], parts[1:]
        note = {'original': 'Original story recovered in full from the supplied transcript.', 'summary': 'New story adapted from a recovered plot summary; original wording was unavailable.', 'premise': 'New story inspired by a surviving title and premise; the original plot and ending were unavailable.'}[status]
        # No added chapter headings. Small paragraphs can stay together on one flowing page.
        pages, current, words = [], [], 0
        for para in body:
            if current and (words + len(para.split()) > 230 or len(current) >= 30):
                pages.append(current); current, words = [], 0
            current.append(para); words += len(para.split())
        if current:
            pages.append(current)
        book = {'id': 'stuffy-' + filename.replace('_', '-'), 'contentVersion': 1, 'title': title, 'subtitle': subtitle, 'editorialNote': note,
                'pages': [{'id': f'page_{i+1:02}', 'paragraphs': p} for i, p in enumerate(pages)]}
        # A focused illustration rather than recycling the flawed ensemble pictures.
        book['pages'][0]['illustration'] = {'asset': 'stuffy-tent', 'alt': 'Opal holds her sloth lovey Lolo while reading inside the purple galaxy tent.'}
        write(CONTENT / (filename + '.json'), book)
        duration = max(4, math.ceil(sum(len(p.split()) for p in body)/145))
        listings.append({'id': book['id'], 'filename': filename, 'contentVersion': 1, 'kind': 'reader', 'title': title, 'subtitle': subtitle, 'blurb': subtitle, 'genre': 'Read or listen', 'symbol': symbol, 'estimatedMinutes': duration, 'coverAsset': 'stuffy-tent', 'collection': 'Read or listen', 'editorialNote': note})
        provenance.append({'id': book['id'], 'status': {'original':'recovered_original', 'summary':'summary_adaptation', 'premise':'premise_inspired_new_story'}[status], 'source': str(src.relative_to(EDITORIAL)), 'notes': note})
    # The new interactive Sundae Switch is authored as its own story graph,
    # not extracted from the recovered transcript. Preserve its catalog entry
    # when this deterministic builder regenerates the original collection.
    sundae = json.loads((CONTENT / 'sundae_switch.json').read_text())
    listings.insert(2, {
        'id': sundae['id'], 'filename': 'sundae_switch', 'contentVersion': sundae['contentVersion'],
        'kind': 'adventure', 'title': sundae['title'], 'subtitle': sundae['subtitle'],
        'blurb': 'The Annoyings Express sends a special sundae flying across Stuffy Land. Help Opal save it.',
        'genre': 'Choose your adventure', 'symbol': 'birthday.cake.fill',
        'estimatedMinutes': 13, 'coverAsset': 'sundae-scene-01',
        'collection': 'Choose an adventure',
        'editorialNote': 'New original interactive story, written for the Stuffy Land app; not a recovered transcript.'
    })
    provenance.append({
        'id': sundae['id'], 'status': 'new_original_interactive',
        'source': '../Content/sundae_switch.json',
        'notes': 'Original new interactive story, not recovered archive material; nine of eighteen story scenes are illustrated.'
    })
    write(CONTENT / 'catalog.json', {'formatVersion': 1, 'adventures': listings})
    write(EDITORIAL / 'story-provenance.json', {'sourceDocumentSHA256': 'ab0dbfbe1381b242ed7da202ae18a6fd52a231cc37e26bf8a649db5b8ac31a63', 'duplicateAttachments': True, 'stories': provenance})
    print(f'Built {len(listings)} stories: 3 adventures and {len(readers)} readers')


if __name__ == '__main__':
    main()
