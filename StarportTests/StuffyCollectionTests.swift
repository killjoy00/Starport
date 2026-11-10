import XCTest
@testable import StarportCore

final class StuffyCollectionTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    private func data(_ name: String) throws -> Data {
        try Data(contentsOf: root.appendingPathComponent("StuffyLand/Content/\(name).json"))
    }

    func testEveryPublishedStoryDecodesWithTheActualAppModels() throws {
        let catalog = try JSONDecoder().decode(AdventureCatalog.self, from: data("catalog"))
        try StoryLoader.validateCatalog(catalog)
        XCTAssertEqual(catalog.adventures.count, 14)
        XCTAssertEqual(catalog.adventures.filter { $0.format == .reader }.count, 11)
        XCTAssertEqual(catalog.adventures.filter { $0.format == .adventure }.count, 3)
        XCTAssertFalse(catalog.adventures.contains { $0.id == "stuffy-bell" || $0.id == "stuffy-reader-sample" })
        for entry in catalog.adventures {
            XCTAssertNotNil(entry.editorialNote)
            if entry.format == .reader {
                let book = try StoryLoader.decodeReader(data(entry.filename))
                XCTAssertEqual(book.id, entry.id)
                XCTAssertEqual(book.contentVersion, entry.contentVersion)
                XCTAssertNotNil(book.editorialNote)
            } else {
                let book = try StoryLoader.decode(data(entry.filename))
                XCTAssertEqual(book.id, entry.id)
                XCTAssertEqual(book.finalCount, 5)
                XCTAssertEqual(book.detourCount, 10)
            }
        }
    }

    func testSundaeSwitchIllustratesExactlyHalfOfItsMainScenes() throws {
        let book = try StoryLoader.decode(data("sundae_switch"))
        let mainScenes = book.nodes.filter { $0.ending == nil }
        let sceneArt = mainScenes.compactMap { $0.illustration?.asset }
        XCTAssertEqual(mainScenes.count, 18)
        XCTAssertEqual(sceneArt.count, 9)
        XCTAssertEqual(Set(sceneArt).count, 9)
        XCTAssertEqual(book.finalCount, 5)
        XCTAssertEqual(book.detourCount, 10)
        XCTAssertGreaterThanOrEqual(book.minimumDecisions, 7)
    }

    func testOriginalGiggleGamesSurvivesPaginationVerbatim() throws {
        let original = try String(contentsOf: root.appendingPathComponent("StuffyLand/Editorial/source/giggle_games.txt"), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n\n")
        let book = try StoryLoader.decodeReader(data("giggle_games"))
        XCTAssertEqual(book.title, original.first)
        XCTAssertEqual(book.pages.flatMap(\.paragraphs), Array(original.dropFirst()))
    }

    func testAllAdventuresCanReachEveryEndingAndRewindEveryDetour() throws {
        for filename in ["pillow_fort", "snore_snatcher", "sundae_switch"] {
            let book = try StoryLoader.decode(data(filename))
            let relevantFlags = Set(book.nodes.flatMap { $0.choices ?? [] }
                .flatMap { $0.requirements ?? [] }.compactMap(\.flag))
            var pending = [try AdventureEngine(book: book)]
            var seen = Set<String>()
            var finals = Set<String>()
            var detours = Set<String>()
            while let engine = pending.popLast() {
                let p = engine.progress
                let key = "\(p.nodeID)|\(p.stats.clues)|\(p.stats.power)|\(p.stats.trust)|\(p.flags.intersection(relevantFlags).sorted())"
                guard seen.insert(key).inserted else { continue }
                if let ending = engine.node.ending {
                    if ending.kind == .final {
                        finals.insert(ending.id)
                        XCTAssertGreaterThanOrEqual(p.decisionCount, book.minimumDecisions)
                        let saved = try engine.encodedProgress()
                        let restored = try AdventureEngine(book: book, restored: saved)
                        XCTAssertEqual(restored.progress, engine.progress)
                    }
                    continue
                }
                let available = engine.choices.filter { $0.isAvailable(stats: p.stats, flags: p.flags) }
                XCTAssertFalse(available.isEmpty, "A playable scene must have an available continuation")
                for choice in available {
                    var next = engine
                    try next.choose(choice.id)
                    if next.isDetour {
                        detours.insert(next.node.ending!.id)
                        try next.rewindDetour()
                        XCTAssertEqual(next.progress.nodeID, p.nodeID)
                        XCTAssertEqual(next.progress.stats, p.stats)
                        XCTAssertEqual(next.progress.flags, p.flags)
                        XCTAssertEqual(next.progress.decisionCount, p.decisionCount)
                    } else {
                        pending.append(next)
                    }
                }
                XCTAssertLessThan(seen.count, 100_000)
            }
            XCTAssertEqual(finals, Set((1...5).map { "final_\($0)" }))
            XCTAssertEqual(detours.count, 10)
        }
    }

    func testSundaeEndingMemoriesAndClueBadgesAreAdventureSpecific() throws {
        let book = try StoryLoader.decode(data("sundae_switch"))
        var engine = try AdventureEngine(book: book)
        while !engine.isComplete {
            let candidates = engine.choices.filter {
                $0.isAvailable(stats: engine.progress.stats, flags: engine.progress.flags)
                    && book.node($0.to)?.ending?.kind != .detour
            }
            let selected = try XCTUnwrap(candidates.first)
            try engine.choose(selected.id)
        }
        let expected = "sundae_ending_\(engine.node.ending!.rank!)"
        let earned = AchievementCatalog.unlockedBy(engine, event: .choice, stuffyLand: true)
        XCTAssertTrue(earned.contains(expected))
        XCTAssertFalse(earned.contains(where: { $0.hasPrefix("snore_ending_") }))
        XCTAssertFalse(earned.contains(where: { $0.hasPrefix("pillow_ending_") }))
    }

    func testEndingMemoriesAreScopedToTheirAdventure() throws {
        var pillow = try AdventureEngine(book: StoryLoader.decode(data("pillow_fort")))
        while !pillow.isComplete {
            let available = pillow.choices.filter { $0.isAvailable(stats: pillow.progress.stats, flags: pillow.progress.flags) }
            let selected = try XCTUnwrap(available.first)
            try pillow.choose(selected.id)
        }
        let earned = AchievementCatalog.unlockedBy(pillow, event: .choice, stuffyLand: true)
        XCTAssertTrue(earned.contains("pillow_ending_1"))
        XCTAssertFalse(earned.contains("snore_ending_1"))
        XCTAssertFalse(earned.contains("bell_ending_1"))
    }
}
