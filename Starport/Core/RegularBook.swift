import Foundation

/// A linear, paged story. Unlike StoryBook, it has no choices, stats or endings.
/// Pages are editorial sections rather than fixed screen-sized slices; Dynamic
/// Type can reflow them naturally on iPhone and iPad.
public struct RegularBookPage: Codable, Identifiable, Sendable {
    public let id: String
    public let heading: String?
    public let paragraphs: [String]
    public let illustration: StoryIllustration?
}

public struct RegularBook: Codable, Sendable {
    public let id: String
    public let contentVersion: Int
    public let title: String
    public let subtitle: String
    public let author: String?
    public let pages: [RegularBookPage]
}

public enum RegularBookValidator {
    public static func validate(_ book: RegularBook) throws {
        guard StoryLoader.isSafeFilename(book.id), book.contentVersion > 0,
              !book.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !book.subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !book.pages.isEmpty, book.pages.count <= 500 else {
            throw StoryError.invalidBook("Reader story is empty or has invalid metadata.")
        }
        let identifiers = book.pages.map(\.id)
        guard identifiers.count == Set(identifiers).count else {
            throw StoryError.invalidBook("Reader pages must have unique IDs.")
        }
        for page in book.pages {
            guard StoryLoader.isSafeFilename(page.id),
                  !page.paragraphs.isEmpty,
                  page.paragraphs.count <= 40,
                  page.paragraphs.allSatisfy({
                      !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      $0.count <= 15_000
                  }) else {
                throw StoryError.invalidBook("Invalid text in reader page \(page.id).")
            }
            if let illustration = page.illustration {
                guard StoryLoader.isSafeFilename(illustration.asset),
                      !illustration.alt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw StoryError.invalidBook("Invalid illustration on \(page.id).")
                }
            }
        }
    }
}
