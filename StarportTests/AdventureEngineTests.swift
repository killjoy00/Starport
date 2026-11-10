import XCTest
@testable import StarportCore

final class AdventureEngineTests: XCTestCase {
    private func story() throws -> StoryBook {
        try StoryLoader.load(filename: "first_signal")
    }

    func testAdventureLibraryAndStoryShape() throws {
        let catalog = try StoryLoader.loadCatalog()
        XCTAssertEqual(catalog.formatVersion, 1)
        XCTAssertEqual(catalog.adventures.count, 1)
        let listing = try XCTUnwrap(catalog.adventures.first)
        let book = try story()
        XCTAssertEqual(listing.id, book.id)
        XCTAssertEqual(listing.contentVersion, book.contentVersion)
        XCTAssertEqual(book.nodes.count, 54)
        XCTAssertEqual(book.finalCount, 5)
        XCTAssertEqual(book.detourCount, 12)
        XCTAssertEqual(book.nodes.flatMap { $0.choices ?? [] }.count, 89)
        XCTAssertEqual(book.minimumDecisions, 30)
        XCTAssertNoThrow(try StoryValidator.validate(book))
    }

    func testEveryPermanentEndingIsReachableAfter37Decisions() throws {
        struct Key: Hashable {
            let scene: String
            let clues: Int
            let power: Int
            let trust: Int
            let handshake: Bool
        }

        var pending = [try AdventureEngine(book: story())]
        var seen = Set<Key>()
        var endings: Set<String> = []
        var explored = 0
        while let current = pending.popLast() {
            let p = current.progress
            let key = Key(scene: p.nodeID, clues: p.stats.clues,
                          power: p.stats.power, trust: p.stats.trust,
                          handshake: p.flags.contains("handshake"))
            guard seen.insert(key).inserted else { continue }
            explored += 1

            if let ending = current.node.ending {
                XCTAssertEqual(ending.kind, .final)
                XCTAssertEqual(p.decisionCount, 37)
                XCTAssertGreaterThanOrEqual(p.decisionCount, current.book.minimumDecisions)
                endings.insert(ending.id)
                continue
            }

            for choice in current.choices where choice.isAvailable(stats: p.stats, flags: p.flags) {
                // Detours are intentionally quick recoverable branches, not permanent endings.
                if current.book.node(choice.to)?.ending?.kind == .detour { continue }
                var next = current
                try next.choose(choice.id)
                pending.append(next)
            }
            XCTAssertLessThan(explored, 20000, "Unexpected explosion in story states.")
        }
        XCTAssertEqual(endings, Set((1...5).map { "final_\($0)" }))
    }

    func testTwelveFalseEndingsCanBeUndoneWithoutLosingProgress() throws {
        var game = try AdventureEngine(book: story())
        try game.choose("s01_1")
        try game.choose("s02_1")
        let before = game.progress
        try game.choose("s03_detour")
        XCTAssertTrue(game.isDetour)
        XCTAssertFalse(game.isComplete)
        XCTAssertEqual(game.progress.decisionCount, 3)
        XCTAssertEqual(game.progress.detoursFound, Set(["detour_1"]))
        XCTAssertEqual(game.progress.runDetoursTriggered, 1)
        try game.rewindDetour()
        XCTAssertEqual(game.progress.nodeID, "s03")
        XCTAssertEqual(game.progress.decisionCount, before.decisionCount)
        XCTAssertEqual(game.progress.stats, before.stats)
        XCTAssertEqual(game.progress.flags, before.flags)
        XCTAssertEqual(game.progress.detoursFound, Set(["detour_1"]))
        XCTAssertEqual(game.progress.runDetoursTriggered, 1)
        try game.choose("s03_1")
        XCTAssertEqual(game.progress.decisionCount, 3)
        XCTAssertThrowsError(try game.rewindDetour())
    }

    func testFinalEndRequiresStartingOver() throws {
        var game = try AdventureEngine(book: story())
        for i in 1...36 {
            try game.choose(String(format: "s%02d_1", i))
        }
        try game.choose("decide_risk")
        XCTAssertTrue(game.isComplete)
        XCTAssertEqual(game.progress.decisionCount, 37)
        XCTAssertEqual(game.progress.endingsFound, Set(["final_5"]))
        XCTAssertThrowsError(try game.rewindDetour()) { error in
            XCTAssertEqual(error as? StoryError, .notADetour)
        }
        XCTAssertThrowsError(try game.choose("decide_safe"))
        let saved = try game.encodedProgress()
        var restored = try AdventureEngine(book: story(), restored: saved)
        XCTAssertTrue(restored.isComplete)
        restored.restart()
        XCTAssertEqual(restored.progress.nodeID, "s01")
        XCTAssertEqual(restored.progress.decisionCount, 0)
        XCTAssertEqual(restored.progress.endingsFound, Set(["final_5"]))
        XCTAssertEqual(restored.progress.runDetoursTriggered, 0)
    }

    func testCatalogDoesNotAcceptUnsafePaths() {
        XCTAssertFalse(StoryLoader.isSafeFilename("../escape"))
        XCTAssertFalse(StoryLoader.isSafeFilename("https://example.org/a"))
        XCTAssertFalse(StoryLoader.isSafeFilename("NEW.json"))
        XCTAssertTrue(StoryLoader.isSafeFilename("first_signal"))
    }

    func testAllPermanentEndingsAreUniquelyRanked() throws {
        let ranks = try story().nodes.compactMap { $0.ending?.rank }
        XCTAssertEqual(ranks.sorted(), Array(1...5))
    }

    func testAchievementsIncludeFiveEndingsAndExploration() throws {
        XCTAssertGreaterThanOrEqual(AchievementCatalog.all.count, 25)
        XCTAssertEqual(Set(AchievementCatalog.all.map(\.id)).count, AchievementCatalog.all.count)

        var game = try AdventureEngine(book: story())
        XCTAssertFalse(AchievementCatalog.unlockedBy(game, event: .newRun).contains("first_choice"))
        try game.choose("s01_1")
        let unlocked = AchievementCatalog.unlockedBy(game, event: .choice)
        XCTAssertTrue(unlocked.contains("first_choice"))
        XCTAssertFalse(unlocked.contains("ending_1"))

        try game.choose("s02_1")
        try game.choose("s03_detour")
        XCTAssertTrue(AchievementCatalog.unlockedBy(game, event: .choice).contains("first_detour"))
        try game.rewindDetour()
        XCTAssertTrue(AchievementCatalog.unlockedBy(game, event: .rewind).contains("first_rewind"))
    }

    func testCorruptSaveResetsCleanly() throws {
        let book = try story()
        let game = try AdventureEngine(book: book, restored: Data("bad JSON".utf8))
        XCTAssertEqual(game.progress.nodeID, book.start)
        XCTAssertFalse(game.progress.started)
    }
}
