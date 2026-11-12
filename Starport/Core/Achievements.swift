import Foundation

public struct Achievement: Identifiable, Sendable {
    public enum Group: String, CaseIterable, Sendable {
        case endings = "Endings"
        case exploration = "Exploration"
        case mastery = "Mastery"
    }

    public let id: String
    public let title: String
    public let detail: String
    public let symbol: String
    public let group: Group
    public let secret: Bool
    /// The Starport adventure this achievement belongs to (`StoryBook.id`).
    /// Stuffy Land keeps its own separate list.
    public let bookID: String

    public init(_ id: String, _ title: String, _ detail: String,
                _ symbol: String, _ group: Group, secret: Bool = false,
                book: String = AchievementCatalog.doorTomorrowID) {
        self.id = id
        self.bookID = book
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.group = group
        self.secret = secret
    }
}

public enum AchievementEvent: Sendable {
    case choice
    case rewind
    case newRun
}

/// Stable identifiers are stored on-device. Keep IDs unchanged as titles evolve.
public enum AchievementCatalog {
    public static let doorTomorrowID = "door-tomorrow"
    public static let carThirteenID = "car-thirteen"

    /// One trophy shelf per Starport adventure, in library order.
    public struct Shelf: Identifiable, Sendable {
        public let bookID: String
        public let title: String
        public var id: String { bookID }
    }

    public static let shelves: [Shelf] = [
        Shelf(bookID: doorTomorrowID, title: "The Door That Opens Tomorrow"),
        Shelf(bookID: carThirteenID, title: "The Thirteenth Car")
    ]

    /// Every Starport achievement. Each adventure only awards its own.
    public static let all: [Achievement] = doorTomorrow + carThirteen

    public static func achievements(for bookID: String) -> [Achievement] {
        all.filter { $0.bookID == bookID }
    }

    public static let doorTomorrow: [Achievement] = [
        Achievement("ending_1", "Perfect Signal", "Reach the best ending.", "sparkles", .endings, secret: true),
        Achievement("ending_2", "The Long Way Home", "Bring everyone home by the safe route.", "moon.stars", .endings, secret: true),
        Achievement("ending_3", "A Hard Landing", "Finish with the station damaged but the Wren safe.", "wrench.adjustable", .endings, secret: true),
        Achievement("ending_4", "An Empty Dock", "Protect the station at the cost of the mission.", "lock.shield", .endings, secret: true),
        Achievement("ending_5", "The Light That Lied", "Find the worst ending.", "exclamationmark.triangle", .endings, secret: true),

        Achievement("first_choice", "Your Call", "Make your first story decision.", "hand.point.up.left", .exploration),
        Achievement("eighteen", "Halfway Through", "Make 18 decisions in one run.", "figure.walk", .exploration),
        Achievement("thirty", "In Deep", "Make at least 30 decisions in one run.", "sailboat", .exploration),
        Achievement("first_detour", "False Alarm", "Discover one false ending.", "arrow.uturn.backward", .exploration),
        Achievement("three_detours", "Wrong Turns", "Find three different false endings.", "point.topleft.down.curvedto.point.bottomright.up", .exploration),
        Achievement("all_detours", "Every Dead End", "Discover all 12 false endings.", "map", .exploration),
        Achievement("first_rewind", "One More Try", "Rewind a false ending and continue.", "arrow.counterclockwise", .exploration),
        Achievement("ally_ren", "Repair Crew", "Earn Ren's help.", "person.2", .exploration),
        Achievement("mika_contact", "Across Tomorrow", "Establish contact with Mika.", "antenna.radiowaves.left.and.right", .exploration),
        Achievement("old_route", "Old Maps", "Find the forgotten flight route.", "map.fill", .exploration),
        Achievement("time_proof", "Impossible Evidence", "Record proof that a signal traveled backward in time.", "clock.arrow.circlepath", .exploration),
        Achievement("drone_ready", "Tiny Navigator", "Wake the station's repair drone.", "airplane", .exploration),
        Achievement("handshake", "In Sync", "Coordinate the pulse with Mika.", "waveform", .exploration),

        Achievement("full_clues", "Sharp Eyes", "Fill the Clues meter.", "eye", .mastery),
        Achievement("full_trust", "Trusted Cadet", "Fill the Trust meter.", "person.crop.circle.badge.checkmark", .mastery),
        Achievement("full_power", "Fully Charged", "Fill the Power meter.", "bolt.fill", .mastery),
        Achievement("clean_run", "No Wrong Turns", "Reach any permanent ending without entering a false ending in that run.", "checkmark.shield", .mastery),
        Achievement("two_endings", "Another Timeline", "Discover two different permanent endings.", "arrow.triangle.branch", .mastery),
        Achievement("all_endings", "Five Futures", "Discover all five permanent endings.", "star.circle.fill", .mastery),
        Achievement("crew_pact", "Crew First", "Bring the crew together.", "person.3", .mastery)
    ]

    private static func car13(_ id: String, _ title: String, _ detail: String,
                              _ symbol: String, _ group: Achievement.Group,
                              secret: Bool = false) -> Achievement {
        Achievement("car13_\(id)", title, detail, symbol, group, secret: secret, book: carThirteenID)
    }

    /// Story flags that unlock a Thirteenth Car achievement the moment they are earned.
    private static let carThirteenFlags: [String: String] = [
        "ember_friend": "car13_ember",
        "wick_trust": "car13_handshake",
        "song_taught": "car13_song",
        "pip_confessed": "car13_pip",
        "fake_inspector": "car13_regards",
        "halvard_past": "car13_halvard",
        "notebook_saved": "car13_notebook",
        "reserve_switch": "car13_tea_tin",
        "radio_tapped": "car13_marzipan",
        "route_under": "car13_under",
        "route_over": "car13_roofs",
        "route_engine": "car13_key",
        "route_lamp": "car13_lamp",
        "endgame_skiff": "car13_skiff"
    ]

    public static let carThirteen: [Achievement] = [
        car13("ending_1", "Every Lantern Lit", "Sing the train home. The best ending.", "sparkles", .endings, secret: true),
        car13("ending_2", "The Coupler Who Jumped", "Ride the thief's skiff into the nets.", "figure.fall", .endings, secret: true),
        car13("ending_3", "The Long Way Round", "Send Ember home the careful way.", "moon.stars", .endings, secret: true),
        car13("ending_4", "The Wrong Three", "Save three eggs and lose sight of the fourth.", "circle.grid.3x3", .endings, secret: true),
        car13("ending_5", "A Hard Stop", "Brake with everything the Marigold has.", "wrench.adjustable", .endings, secret: true),
        car13("ending_6", "Twelve Cars", "Make the list correct again.", "list.number", .endings, secret: true),
        car13("ending_7", "Off the End of the Line", "Find the worst ending.", "exclamationmark.triangle", .endings, secret: true),

        car13("first_choice", "All Aboard", "Make your first decision on the Marigold.", "tram.fill", .exploration),
        car13("halfway", "Halfway Bell", "Make 25 decisions in one run.", "bell", .exploration),
        car13("fifty", "Fifty Lanterns", "Make 50 decisions in one run.", "lightbulb.fill", .exploration),
        car13("first_detour", "Turnip Trouble", "Stumble into a false ending.", "arrow.uturn.backward", .exploration),
        car13("first_rewind", "Back on Track", "Rewind a false ending and carry on.", "arrow.counterclockwise", .exploration),
        car13("ember", "Handle With Kindness", "Win Ember's trust.", "flame", .exploration),
        car13("handshake", "Four Steps and an Elbow", "Earn the Lamplighter handshake from Wick.", "hand.wave", .exploration),
        car13("song", "One-Tenth of a Lamplighter", "Learn the lantern song.", "music.note", .exploration),
        car13("pip", "PIP Typed Your Number", "Hear PIP's confession.", "cpu", .exploration),
        car13("regards", "She Sends Her Regards", "Keep the Company's message about Inspector Vane.", "envelope.open", .exploration),
        car13("halvard", "The Boy in the Mirror Coat", "Learn where Old Halvard came from.", "person.crop.square", .exploration),
        car13("under", "Braver From the Back", "Take the crawlway under the floors.", "arrow.down.to.line", .exploration),
        car13("roofs", "Roof Legs", "Walk the roof of a moving star train.", "figure.walk", .exploration),
        car13("key", "Never Lent It Once", "Carry the Conductor's brass key.", "key.fill", .exploration),
        car13("lamp", "Long, Short, Short", "Signal the Moth Fleet from the lamp car.", "flashlight.on.fill", .exploration),
        car13("skiff", "Nobody Ever Looks Up", "Board the thief's skiff from above.", "arrow.up.forward", .exploration),

        car13("all_detours", "Every Last Turnip", "Discover all 12 false endings.", "map", .mastery),
        car13("notebook", "Keep Your Scribbles", "Save your notebook when Vane takes the evidence.", "book.closed", .mastery),
        car13("tea_tin", "Behind the Tea Tin", "Be shown Halvard's reserve switch.", "cup.and.saucer.fill", .mastery),
        car13("marzipan", "Password: Marzipan", "Have Ember repeat Vane's secret.", "ear", .mastery),
        car13("full_trust", "The Whole Crew", "Fill the Trust meter.", "person.3", .mastery),
        car13("full_power", "Full Lamp", "Fill the Power meter.", "bolt.fill", .mastery),
        car13("clean_run", "Right on Time", "Reach a permanent ending without a single false ending in that run.", "checkmark.shield", .mastery),
        car13("three_ways", "Three Ways Home", "Finish once by the song, once by the skiff and once at the coupling.", "arrow.triangle.branch", .mastery),
        car13("all_endings", "The Whole Line", "Discover all seven permanent endings.", "star.circle.fill", .mastery)
    ]

    private static func carThirteenUnlocked(_ engine: AdventureEngine, event: AchievementEvent) -> Set<String> {
        let p = engine.progress
        var earned: Set<String> = []

        if p.decisionCount >= 1 { earned.insert("car13_first_choice") }
        if p.decisionCount >= 25 { earned.insert("car13_halfway") }
        if p.decisionCount >= 50 { earned.insert("car13_fifty") }
        if p.detoursFound.count >= 1 { earned.insert("car13_first_detour") }
        if engine.book.detourCount > 0, p.detoursFound.count >= engine.book.detourCount {
            earned.insert("car13_all_detours")
        }
        if case .rewind = event { earned.insert("car13_first_rewind") }

        for (flag, id) in carThirteenFlags where p.flags.contains(flag) {
            earned.insert(id)
        }
        if p.stats.trust == 5 { earned.insert("car13_full_trust") }
        if p.stats.power == 5 { earned.insert("car13_full_power") }

        let found = Set((1...7).filter { p.endingsFound.contains("car13_final_\($0)") })
        for rank in found { earned.insert("car13_ending_\(rank)") }
        // Ending 1 needs the song, 2 and 4 need the skiff, 5 to 7 need the coupling.
        if found.contains(1), !found.isDisjoint(with: [2, 4]), !found.isDisjoint(with: [5, 6, 7]) {
            earned.insert("car13_three_ways")
        }
        if found.count == 7 { earned.insert("car13_all_endings") }
        if engine.node.ending?.kind == .final && p.runDetoursTriggered == 0 {
            earned.insert("car13_clean_run")
        }
        return earned
    }

    public static func unlockedBy(_ engine: AdventureEngine, event: AchievementEvent, stuffyLand: Bool = false) -> Set<String> {
        if stuffyLand { return stuffyUnlockedBy(engine, event: event) }
        if engine.book.id == carThirteenID { return carThirteenUnlocked(engine, event: event) }
        let p = engine.progress
        let ending = engine.node.ending
        var earned: Set<String> = []

        if p.decisionCount >= 1 { earned.insert("first_choice") }
        if p.decisionCount >= 18 { earned.insert("eighteen") }
        if p.decisionCount >= 30 { earned.insert("thirty") }
        if p.detoursFound.count >= 1 { earned.insert("first_detour") }
        if p.detoursFound.count >= 3 { earned.insert("three_detours") }
        if p.detoursFound.count >= 12 { earned.insert("all_detours") }
        if case .rewind = event { earned.insert("first_rewind") }

        for marker in ["ally_ren", "mika_contact", "old_route", "time_proof",
                       "drone_ready", "handshake", "crew_pact"] {
            if p.flags.contains(marker) { earned.insert(marker) }
        }

        if p.stats.clues == 5 { earned.insert("full_clues") }
        if p.stats.trust == 5 { earned.insert("full_trust") }
        if p.stats.power == 5 { earned.insert("full_power") }

        for index in 1...5 {
            if p.endingsFound.contains("final_\(index)") {
                earned.insert("ending_\(index)")
            }
        }
        if p.endingsFound.count >= 2 { earned.insert("two_endings") }
        if p.endingsFound.count == 5 { earned.insert("all_endings") }
        if ending?.kind == .final && p.runDetoursTriggered == 0 {
            earned.insert("clean_run")
        }
        return earned
    }

    /// Canonical ending memories are scoped separately to each Opal adventure.
    public static let stuffyLand: [Achievement] = {
        let stories = [
            ("pillow", ["A Galaxy for Everyone", "The Traveling Star", "The Mapmakers’ Night", "A Light for Tomorrow", "A Smaller Castle"]),
            ("snore", ["Rest and Sound", "The First Soft Wall", "An Invitation", "Home Again", "The Quiet Castle"]),
            ("sundae", ["One Spoonful at a Time", "The Grand Unveiling", "The Party Is Saved", "The Mapmakers’ Rescue", "The Lopsided Sundae"]),
            ("titanus", ["The Biggest New Friend", "A Star for Two", "The Quiet Bell", "The Upside-Down Fortress", "The Snack Truce", "An Igloo for a Giant", "Everybody Floats"])
        ]
        let endings = stories.flatMap { prefix, titles in
            titles.enumerated().map { index, title in
                Achievement("\(prefix)_ending_\(index + 1)", title,
                            "Discover this Stuffy Land ending.", "star.fill", .endings, secret: true)
            }
        }
        return endings + [
            Achievement("first_choice", "First Stitch", "Make your first Stuffy Land choice.", "hand.point.up.left.fill", .exploration),
            Achievement("ten_choices", "A Story Unfolds", "Make ten choices in one adventure.", "book", .exploration),
            Achievement("first_detour", "A Little Detour", "Discover a funny turn in the story.", "arrow.uturn.backward", .exploration),
            Achievement("three_detours", "A Winding Path", "Discover three different detours in one story.", "map.fill", .exploration),
            Achievement("all_detours", "Every Little Turn", "Discover every detour in one adventure.", "map", .exploration),
            Achievement("first_rewind", "Try That Again", "Try another way after a detour.", "arrow.counterclockwise", .exploration),
            Achievement("map_rule", "The Moving Star", "Discover what the golden map is showing.", "sparkle", .exploration),
            Achievement("share_star", "Room for Everyone", "Invite every friend to share the star.", "person.3", .exploration),
            Achievement("heard_duke", "A Listening Ear", "Listen to why Duke cannot sleep.", "ear", .exploration),
            Achievement("quiet_room", "A Place to Rest", "Help Duke plan a quiet room.", "moon.zzz", .exploration),
            Achievement("laughter_clue", "A Laugh Gets Loose", "Discover how laughter frees the sounds.", "music.note", .exploration),
            Achievement("first_spoonful", "One Spoonful", "Offer Swirly the first taste of the rescued sundae.", "heart.fill", .exploration),
            Achievement("spinner_untangled", "Express Detective", "Find and free the broken delivery spinner.", "magnifyingglass", .exploration),
            Achievement("titan_carvings", "The Waterfall Secret", "Read the carvings behind the waterfall.", "mountain.2.fill", .exploration),
            Achievement("titan_lullaby", "A Giant’s Lullaby", "Hear Titanus sing to the empty cradle.", "music.quarternote.3", .exploration),
            Achievement("titan_crumb", "Crumb-Sized Hero", "Send Onion Ring Kitty through the tiny door.", "circle.dotted", .exploration),
            Achievement("titan_donut", "Donut of Distraction", "Launch the Donut of Distraction.", "circle.circle", .exploration),
            Achievement("full_curiosity", "Curious Paws", "Fill the Curiosity meter.", "eye.fill", .mastery),
            Achievement("full_courage", "Brave Enough", "Fill the Courage meter.", "shield.fill", .mastery),
            Achievement("full_friendship", "Good Friends", "Fill the Friendship meter.", "person.2.fill", .mastery),
            Achievement("clean_run", "A Steady Path", "Finish an adventure without taking a detour.", "checkmark.seal.fill", .mastery),
            Achievement("two_endings", "Another Way", "Discover two endings in one adventure.", "arrow.triangle.branch", .mastery),
            Achievement("all_endings", "Every Way Home", "Discover every ending in one adventure.", "star.circle.fill", .mastery)
        ]
    }()

    public static func all(forStuffyLand: Bool) -> [Achievement] {
        forStuffyLand ? stuffyLand : all
    }

    private static func stuffyUnlockedBy(_ engine: AdventureEngine, event: AchievementEvent) -> Set<String> {
        let p = engine.progress
        var earned: Set<String> = []
        if p.decisionCount >= 1 { earned.insert("first_choice") }
        if p.decisionCount >= 10 { earned.insert("ten_choices") }
        if p.detoursFound.count >= 1 { earned.insert("first_detour") }
        if p.detoursFound.count >= 3 { earned.insert("three_detours") }
        if engine.book.detourCount > 0 && p.detoursFound.count >= engine.book.detourCount {
            earned.insert("all_detours")
        }
        if case .rewind = event { earned.insert("first_rewind") }
        for flag in ["map_rule", "share_star", "heard_duke", "quiet_room", "laughter_clue", "first_spoonful", "spinner_untangled",
                     "titan_carvings", "titan_lullaby", "titan_crumb", "titan_donut"] where p.flags.contains(flag) {
            earned.insert(flag)
        }
        if p.stats.clues == 5 { earned.insert("full_curiosity") }
        if p.stats.power == 5 { earned.insert("full_courage") }
        if p.stats.trust == 5 { earned.insert("full_friendship") }
        if engine.node.ending?.kind == .final && p.runDetoursTriggered == 0 { earned.insert("clean_run") }
        let prefix: String?
        switch engine.book.id {
        case "stuffy-pillow-fort": prefix = "pillow"
        case "stuffy-snore-snatcher": prefix = "snore"
        case "stuffy-sundae-switch": prefix = "sundae"
        case "stuffy-titanus": prefix = "titanus"
        default: prefix = nil
        }
        if let prefix {
            for rank in 1...engine.book.finalCount where p.endingsFound.contains("final_\(rank)") {
                earned.insert("\(prefix)_ending_\(rank)")
            }
            if p.endingsFound.count >= 2 { earned.insert("two_endings") }
            if p.endingsFound.count >= engine.book.finalCount { earned.insert("all_endings") }
        }
        return earned
    }

}
