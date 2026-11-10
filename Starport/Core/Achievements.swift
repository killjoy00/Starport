import Foundation

public struct Achievement: Identifiable, Sendable {
    public enum Group: String, CaseIterable, Sendable {
        case endings = "The five endings"
        case exploration = "Exploration"
        case mastery = "Mastery"
    }

    public let id: String
    public let title: String
    public let detail: String
    public let symbol: String
    public let group: Group
    public let secret: Bool

    public init(_ id: String, _ title: String, _ detail: String,
                _ symbol: String, _ group: Group, secret: Bool = false) {
        self.id = id
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
    public static let all: [Achievement] = [
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

    public static func unlockedBy(_ engine: AdventureEngine, event: AchievementEvent, stuffyLand: Bool = false) -> Set<String> {
        if stuffyLand { return stuffyUnlockedBy(engine, event: event) }
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
            ("sundae", ["One Spoonful at a Time", "The Grand Unveiling", "The Party Is Saved", "The Mapmakers’ Rescue", "The Lopsided Sundae"])
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
            Achievement("full_curiosity", "Curious Paws", "Fill the Curiosity meter.", "eye.fill", .mastery),
            Achievement("full_courage", "Brave Enough", "Fill the Courage meter.", "shield.fill", .mastery),
            Achievement("full_friendship", "Good Friends", "Fill the Friendship meter.", "person.2.fill", .mastery),
            Achievement("clean_run", "A Steady Path", "Finish an adventure without taking a detour.", "checkmark.seal.fill", .mastery),
            Achievement("two_endings", "Another Way", "Discover two endings in one adventure.", "arrow.triangle.branch", .mastery),
            Achievement("all_endings", "Every Way Home", "Discover all five endings in one adventure.", "star.circle.fill", .mastery)
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
        for flag in ["map_rule", "share_star", "heard_duke", "quiet_room", "laughter_clue", "first_spoonful", "spinner_untangled"] where p.flags.contains(flag) {
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
