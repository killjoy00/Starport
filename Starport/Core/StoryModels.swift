import Foundation

public enum StoryStat: String, Codable, CaseIterable, Sendable {
    case clues
    case power
    case trust

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
        let statOK = stat.map { stats[$0] >= (atLeast ?? 0) } ?? true
        let flagOK = flag.map { flags.contains($0) } ?? true
        return statOK && flagOK
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

public struct StoryEnding: Codable, Sendable {
    public let id: String
    public let title: String
    public let note: String
}

public struct StoryNode: Codable, Identifiable, Sendable {
    public let id: String
    public let act: String
    public let title: String
    public let paragraphs: [String]
    public let choices: [StoryChoice]?
    public let ending: StoryEnding?
}

public struct StoryBook: Codable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let start: String
    public let nodes: [StoryNode]

    public func node(_ id: String) -> StoryNode? {
        nodes.first { $0.id == id }
    }
}

public struct AdventureProgress: Codable, Equatable, Sendable {
    public let version: Int
    public var nodeID: String
    public var stats: AdventureStats
    public var flags: Set<String>
    public var history: [String]
    public var endingsFound: Set<String>
    public var started: Bool

    public init(start: String, endingsFound: Set<String> = []) {
        version = 1
        nodeID = start
        stats = AdventureStats()
        flags = []
        history = [start]
        self.endingsFound = endingsFound
        started = false
    }
}

public enum StoryError: Error, Equatable, LocalizedError {
    case invalidBook(String)
    case unknownChoice
    case lockedChoice
    case missingResource

    public var errorDescription: String? {
        switch self {
        case .invalidBook(let message): return "Invalid adventure: \(message)"
        case .unknownChoice: return "That choice doesn't exist here."
        case .lockedChoice: return "That choice isn't available yet."
        case .missingResource: return "The adventure could not be loaded."
        }
    }
}
