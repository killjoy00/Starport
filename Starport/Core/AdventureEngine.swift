import Foundation

/// Pure game rules with no network, UI, or storage dependency.
public struct AdventureEngine {
    public let book: StoryBook
    public private(set) var progress: AdventureProgress

    public init(book: StoryBook, restored: Data? = nil) throws {
        try StoryValidator.validate(book)
        self.book = book

        if let restored,
           let saved = try? JSONDecoder().decode(AdventureProgress.self, from: restored),
           saved.version == 1,
           book.node(saved.nodeID) != nil {
            progress = saved
        } else {
            progress = AdventureProgress(start: book.start)
        }
    }

    public var node: StoryNode {
        // Story validation plus the restored-save check guarantee this exists.
        book.node(progress.nodeID)!
    }

    public var isComplete: Bool { node.ending != nil }
    public var choices: [StoryChoice] { node.choices ?? [] }

    public mutating func begin() {
        progress.started = true
    }

    public mutating func choose(_ choiceID: String) throws {
        guard let choice = choices.first(where: { $0.id == choiceID }) else {
            throw StoryError.unknownChoice
        }
        guard choice.isAvailable(stats: progress.stats, flags: progress.flags) else {
            throw StoryError.lockedChoice
        }
        for effect in choice.effects ?? [] {
            if let stat = effect.stat, let delta = effect.delta {
                progress.stats[stat] += delta
            }
            if let flag = effect.flag {
                progress.flags.insert(flag)
            }
        }
        progress.nodeID = choice.to
        progress.history.append(choice.to)
        progress.started = true
        if let ending = node.ending {
            progress.endingsFound.insert(ending.id)
        }
    }

    /// Keep discovered endings, but reset the current run.
    public mutating func restart() {
        progress = AdventureProgress(start: book.start, endingsFound: progress.endingsFound)
        progress.started = true
    }

    public func encodedProgress() throws -> Data {
        try JSONEncoder().encode(progress)
    }
}

public enum StoryValidator {
    public static func validate(_ book: StoryBook) throws {
        let ids = book.nodes.map(\.id)
        let known = Set(ids)
        guard !book.id.isEmpty, !book.title.isEmpty,
              ids.count == known.count, !ids.isEmpty, known.contains(book.start) else {
            throw StoryError.invalidBook("Duplicate or missing scene IDs, title, or start.")
        }

        var endingIDs: Set<String> = []
        for node in book.nodes {
            guard !node.title.isEmpty, !node.paragraphs.isEmpty else {
                throw StoryError.invalidBook("Scene \(node.id) is missing its text.")
            }
            let choices = node.choices ?? []
            if let ending = node.ending {
                guard choices.isEmpty, endingIDs.insert(ending.id).inserted else {
                    throw StoryError.invalidBook("Ending \(node.id) repeats an ID or has choices.")
                }
            } else if choices.isEmpty {
                throw StoryError.invalidBook("Scene \(node.id) has no next step.")
            }
            guard Set(choices.map(\.id)).count == choices.count else {
                throw StoryError.invalidBook("Scene \(node.id) repeats a choice ID.")
            }
            for choice in choices {
                guard known.contains(choice.to), !choice.label.isEmpty else {
                    throw StoryError.invalidBook("Broken choice \(choice.id) in \(node.id).")
                }
                for requirement in choice.requirements ?? [] {
                    guard (requirement.stat != nil || requirement.flag != nil),
                          !requirement.hint.isEmpty,
                          (requirement.stat != nil) == (requirement.atLeast != nil) else {
                        throw StoryError.invalidBook("Invalid requirement on \(choice.id).")
                    }
                }
                for effect in choice.effects ?? [] {
                    guard (effect.stat != nil && effect.delta != nil) ||
                          (effect.flag != nil && effect.stat == nil && effect.delta == nil) else {
                        throw StoryError.invalidBook("Invalid effect on \(choice.id).")
                    }
                }
            }
        }
        guard !endingIDs.isEmpty else {
            throw StoryError.invalidBook("The story needs at least one ending.")
        }

        var seen: Set<String> = [book.start]
        var queue = [book.start]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            for choice in book.node(current)?.choices ?? [] where seen.insert(choice.to).inserted {
                queue.append(choice.to)
            }
        }
        guard seen == known else {
            throw StoryError.invalidBook("Unreachable scenes: \(known.subtracting(seen).sorted().joined(separator: ", ")).")
        }
    }
}
