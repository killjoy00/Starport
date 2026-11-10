import XCTest
@testable import StarportCore

final class AdventureEngineTests: XCTestCase {
    func testStoryLoadsWithValidConnections() throws {
        let story = try StoryLoader.load()
        XCTAssertEqual(story.nodes.count, 26)
        XCTAssertEqual(story.nodes.filter { $0.ending != nil }.count, 6)
        XCTAssertEqual(story.nodes.flatMap { $0.choices ?? [] }.count, 52)
        XCTAssertNoThrow(try StoryValidator.validate(story))
    }

    func testAllSixEndingsAreActuallyReachable() throws {
        let story = try StoryLoader.load()
        var discovered: Set<String> = []
        func explore(_ game: AdventureEngine, depth: Int) throws {
            XCTAssertLessThan(depth, 15, "The adventure should not contain infinite loops")
            if let ending = game.node.ending {
                discovered.insert(ending.id)
                return
            }
            for choice in game.choices where choice.isAvailable(
                stats: game.progress.stats,
                flags: game.progress.flags
            ) {
                var next = game
                try next.choose(choice.id)
                try explore(next, depth: depth + 1)
            }
        }
        try explore(AdventureEngine(book: story), depth: 0)
        XCTAssertEqual(discovered, Set(["bridge", "beacon", "drone", "warning", "seal", "open"]))
    }

    func testLockedChoiceCannotChangeGameState() throws {
        var game = try AdventureEngine(book: StoryLoader.load())
        try game.choose("go_control")
        try game.choose("check_manifest")
        try game.choose("decode_times")
        try game.choose("go_console")
        let before = game.progress
        XCTAssertThrowsError(try game.choose("bridge")) { error in
            XCTAssertEqual(error as? StoryError, .lockedChoice)
        }
        XCTAssertEqual(game.progress, before)
    }

    func testUnknownChoiceCannotChangeGameState() throws {
        var game = try AdventureEngine(book: StoryLoader.load())
        let before = game.progress
        XCTAssertThrowsError(try game.choose("not-an-option"))
        XCTAssertEqual(game.progress, before)
    }

    func testSaveResumeAndRestartRetainDiscoveredEndings() throws {
        let story = try StoryLoader.load()
        var game = try AdventureEngine(book: story)
        game.begin()
        try game.choose("go_archive")
        try game.choose("read_storm")
        try game.choose("calculate_phase")

        let saved = try game.encodedProgress()
        var resumed = try AdventureEngine(book: story, restored: saved)
        XCTAssertEqual(resumed.progress, game.progress)
        try resumed.choose("go_console")
        try resumed.choose("seal")
        XCTAssertTrue(resumed.isComplete)
        XCTAssertEqual(resumed.progress.endingsFound, Set(["seal"]))
        resumed.restart()
        XCTAssertEqual(resumed.progress.nodeID, "arrival")
        XCTAssertEqual(resumed.progress.endingsFound, Set(["seal"]))
        XCTAssertEqual(resumed.progress.stats, AdventureStats())
    }

    func testCorruptOrStaleSaveStartsSafely() throws {
        let book = try StoryLoader.load()
        let game = try AdventureEngine(book: book, restored: Data("not JSON".utf8))
        XCTAssertEqual(game.progress.nodeID, "arrival")
        XCTAssertFalse(game.progress.started)
    }

    func testStatsStayWithinFiveBars() {
        var stats = AdventureStats()
        stats[.power] = -50
        stats[.clues] = 99
        XCTAssertEqual(stats.power, 0)
        XCTAssertEqual(stats.clues, 5)
    }
}
