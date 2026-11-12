import XCTest
@testable import StarportCore

/// Opal and TITANUS: a branching retelling of a complete user-supplied story.
final class TitanusAdventureTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    private func book() throws -> StoryBook {
        try StoryLoader.decode(Data(contentsOf: root.appendingPathComponent("StuffyLand/Content/titanus.json")))
    }

    /// Plays forward, taking a `prefer` choice whenever one is open and otherwise
    /// the first open choice that is not a detour, until reaching `stop`.
    private func play(_ engine: inout AdventureEngine, until stop: String, prefer: Set<String> = []) throws {
        while engine.progress.nodeID != stop && !engine.isComplete {
            let p = engine.progress
            let open = engine.choices.filter {
                $0.isAvailable(stats: p.stats, flags: p.flags) && engine.book.node($0.to)?.ending?.kind != .detour
            }
            let pick = try XCTUnwrap(open.first { prefer.contains($0.id) } ?? open.first, "Stuck at \(p.nodeID)")
            try engine.choose(pick.id)
        }
    }

    private func isOpen(_ engine: AdventureEngine, _ choiceID: String) throws -> Bool {
        let choice = try XCTUnwrap(engine.choices.first { $0.id == choiceID })
        return choice.isAvailable(stats: engine.progress.stats, flags: engine.progress.flags)
    }

    func testShapeAndPlannedIllustrations() throws {
        let story = try book()
        XCTAssertEqual(story.id, "stuffy-titanus")
        XCTAssertEqual(story.nodes.count, 59)
        XCTAssertEqual(story.finalCount, 7)
        XCTAssertEqual(story.detourCount, 12)
        XCTAssertEqual(story.minimumDecisions, 22)
        let scenes = story.nodes.filter { $0.ending == nil }
        XCTAssertEqual(scenes.count, 40)
        let art = scenes.compactMap { $0.illustration }
        XCTAssertGreaterThanOrEqual(art.count * 3, scenes.count)
        XCTAssertTrue(art.allSatisfy { $0.asset.hasPrefix("titanus-scene-") && !$0.alt.isEmpty })
        XCTAssertEqual(Set(art.map(\.asset)).count, 11)
    }

    func testEveryEndingIsReachableAndRunsAre22To25Choices() throws {
        let story = try book()
        let gates = Set(story.nodes.flatMap { $0.choices ?? [] }.flatMap { $0.requirements ?? [] }.compactMap(\.flag))
        var pending = [try AdventureEngine(book: story)]
        var seen = Set<String>()
        var lengths: [String: Set<Int>] = [:]
        while let engine = pending.popLast() {
            let p = engine.progress
            let key = "\(p.nodeID)|\(p.stats.clues)|\(p.stats.power)|\(p.stats.trust)|\(p.flags.intersection(gates).sorted())|\(p.decisionCount)"
            guard seen.insert(key).inserted else { continue }
            if let ending = engine.node.ending {
                lengths[ending.id, default: []].insert(p.decisionCount)
                continue
            }
            for choice in engine.choices where choice.isAvailable(stats: p.stats, flags: p.flags) {
                if story.node(choice.to)?.ending?.kind == .detour { continue }
                var next = engine
                try next.choose(choice.id)
                pending.append(next)
            }
            XCTAssertLessThan(seen.count, 100_000)
        }
        XCTAssertEqual(Set(lengths.keys), Set((1...7).map { "final_\($0)" }))
        let all = lengths.values.reduce(into: Set<Int>()) { $0.formUnion($1) }
        XCTAssertEqual(all.min(), 22)
        XCTAssertEqual(all.max(), 25)
    }

    /// Mountain route then river: nobody finds the tiny door, so the bell plan stays shut.
    func testWaterfallAndRiverRouteLocksOutTheTinyTeam() throws {
        var engine = try AdventureEngine(book: book())
        try play(&engine, until: "s20", prefer: ["s05_choice_1", "s12_choice_1"])
        XCTAssertTrue(engine.progress.history.contains("a3"))
        XCTAssertTrue(engine.progress.history.contains("c2"))
        XCTAssertFalse(try isOpen(engine, "s20_choice_2"))
        XCTAssertTrue(try isOpen(engine, "s20_choice_3"))
    }

    /// Spy route then dragons: the star-shaped piece is never found, so the star can't come home.
    func testSpyAndDragonRouteLocksOutTheLittleStar() throws {
        var engine = try AdventureEngine(book: book())
        try play(&engine, until: "s20", prefer: ["s05_choice_2", "s12_choice_2", "b3_choice_1", "d2_choice_1"])
        XCTAssertFalse(engine.progress.flags.contains("last_fragment"))
        XCTAssertFalse(try isOpen(engine, "s20_choice_1"))
        XCTAssertTrue(try isOpen(engine, "s20_choice_2"))
        XCTAssertThrowsError(try engine.choose("s20_choice_1")) { error in
            XCTAssertEqual(error as? StoryError, .lockedChoice)
        }
    }

    /// The best ending needs every friend to have had a job back in the meadow.
    func testBestEndingNeedsTheWholeTeam() throws {
        var small = try AdventureEngine(book: book())
        try play(&small, until: "decide_circle", prefer: ["s05_choice_1", "a4_choice_2", "s11_choice_1", "s20_choice_1"])
        XCTAssertFalse(small.progress.flags.contains("whole_team"))
        XCTAssertFalse(try isOpen(small, "decide_circle_choice_1"))
        try small.choose("decide_circle_choice_2")
        XCTAssertEqual(small.progress.endingsFound, ["final_2"])

        var whole = try AdventureEngine(book: book())
        try play(&whole, until: "decide_circle", prefer: ["s05_choice_1", "a4_choice_2", "s11_choice_2", "s20_choice_1"])
        XCTAssertTrue(try isOpen(whole, "decide_circle_choice_1"))
        try whole.choose("decide_circle_choice_1")
        XCTAssertTrue(whole.isComplete)
        XCTAssertEqual(whole.progress.endingsFound, ["final_1"])
        XCTAssertTrue(whole.node.paragraphs.contains { $0.contains("NOW I SHALL FIND MINE") })

        let earned = AchievementCatalog.unlockedBy(whole, event: .choice, stuffyLand: true)
        XCTAssertTrue(earned.isSuperset(of: ["titanus_ending_1", "titan_carvings"]))
        XCTAssertFalse(earned.contains { $0.hasPrefix("sundae_ending_") })
        XCTAssertTrue(earned.isSubset(of: Set(AchievementCatalog.stuffyLand.map(\.id))))
    }

    /// Only the best ending carries the sequel teaser.
    func testSequelTeaserOnlyInTheBestEnding() throws {
        let story = try book()
        for node in story.nodes where node.ending?.kind == .final {
            let teaser = node.paragraphs.contains { $0.contains("NOW I SHALL FIND MINE") }
            XCTAssertEqual(teaser, node.id == "final_1", node.id)
            XCTAssertEqual(node.paragraphs.last, "The End.")
        }
    }

    func testDetoursRewindToTheSameChoice() throws {
        var engine = try AdventureEngine(book: book())
        let before = engine.progress
        try engine.choose("s01_detour")
        XCTAssertTrue(engine.isDetour)
        try engine.rewindDetour()
        XCTAssertEqual(engine.progress.nodeID, "s01")
        XCTAssertEqual(engine.progress.stats, before.stats)
        XCTAssertEqual(engine.progress.detoursFound, ["detour_1"])
    }
}
