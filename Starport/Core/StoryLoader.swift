import Foundation

public enum StoryLoader {
    private static var contentBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }

    public static func loadCatalog() throws -> AdventureCatalog {
        let data = try bundledData(filename: "catalog")
        let catalog = try JSONDecoder().decode(AdventureCatalog.self, from: data)
        try validateCatalog(catalog)
        return catalog
    }

    public static func validateCatalog(_ catalog: AdventureCatalog) throws {
        guard catalog.formatVersion == 1,
              !catalog.adventures.isEmpty,
              Set(catalog.adventures.map(\.id)).count == catalog.adventures.count,
              Set(catalog.adventures.map(\.filename)).count == catalog.adventures.count else {
            throw StoryError.invalidBook("Invalid adventure catalog.")
        }
        for item in catalog.adventures {
            guard !item.id.isEmpty, !item.title.isEmpty, item.contentVersion > 0,
                  item.estimatedMinutes > 0, isSafeFilename(item.filename) else {
                throw StoryError.invalidBook("Unsafe or incomplete adventure entry.")
            }
        }
    }

    public static func load(filename: String) throws -> StoryBook {
        try decode(try bundledData(filename: filename))
    }

    public static func decode(_ data: Data) throws -> StoryBook {
        guard data.count <= 1_000_000 else {
            throw StoryError.invalidBook("Adventure exceeds the size limit.")
        }
        do {
            let book = try JSONDecoder().decode(StoryBook.self, from: data)
            try StoryValidator.validate(book)
            return book
        } catch let error as StoryError { throw error }
        catch { throw StoryError.invalidBook(error.localizedDescription) }
    }

    public static func isSafeFilename(_ name: String) -> Bool {
        !name.isEmpty && name.count <= 64 &&
        name.unicodeScalars.allSatisfy {
            CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_-").contains($0)
        }
    }

    private static func bundledData(filename: String) throws -> Data {
        guard isSafeFilename(filename),
              let url = contentBundle.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw StoryError.missingResource
        }
        return data
    }
}
