import Foundation

public enum StoryStat: String, Codable, CaseIterable, Sendable {
    case clues, power, trust
    public var title: String {
        switch self {
        case .clues: return "Clues"
        case .power: return "Power"
        case .trust: return "Trust"
        }
    }
}

public struct AdventureStats: Codable, Equatable, Sendable {
    public var clues: Int
    public var power: Int
    public var trust: Int

    public init(clues: Int = 0, power: Int = 3, trust: Int = 1) {
        self.clues = clues
        self.power = power
        self.trust = trust
    }

    public subscript(_ stat: StoryStat) -> Int {
        get {
            switch stat {
            case .clues: return clues
            case .power: return power
            case .trust: return trust
            }
        }
        set {
            let value = min(5, max(0, newValue))
            switch stat {
            case .clues: clues = value
            case .power: power = value
            case .trust: trust = value
            }
        }
    }
}

public struct StoryRequirement: Codable, Equatable, Sendable {
    public let stat: StoryStat?
    public let atLeast: Int?
    public let flag: String?
    public let hint: String

    public func isMet(stats: AdventureStats, flags: Set<String>) -> Bool {
        (stat.map { stats[$0] >= (atLeast ?? 0) } ?? true) &&
        (flag.map { flags.contains($0) } ?? true)
    }
}

public struct StoryEffect: Codable, Equatable, Sendable {
    public let stat: StoryStat?
    public let delta: Int?
    public let flag: String?

    public init(stat: StoryStat? = nil, delta: Int? = nil, flag: String? = nil) {
        self.stat = stat
        self.delta = delta
        self.flag = flag
    }
}

public struct StoryChoice: Codable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let detail: String?
    public let to: String
    public let outcome: String?
    public let requirements: [StoryRequirement]?
    public let effects: [StoryEffect]?

    public func isAvailable(stats: AdventureStats, flags: Set<String>) -> Bool {
        (requirements ?? []).allSatisfy { $0.isMet(stats: stats, flags: flags) }
    }

    public func lockedReason(stats: AdventureStats, flags: Set<String>) -> String? {
        let unmet = (requirements ?? []).filter { !$0.isMet(stats: stats, flags: flags) }
        return unmet.isEmpty ? nil : unmet.map(\.hint).joined(separator: " · ")
    }
}

public enum EndingKind: String, Codable, Sendable {
    case final, detour
}

public struct StoryEnding: Codable, Sendable {
    public let id: String
    public let kind: EndingKind
    /// Final outcomes: 1 is best; 5 is worst. Detours have no rank.
    public let rank: Int?
    public let title: String
    public let note: String
}

public struct ConditionalParagraph: Codable, Sendable {
    public let requirement: StoryRequirement
    public let text: String
}

public struct StoryIllustration: Codable, Sendable {
    public let asset: String
    public let alt: String
}

public struct StoryNode: Codable, Identifiable, Sendable {
    public let id: String
    public let act: String
    public let title: String
    public let paragraphs: [String]
    public let conditionalParagraphs: [ConditionalParagraph]?
    public let choices: [StoryChoice]?
    public let ending: StoryEnding?
    public let illustration: StoryIllustration?

    public func visibleParagraphs(stats: AdventureStats, flags: Set<String>) -> [String] {
        paragraphs + (conditionalParagraphs ?? [])
            .filter { $0.requirement.isMet(stats: stats, flags: flags) }
            .map(\.text)
    }
}

public struct StoryBook: Codable, Sendable {
    public let id: String
    public let contentVersion: Int
    public let title: String
    public let subtitle: String
    public let start: String
    public let minimumDecisions: Int
    public let nodes: [StoryNode]

    public func node(_ id: String) -> StoryNode? { nodes.first { $0.id == id } }
    public var finalCount: Int { nodes.filter { $0.ending?.kind == .final }.count }
    public var detourCount: Int { nodes.filter { $0.ending?.kind == .detour }.count }
    public var illustratedCount: Int { nodes.filter { $0.illustration != nil }.count }
}

public struct AdventureListing: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let filename: String
    public let contentVersion: Int
    public let title: String
    public let subtitle: String
    public let blurb: String
    public let genre: String
    public let symbol: String
    public let coverAsset: String?
    public let estimatedMinutes: Int
    /// Optional shelf label for large themed libraries, absent in older catalogs.
    public let collection: String?
}

public struct AdventureCatalog: Codable, Sendable {
    public let formatVersion: Int
    public let adventures: [AdventureListing]
}

public struct AdventureSnapshot: Codable, Equatable, Sendable {
    public let nodeID: String
    public let stats: AdventureStats
    public let flags: Set<String>
    public let history: [String]
    public let decisionCount: Int
    public let lastOutcome: String?
}

public struct AdventureProgress: Codable, Equatable, Sendable {
    public let version: Int
    public let bookID: String
    public let bookVersion: Int
    public var nodeID: String
    public var stats: AdventureStats
    public var flags: Set<String>
    public var history: [String]
    public var decisionCount: Int
    public var runDetoursTriggered: Int
    public var lastOutcome: String?
    public var rewindSnapshot: AdventureSnapshot?
    public var endingsFound: Set<String>
    public var detoursFound: Set<String>
    public var started: Bool

    public init(book: StoryBook, endingsFound: Set<String> = [], detoursFound: Set<String> = []) {
        version = 2
        bookID = book.id
        bookVersion = book.contentVersion
        nodeID = book.start
        stats = AdventureStats()
        flags = []
        history = [book.start]
        decisionCount = 0
        runDetoursTriggered = 0
        lastOutcome = nil
        rewindSnapshot = nil
        self.endingsFound = endingsFound
        self.detoursFound = detoursFound
        started = false
    }

    public var snapshot: AdventureSnapshot {
        AdventureSnapshot(nodeID: nodeID, stats: stats, flags: flags,
                          history: history, decisionCount: decisionCount,
                          lastOutcome: lastOutcome)
    }
}

public enum StoryError: Error, Equatable, LocalizedError {
    case invalidBook(String)
    case unknownChoice
    case lockedChoice
    case notADetour
    case missingResource

    public var errorDescription: String? {
        switch self {
        case .invalidBook(let message): return "Invalid adventure: \(message)"
        case .unknownChoice: return "That choice doesn't exist here."
        case .lockedChoice: return "That choice isn't available yet."
        case .notADetour: return "Only short detours can be rewound."
        case .missingResource: return "The adventure could not be loaded."
        }
    }
}
