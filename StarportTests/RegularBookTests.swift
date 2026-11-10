import XCTest
@testable import StarportCore

final class RegularBookTests: XCTestCase {
    private func fixture() throws -> Data {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try Data(contentsOf: root.appendingPathComponent(
            "StuffyLand/Content/button_at_window.json"))
    }

    func testReadThroughStoryIsCompleteAndValid() throws {
        let book = try StoryLoader.decodeReader(fixture())
        XCTAssertEqual(book.id, "stuffy-reader-sample")
        XCTAssertEqual(book.contentVersion, 1)
        XCTAssertEqual(book.pages.count, 7)
        XCTAssertEqual(book.pages.first?.id, "page_01")
        XCTAssertEqual(book.pages.last?.id, "page_07")
        XCTAssertGreaterThanOrEqual(book.pages.filter { $0.illustration != nil }.count, 2)
        XCTAssertTrue(book.pages.flatMap(\.paragraphs).allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        })
    }

    func testOlderCatalogEntriesRemainBranchingAdventures() throws {
        let catalog = try StoryLoader.loadCatalog()
        XCTAssertEqual(catalog.adventures.first?.format, .adventure)
    }

    func testDuplicateReaderPageIDsRejected() throws {
        var obj = try XCTUnwrap(JSONSerialization.jsonObject(with: fixture()) as? [String: Any])
        var pages = try XCTUnwrap(obj["pages"] as? [[String: Any]])
        pages[1]["id"] = pages[0]["id"]
        obj["pages"] = pages
        let data = try JSONSerialization.data(withJSONObject: obj)
        XCTAssertThrowsError(try StoryLoader.decodeReader(data))
    }

    func testBlankReaderPageRejected() throws {
        var obj = try XCTUnwrap(JSONSerialization.jsonObject(with: fixture()) as? [String: Any])
        var pages = try XCTUnwrap(obj["pages"] as? [[String: Any]])
        pages[0]["paragraphs"] = ["  "]
        obj["pages"] = pages
        let data = try JSONSerialization.data(withJSONObject: obj)
        XCTAssertThrowsError(try StoryLoader.decodeReader(data))
    }

    func testUnsafeReaderImageNameRejected() throws {
        var obj = try XCTUnwrap(JSONSerialization.jsonObject(with: fixture()) as? [String: Any])
        var pages = try XCTUnwrap(obj["pages"] as? [[String: Any]])
        pages[0]["illustration"] = ["asset": "../elsewhere", "alt": "Bad asset"]
        obj["pages"] = pages
        let data = try JSONSerialization.data(withJSONObject: obj)
        XCTAssertThrowsError(try StoryLoader.decodeReader(data))
    }
}
