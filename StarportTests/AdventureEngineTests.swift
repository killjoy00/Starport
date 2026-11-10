import XCTest
@testable import StarportCore

final class AdventureEngineTests: XCTestCase {
    private func story() throws -> StoryBook {
        try StoryLoader.load(filename: "first_signal")
    }

    func testAdventureLibraryAndExpandedStory() throws {
        let catalog = try StoryLoader.loadCatalog()
        XCTAssertEqual(catalog.formatVersion, 1)
        XCTAssertEqual(catalog.adventures.count, 2)
        let listing = try XCTUnwrap(catalog.adventures.first)
        let book = try story()
        XCTAssertEqual(listing.id, book.id)
        XCTAssertEqual(listing.contentVersion, 3)
        XCTAssertEqual(book.contentVersion, listing.contentVersion)
        XCTAssertEqual(book.nodes.count, 81)
        XCTAssertEqual(book.finalCount, 5)
        XCTAssertEqual(book.detourCount, 12)
        XCTAssertEqual(book.illustratedCount, 33)
        let scenes = book.nodes.filter { $0.ending == nil }
        XCTAssertEqual(scenes.count, 64)
        XCTAssertGreaterThanOrEqual(scenes.filter { $0.illustration != nil }.count * 3, scenes.count)
        XCTAssertEqual(book.nodes.flatMap { $0.choices ?? [] }.count, 143)
        XCTAssertEqual(book.minimumDecisions, 30)
        XCTAssertNoThrow(try StoryValidator.validate(book))

        // Readers spend time with characters and settings now, not only with
        // two short sentences before another button.
        let lengths = scenes.map { $0.paragraphs.joined(separator: " ").split(whereSeparator: \.isWhitespace).count }
        let words = book.nodes.flatMap(\.paragraphs).joined(separator: " ").split(whereSeparator: \.isWhitespace).count
        XCTAssertGreaterThan(words, 10_000)
        XCTAssertGreaterThan(try XCTUnwrap(lengths.max()) - XCTUnwrap(lengths.min()), 100)
        XCTAssertGreaterThanOrEqual(scenes.filter { $0.paragraphs.count >= 4 }.count, 25)
    }

    func testStoryHasSeparateBranchesBeforeTheLastChoice() throws {
        let book = try story()
        let distinct = book.nodes.filter { node in
            let targets = Set((node.choices ?? []).compactMap { choice -> String? in
                if book.node(choice.to)?.ending?.kind == .detour { return nil }
                return choice.to
            })
            return targets.count > 1
        }
        let expected = ["s06","s12","s18","s24","s30","b21","b27","decision"]
        for id in expected {
            XCTAssertTrue(distinct.contains(where: { $0.id == id }),
                          "The reader must be able to change locations at \(id).")
        }
        XCTAssertGreaterThanOrEqual(distinct.count, 8)

        let first = try XCTUnwrap(book.node("s06"))
        let destinations = Set((first.choices ?? []).map(\.to))
        XCTAssertTrue(destinations.contains("s07"))
        XCTAssertTrue(destinations.contains("b07"))
        XCTAssertNotEqual(try XCTUnwrap(book.node("s08")).title,
                          try XCTUnwrap(book.node("b08")).title)
    }

    func testEveryFinalEndingIsReachableThroughA37DecisionRoute() throws {
        struct Key: Hashable {
            let nodeID: String
            let clues: Int
            let power: Int
            let trust: Int
            let relevantFlags: Set<String>
        }
        let book = try story()
        let relevantFlags = Set(book.nodes.flatMap { node in
            (node.choices ?? []).flatMap { choice in
                (choice.requirements ?? []).compactMap(\.flag)
            }
        })
        var queue = [try AdventureEngine(book: book)]
        var seen = Set<Key>()
        var endings = Set<String>()
        var visitedDecisionScenes = Set<String>()
        var explored = 0

        while let game = queue.popLast() {
            let p = game.progress
            let key = Key(nodeID: p.nodeID, clues: p.stats.clues,
                          power: p.stats.power, trust: p.stats.trust,
                          relevantFlags: p.flags.intersection(relevantFlags))
            guard seen.insert(key).inserted else { continue }
            explored += 1

            if let ending = game.node.ending {
                XCTAssertEqual(ending.kind, .final)
                XCTAssertEqual(p.decisionCount, 37)
                XCTAssertGreaterThanOrEqual(p.decisionCount, book.minimumDecisions)
                endings.insert(ending.id)
                continue
            }

            visitedDecisionScenes.insert(p.nodeID)
            for choice in game.choices where choice.isAvailable(stats: p.stats, flags: p.flags) {
                if book.node(choice.to)?.ending?.kind == .detour { continue }
                var next = game
                try next.choose(choice.id)
                queue.append(next)
            }
            XCTAssertLessThan(explored, 50_000, "Unexpected branch-state explosion.")
        }
        XCTAssertEqual(endings, Set((1...5).map { "final_\($0)" }))
        XCTAssertEqual(visitedDecisionScenes.count, 64)
    }

    func testEarlyRouteCommitmentsCanPermanentlyCloseOutcomes() throws {
        let book = try story()
        var engineer = try AdventureEngine(book: book)
        for i in 1...36 {
            try engineer.choose(String(format: "s%02d_1", i))
        }
        XCTAssertEqual(engineer.node.id, "decision")
        let safe = try XCTUnwrap(engineer.choices.first { $0.id == "decide_safe" })
        XCTAssertFalse(safe.isAvailable(stats: engineer.progress.stats, flags: engineer.progress.flags))
        XCTAssertTrue((safe.lockedReason(stats: engineer.progress.stats, flags: engineer.progress.flags) ?? "")
                      .contains("Juno"))
        XCTAssertFalse(engineer.progress.flags.contains("pilot_path"))

        var pilot = try AdventureEngine(book: book)
        for i in 1...11 {
            try pilot.choose(String(format: "s%02d_1", i))
        }
        try pilot.choose("s12_2")
        XCTAssertEqual(pilot.node.id, "b13")
        for i in 13...17 {
            try pilot.choose(String(format: "b%02d_1", i))
        }
        XCTAssertEqual(pilot.node.id, "s18")
        XCTAssertFalse(pilot.progress.history.contains("s15"))
        XCTAssertTrue(pilot.progress.flags.contains("pilot_path"))
        for i in 18...36 {
            try pilot.choose(String(format: "s%02d_1", i))
        }
        XCTAssertTrue(try XCTUnwrap(pilot.choices.first { $0.id == "decide_safe" })
                      .isAvailable(stats: pilot.progress.stats, flags: pilot.progress.flags))
        try pilot.choose("decide_safe")
        XCTAssertEqual(pilot.node.ending?.rank, 2)

        var echo = try AdventureEngine(book: book)
        for i in 1...17 {
            try echo.choose(String(format: "s%02d_1", i))
        }
        try echo.choose("s18_2")
        for i in 19...23 {
            try echo.choose(String(format: "b%02d_1", i))
        }
        for i in 24...36 {
            try echo.choose(String(format: "s%02d_1", i))
        }
        XCTAssertEqual(echo.node.id, "decision")
        let best = try XCTUnwrap(echo.choices.first { $0.id == "decide_best" })
        XCTAssertFalse(best.isAvailable(stats: echo.progress.stats, flags: echo.progress.flags))
        XCTAssertTrue((best.lockedReason(stats: echo.progress.stats, flags: echo.progress.flags) ?? "")
                      .contains("live channel"))
        XCTAssertFalse(echo.progress.flags.contains("radio_path"))
    }

    func testFalseEndingsRewindWithoutLosingProgress() throws {
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

    func testPermanentEndRequiresStartingOver() throws {
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

    func testRevisedStoryRestartsOldRunButKeepsDiscoveredEndings() throws {
        let book = try story()
        let old = AdventureProgress(book: book,
                                    endingsFound: ["final_2", "final_5"],
                                    detoursFound: ["detour_1"])
        let data = try JSONEncoder().encode(old)
        var values = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        values["bookVersion"] = 2
        values["nodeID"] = "s18"
        values["decisionCount"] = 17
        let oldSave = try JSONSerialization.data(withJSONObject: values)
        let updated = try AdventureEngine(book: book, restored: oldSave)
        XCTAssertEqual(updated.progress.bookVersion, 3)
        XCTAssertEqual(updated.progress.nodeID, "s01")
        XCTAssertEqual(updated.progress.decisionCount, 0)
        XCTAssertEqual(updated.progress.endingsFound, ["final_2", "final_5"])
        XCTAssertEqual(updated.progress.detoursFound, ["detour_1"])
    }

    func testCatalogRejectsUnsafePaths() {
        XCTAssertFalse(StoryLoader.isSafeFilename("../escape"))
        XCTAssertFalse(StoryLoader.isSafeFilename("https://example.org/a"))
        XCTAssertFalse(StoryLoader.isSafeFilename("NEW.json"))
        XCTAssertTrue(StoryLoader.isSafeFilename("first_signal"))
    }

    func testAllPermanentEndingsAreUniquelyRanked() throws {
        let ranks = try story().nodes.compactMap { $0.ending?.rank }
        XCTAssertEqual(ranks.sorted(), Array(1...5))
    }

    func testAchievementsSurviveNewRuns() throws {
        XCTAssertGreaterThanOrEqual(AchievementCatalog.all.count, 25)
        XCTAssertEqual(Set(AchievementCatalog.all.map(\.id)).count, AchievementCatalog.all.count)
        var game = try AdventureEngine(book: story())
        XCTAssertFalse(AchievementCatalog.unlockedBy(game, event: .newRun).contains("first_choice"))
        try game.choose("s01_1")
        XCTAssertTrue(AchievementCatalog.unlockedBy(game, event: .choice).contains("first_choice"))
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
