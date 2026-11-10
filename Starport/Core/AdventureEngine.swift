import Foundation

/// Pure, deterministic story engine. Detours can be undone; final endings cannot.
public struct AdventureEngine {
    public let book: StoryBook
    public private(set) var progress: AdventureProgress

    public init(book: StoryBook, restored: Data? = nil) throws {
        try StoryValidator.validate(book)
        self.book = book
        if let restored,
           let saved = try? JSONDecoder().decode(AdventureProgress.self, from: restored),
           saved.version == 2, saved.bookID == book.id {
            if saved.bookVersion == book.contentVersion,
               book.node(saved.nodeID) != nil,
               saved.history.first == book.start {
                progress = saved
            } else if saved.bookVersion != book.contentVersion {
                // A new version can move or remove scenes. Restart the active
                // route rather than restoring an impossible branch, but keep
                // every discovered ending/detour that still exists in the book.
                let finalIDs = Set(book.nodes.compactMap { node in
                    node.ending?.kind == .final ? node.ending?.id : nil
                })
                let detourIDs = Set(book.nodes.compactMap { node in
                    node.ending?.kind == .detour ? node.ending?.id : nil
                })
                progress = AdventureProgress(
                    book: book,
                    endingsFound: saved.endingsFound.intersection(finalIDs),
                    detoursFound: saved.detoursFound.intersection(detourIDs))
            } else {
                progress = AdventureProgress(book: book)
            }
        } else {
            progress = AdventureProgress(book: book)
        }
    }

    public var node: StoryNode { book.node(progress.nodeID)! }
    public var isComplete: Bool { node.ending?.kind == .final }
    public var isDetour: Bool { node.ending?.kind == .detour }
    public var choices: [StoryChoice] { node.choices ?? [] }

    public mutating func begin() { progress.started = true }

    public mutating func choose(_ choiceID: String) throws {
        guard let choice = choices.first(where: { $0.id == choiceID }) else {
            throw StoryError.unknownChoice
        }
        guard choice.isAvailable(stats: progress.stats, flags: progress.flags) else {
            throw StoryError.lockedChoice
        }
        let before = progress.snapshot
        for effect in choice.effects ?? [] {
            if let stat = effect.stat, let delta = effect.delta {
                progress.stats[stat] += delta
            }
            if let flag = effect.flag { progress.flags.insert(flag) }
        }
        progress.nodeID = choice.to
        progress.history.append(choice.to)
        progress.decisionCount += 1
        progress.lastOutcome = choice.outcome
        progress.rewindSnapshot = nil
        progress.started = true

        if let ending = node.ending {
            if ending.kind == .detour {
                progress.rewindSnapshot = before
                progress.runDetoursTriggered += 1
                progress.detoursFound.insert(ending.id)
            } else {
                progress.endingsFound.insert(ending.id)
            }
        }
    }

    /// One-tap undo restores exactly the stats, flags and decision count before a detour.
    /// Discovered detours remain in the collection; no choices can be farmed for points.
    public mutating func rewindDetour() throws {
        guard isDetour, let before = progress.rewindSnapshot else {
            throw StoryError.notADetour
        }
        progress.nodeID = before.nodeID
        progress.stats = before.stats
        progress.flags = before.flags
        progress.history = before.history
        progress.decisionCount = before.decisionCount
        progress.lastOutcome = before.lastOutcome
        progress.rewindSnapshot = nil
        progress.started = true
    }

    /// Final endings always require a new run. Discovered endings and detours survive.
    public mutating func restart() {
        progress = AdventureProgress(book: book,
            endingsFound: progress.endingsFound,
            detoursFound: progress.detoursFound)
        progress.started = true
    }

    public func encodedProgress() throws -> Data { try JSONEncoder().encode(progress) }
}

public enum StoryValidator {
    public static func validate(_ book: StoryBook) throws {
        let ids = book.nodes.map(\.id)
        let known = Set(ids)
        guard !book.id.isEmpty, !book.title.isEmpty, book.contentVersion > 0,
              ids.count == known.count, !ids.isEmpty,
              known.contains(book.start), book.minimumDecisions >= 0 else {
            throw StoryError.invalidBook("Missing/duplicate scene IDs, version or start.")
        }

        var endingIDs: Set<String> = []
        var finalRanks: Set<Int> = []
        var finalNodes: Set<String> = []
        var detourNodes: Set<String> = []
        for node in book.nodes {
            if let art = node.illustration {
                guard StoryLoader.isSafeFilename(art.asset),
                      !art.alt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw StoryError.invalidBook("Invalid illustration on \(node.id).")
                }
            }
            guard !node.title.isEmpty, !node.paragraphs.isEmpty else {
                throw StoryError.invalidBook("Scene \(node.id) has no text.")
            }
            let choices = node.choices ?? []
            if let ending = node.ending {
                guard choices.isEmpty, endingIDs.insert(ending.id).inserted else {
                    throw StoryError.invalidBook("Ending \(node.id) repeats an ID or has choices.")
                }
                if ending.kind == .final {
                    guard let rank = ending.rank, rank > 0,
                          finalRanks.insert(rank).inserted else {
                        throw StoryError.invalidBook("Missing or repeated final rank.")
                    }
                    finalNodes.insert(node.id)
                } else {
                    guard ending.rank == nil else {
                        throw StoryError.invalidBook("Detours cannot have ranks.")
                    }
                    detourNodes.insert(node.id)
                }
            } else if choices.count < 2 {
                throw StoryError.invalidBook("Scene \(node.id) must offer at least two decisions.")
            }
            guard Set(choices.map(\.id)).count == choices.count else {
                throw StoryError.invalidBook("Repeated choice in \(node.id).")
            }
            for choice in choices {
                guard known.contains(choice.to), !choice.label.isEmpty else {
                    throw StoryError.invalidBook("Broken choice \(choice.id) in \(node.id).")
                }
                for requirement in choice.requirements ?? [] {
                    guard !requirement.hint.isEmpty,
                          (requirement.stat != nil) == (requirement.atLeast != nil),
                          requirement.stat != nil || requirement.flag != nil else {
                        throw StoryError.invalidBook("Invalid requirement \(choice.id).")
                    }
                }
                for effect in choice.effects ?? [] {
                    guard (effect.stat != nil && effect.delta != nil && effect.flag == nil) ||
                          (effect.flag != nil && effect.stat == nil && effect.delta == nil) else {
                        throw StoryError.invalidBook("Invalid effect \(choice.id).")
                    }
                }
            }
        }
        guard !finalNodes.isEmpty else { throw StoryError.invalidBook("No final endings.") }

        var reachable: Set<String> = [book.start]
        var queue = [book.start]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            for choice in book.node(current)?.choices ?? [] where reachable.insert(choice.to).inserted {
                queue.append(choice.to)
            }
        }
        guard reachable == known else {
            throw StoryError.invalidBook("Unreachable: \(known.subtracting(reachable).sorted().joined(separator: ", ")).")
        }
        // The story must be acyclic. A player can rewind a detour, but no ending
        // can be reached by choosing a loop repeatedly to pad the decision count.
        var state: [String: Int] = [:]
        var minDepth: [String: Int] = [:]
        func shortest(_ id: String) throws -> Int {
            if state[id] == 1 { throw StoryError.invalidBook("Choice graph has a cycle.") }
            if let done = minDepth[id] { return done }
            state[id] = 1
            let node = book.node(id)!
            let depth: Int
            if node.ending != nil { depth = 0 }
            else {
                depth = 1 + (try (node.choices ?? []).map { try shortest($0.to) }.min() ?? 0)
            }
            state[id] = 2
            minDepth[id] = depth
            return depth
        }
        _ = try shortest(book.start)

        // Every *route* to a final ending must be long enough, not just the
        // shortest overall route (which may end at a deliberately short detour).
        var shortestArrival: [String: Int] = [book.start: 0]
        func visit(_ id: String) {
            let fromDepth = shortestArrival[id]!
            for choice in book.node(id)?.choices ?? [] {
                let nextDepth = fromDepth + 1
                if nextDepth < (shortestArrival[choice.to] ?? Int.max) {
                    shortestArrival[choice.to] = nextDepth
                    visit(choice.to)
                }
            }
        }
        visit(book.start)
        for id in finalNodes {
            guard (shortestArrival[id] ?? 0) >= book.minimumDecisions else {
                throw StoryError.invalidBook("Final \(id) occurs before \(book.minimumDecisions) decisions.")
            }
        }
        for id in detourNodes {
            guard (shortestArrival[id] ?? 0) > 0 else {
                throw StoryError.invalidBook("Detour \(id) has no rewind point.")
            }
        }
    }
}
