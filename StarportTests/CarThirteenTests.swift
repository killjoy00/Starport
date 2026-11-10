import XCTest
@testable import StarportCore

final class CarThirteenTests: XCTestCase {
    private func story() throws -> StoryBook {
        try StoryLoader.load(filename: "car_thirteen")
    }

    /// Plays forward, taking `prefer` choices when offered and otherwise the first open
    /// choice that is not a false ending and passes `allow`, until `stop` is reached.
    private func play(_ game: inout AdventureEngine, until stop: String, prefer: Set<String> = [],
                      allow: (StoryChoice) -> Bool = { _ in true }) throws {
        while game.progress.nodeID != stop {
            let p = game.progress
            let open = game.choices.filter {
                $0.isAvailable(stats: p.stats, flags: p.flags) &&
                game.book.node($0.to)?.ending?.kind != .detour && allow($0)
            }
            let pick = try XCTUnwrap(open.first { prefer.contains($0.id) } ?? open.first,
                                     "Stuck at \(p.nodeID)")
            try game.choose(pick.id)
        }
    }

    func testCatalogListingMatchesStory() throws {
        let catalog = try StoryLoader.loadCatalog()
        let listing = try XCTUnwrap(catalog.adventures.first { $0.id == "car-thirteen" })
        let book = try story()
        XCTAssertEqual(listing.filename, "car_thirteen")
        XCTAssertEqual(listing.contentVersion, book.contentVersion)
        XCTAssertEqual(listing.title, book.title)
        XCTAssertEqual(listing.coverAsset, "cover-car-thirteen")
        XCTAssertEqual(listing.format, .adventure)
    }

    func testStoryShape() throws {
        let book = try story()
        XCTAssertEqual(book.nodes.count, 91)
        XCTAssertEqual(book.finalCount, 7)
        XCTAssertEqual(book.detourCount, 12)
        XCTAssertEqual(book.minimumDecisions, 50)
        XCTAssertEqual(book.illustratedCount, 43)
        let scenes = book.nodes.filter { $0.ending == nil }
        XCTAssertEqual(scenes.count, 72)
        XCTAssertGreaterThanOrEqual(scenes.filter { $0.illustration != nil }.count * 3, scenes.count)
        XCTAssertNoThrow(try StoryValidator.validate(book))
        XCTAssertEqual(book.nodes.compactMap { $0.ending?.rank }.sorted(), Array(1...7))
    }

    /// Episode 01's achievements key off "final_N" and "detour_N" ending IDs.
    func testEndingIDsDoNotCollideWithEpisodeOne() throws {
        let first = try StoryLoader.load(filename: "first_signal")
        let firstIDs = Set(first.nodes.compactMap { $0.ending?.id })
        let ids = Set(try story().nodes.compactMap { $0.ending?.id })
        XCTAssertEqual(ids.count, 19)
        XCTAssertTrue(ids.isDisjoint(with: firstIDs))
    }

    /// A reader can never be stranded: every scene keeps one unlocked, non-detour choice.
    func testEverySceneHasAnUnlockedWayForward() throws {
        let book = try story()
        for node in book.nodes where node.ending == nil {
            let open = (node.choices ?? []).filter {
                ($0.requirements ?? []).isEmpty && book.node($0.to)?.ending?.kind != .detour
            }
            XCTAssertFalse(open.isEmpty, "Scene \(node.id) can lock the reader out.")
        }
    }

    func testEveryEndingIsReachableByRoutesOfDifferentLengths() throws {
        struct Key: Hashable {
            let scene: String
            let clues: Int
            let power: Int
            let trust: Int
            let gates: Set<String>
        }

        let book = try story()
        // Flags that some requirement checks can change which choices are open. The two
        // longer routes are tracked too, so every distinct route length is explored.
        let gateFlags = Set(book.nodes.flatMap { $0.choices ?? [] }
            .flatMap { $0.requirements ?? [] }.compactMap(\.flag))
            .union(["route_over", "route_lamp"])

        var pending = [try AdventureEngine(book: book)]
        var seen = Set<Key>()
        var lengths: [String: Set<Int>] = [:]
        while let current = pending.popLast() {
            let p = current.progress
            let key = Key(scene: p.nodeID, clues: p.stats.clues, power: p.stats.power,
                          trust: p.stats.trust, gates: p.flags.intersection(gateFlags))
            guard seen.insert(key).inserted else { continue }
            XCTAssertLessThan(seen.count, 600_000, "Unexpected explosion in story states.")

            if let ending = current.node.ending {
                XCTAssertEqual(ending.kind, .final)
                XCTAssertGreaterThanOrEqual(p.decisionCount, 50)
                lengths[ending.id, default: []].insert(p.decisionCount)
                continue
            }
            for choice in current.choices where choice.isAvailable(stats: p.stats, flags: p.flags) {
                if book.node(choice.to)?.ending?.kind == .detour { continue }
                var next = current
                try next.choose(choice.id)
                pending.append(next)
            }
        }
        XCTAssertEqual(Set(lengths.keys), Set((1...7).map { "car13_final_\($0)" }))
        let all = lengths.values.reduce(into: Set<Int>()) { $0.formUnion($1) }
        XCTAssertEqual(all.min(), 51)
        XCTAssertEqual(all.max(), 56)
        // The skiff endgame is longer than the others.
        XCTAssertEqual(lengths["car13_final_2"]?.min(), 54)
        XCTAssertEqual(lengths["car13_final_7"]?.min(), 51)
    }

    /// Each endgame owns its endings: choosing one closes the others for that run.
    func testEndgamesLeadToDifferentEndings() throws {
        let book = try story()
        var sources: [String: Set<String>] = [:]
        for node in book.nodes {
            for choice in node.choices ?? [] {
                if let ending = book.node(choice.to)?.ending, ending.kind == .final {
                    sources[ending.id, default: []].insert(node.id)
                }
            }
        }
        XCTAssertEqual(sources["car13_final_1"], ["decision_song"])
        XCTAssertEqual(sources["car13_final_2"], ["decision_skiff"])
        XCTAssertEqual(sources["car13_final_4"], ["decision_skiff"])
        XCTAssertEqual(sources["car13_final_3"], ["decision_song", "decision"])
        for rank in 5...7 {
            XCTAssertEqual(sources["car13_final_\(rank)"], ["decision"])
        }
    }

    func testStayingInsideTheTrainLocksOutTheSkiff() throws {
        var game = try AdventureEngine(book: story())
        // Under the floors, then the engine room: never outside with Wick.
        try play(&game, until: "s47", prefer: ["s20_1", "s36_1"])
        XCTAssertFalse(game.progress.flags.contains("roof_legs"))
        XCTAssertThrowsError(try game.choose("s47_2")) { error in
            XCTAssertEqual(error as? StoryError, .lockedChoice)
        }
        XCTAssertFalse(game.progress.history.contains("roof5"))
        XCTAssertFalse(game.progress.history.contains("lamp5"))
    }

    func testNeverLearningTheSongLocksOutTheBestEnding() throws {
        var game = try AdventureEngine(book: story())
        try play(&game, until: "s47") { choice in
            !(choice.effects ?? []).contains { $0.flag == "song_taught" }
        }
        XCTAssertThrowsError(try game.choose("s47_1")) { error in
            XCTAssertEqual(error as? StoryError, .lockedChoice)
        }
        try game.choose("s47_3")
        try play(&game, until: "decision")
        XCTAssertNil(game.choices.first { $0.to == "final_1" })
        try game.choose("decide_risk")
        XCTAssertTrue(game.isComplete)
        XCTAssertEqual(game.progress.endingsFound, ["car13_final_7"])
    }

    func testRoofAndLampRoutesAreLongerAndOpenTheSkiff() throws {
        var short = try AdventureEngine(book: story())
        try play(&short, until: "s47", prefer: ["s20_1", "s36_1"])
        var long = try AdventureEngine(book: story())
        try play(&long, until: "s47", prefer: ["s20_2", "s36_2"])
        XCTAssertEqual(short.progress.decisionCount, 46)
        XCTAssertEqual(long.progress.decisionCount, 49)
        XCTAssertTrue(long.progress.history.contains("roof6"))
        XCTAssertTrue(long.progress.history.contains("lamp5"))

        try long.choose("s47_2")
        try play(&long, until: "decision_skiff")
        try long.choose("skiff_hold")
        XCTAssertTrue(long.isComplete)
        XCTAssertEqual(long.progress.decisionCount, 56)
        XCTAssertEqual(long.progress.endingsFound, ["car13_final_4"])
    }

    func testDetourRewindsToTheSameScene() throws {
        var game = try AdventureEngine(book: story())
        try game.choose("s01_1")
        try game.choose("s02_1")
        let before = game.progress
        try game.choose("s03_detour")
        XCTAssertTrue(game.isDetour)
        XCTAssertEqual(game.progress.detoursFound, ["car13_detour_1"])
        try game.rewindDetour()
        XCTAssertEqual(game.progress.nodeID, "s03")
        XCTAssertEqual(game.progress.stats, before.stats)
        XCTAssertEqual(game.progress.decisionCount, before.decisionCount)
        XCTAssertTrue(AchievementCatalog.unlockedBy(game, event: .rewind).contains("car13_first_rewind"))
    }

    func testAchievementsBelongToTheirOwnStory() throws {
        let mine = AchievementCatalog.achievements(for: AchievementCatalog.carThirteenID)
        XCTAssertEqual(mine.count, 32)
        XCTAssertEqual(mine.filter { $0.group == .endings }.count, 7)
        XCTAssertTrue(mine.allSatisfy { $0.id.hasPrefix("car13_") })
        XCTAssertEqual(AchievementCatalog.achievements(for: AchievementCatalog.doorTomorrowID).count, 25)
        XCTAssertEqual(Set(AchievementCatalog.all.map(\.id)).count, AchievementCatalog.all.count)
        XCTAssertEqual(AchievementCatalog.shelves.map(\.bookID), ["door-tomorrow", "car-thirteen"])

        var game = try AdventureEngine(book: story())
        XCTAssertTrue(AchievementCatalog.unlockedBy(game, event: .newRun).isEmpty)
        try game.choose("s01_1")
        let first = AchievementCatalog.unlockedBy(game, event: .choice)
        XCTAssertEqual(first, ["car13_first_choice"])

        // Episode 01 never awards this story's achievements.
        var other = try AdventureEngine(book: StoryLoader.load(filename: "first_signal"))
        try other.choose("s01_1")
        XCTAssertTrue(AchievementCatalog.unlockedBy(other, event: .choice)
            .allSatisfy { !$0.hasPrefix("car13_") })
    }

    func testRouteAndEndingAchievements() throws {
        var game = try AdventureEngine(book: story())
        try play(&game, until: "s47", prefer: ["s20_2", "s36_2"])
        var earned = AchievementCatalog.unlockedBy(game, event: .choice)
        XCTAssertTrue(earned.isSuperset(of: ["car13_roofs", "car13_lamp", "car13_halfway"]))
        XCTAssertFalse(earned.contains("car13_under"))
        XCTAssertFalse(earned.contains("car13_key"))

        try game.choose("s47_2")
        try play(&game, until: "decision_skiff")
        try game.choose("skiff_hold")
        earned = AchievementCatalog.unlockedBy(game, event: .choice)
        XCTAssertTrue(earned.isSuperset(of: ["car13_skiff", "car13_fifty", "car13_ending_4", "car13_clean_run"]))
        XCTAssertFalse(earned.contains("car13_ending_1"))
        XCTAssertFalse(earned.contains("car13_three_ways"))
        // Every earned ID is a real achievement.
        XCTAssertTrue(earned.isSubset(of: Set(AchievementCatalog.all.map(\.id))))
    }
}
