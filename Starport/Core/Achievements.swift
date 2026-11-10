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

    public static func unlockedBy(_ engine: AdventureEngine, event: AchievementEvent) -> Set<String> {
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
}
