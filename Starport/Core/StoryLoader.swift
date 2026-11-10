import Foundation

public enum StoryLoader {
    public static func load() throws -> StoryBook {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif
        guard let url = bundle.url(forResource: "first_signal", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw StoryError.missingResource
        }
        do {
            let book = try JSONDecoder().decode(StoryBook.self, from: data)
            try StoryValidator.validate(book)
            return book
        } catch {
            throw StoryError.invalidBook(error.localizedDescription)
        }
    }
}
