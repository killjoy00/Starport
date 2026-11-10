import Foundation

/// Local-first adventure shelf. New JSON adventures can be published to the
/// public repository and loaded with "Check for new adventures" — no app update.
/// No remote code or untrusted URLs are ever executed.
@MainActor
final class AdventureRepository {
    private static let remoteRoot = "https://raw.githubusercontent.com/killjoy00/Starport/main/Starport/Content/"
    private let bundled: AdventureCatalog
    private let folder: URL
    private let session: URLSession

    private(set) var catalog: AdventureCatalog

    init() throws {
        let local = try StoryLoader.loadCatalog()
        bundled = local

        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        folder = base.appendingPathComponent("StoryPacks", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        session = URLSession(configuration: configuration)

        if let data = try? Data(contentsOf: folder.appendingPathComponent("catalog.json")),
           let cached = try? JSONDecoder().decode(AdventureCatalog.self, from: data),
           (try? StoryLoader.validateCatalog(cached)) != nil {
            catalog = Self.combined(bundled: local, updates: cached)
        } else {
            catalog = local
        }
    }

    func load(_ listing: AdventureListing) throws -> StoryBook {
        guard StoryLoader.isSafeFilename(listing.id), StoryLoader.isSafeFilename(listing.filename) else {
            throw StoryError.missingResource
        }
        let cached = folder.appendingPathComponent("\(listing.id)_\(listing.contentVersion).json")
        if let data = try? Data(contentsOf: cached),
           let story = try? StoryLoader.decode(data),
           story.id == listing.id, story.contentVersion == listing.contentVersion {
            return story
        }
        let story = try StoryLoader.load(filename: listing.filename)
        guard story.id == listing.id, story.contentVersion == listing.contentVersion else {
            throw StoryError.invalidBook("The downloaded adventure is unavailable. Check for updates.")
        }
        return story
    }

    func refresh() async throws -> AdventureCatalog {
        let manifest = try await fetch("catalog.json", sizeLimit: 50_000)
        let incoming = try JSONDecoder().decode(AdventureCatalog.self, from: manifest)
        try StoryLoader.validateCatalog(incoming)
        guard incoming.adventures.count <= 30 else {
            throw StoryError.invalidBook("Too many stories in the catalog.")
        }

        let merged = Self.combined(bundled: bundled, updates: incoming)
        // Download and validate *every* new/updated story before publishing the shelf.
        // Each version has its own filename so a failed refresh can't overwrite a good copy.
        for listing in merged.adventures {
            if let local = bundled.adventures.first(where: {
                $0.id == listing.id && $0.contentVersion == listing.contentVersion
            }) {
                let localStory = try StoryLoader.load(filename: local.filename)
                guard localStory.id == listing.id else {
                    throw StoryError.invalidBook("Bundled adventure ID mismatch.")
                }
                continue
            }
            let data = try await fetch("\(listing.filename).json", sizeLimit: 1_000_000)
            let story = try StoryLoader.decode(data)
            guard story.id == listing.id, story.contentVersion == listing.contentVersion else {
                throw StoryError.invalidBook("Downloaded story does not match its catalog entry.")
            }
            try data.write(to: folder.appendingPathComponent("\(listing.id)_\(listing.contentVersion).json"), options: .atomic)
        }

        let savedCatalog = try JSONEncoder().encode(merged)
        try savedCatalog.write(to: folder.appendingPathComponent("catalog.json"), options: .atomic)
        catalog = merged
        return merged
    }

    private static func combined(bundled: AdventureCatalog, updates: AdventureCatalog) -> AdventureCatalog {
        var entries = bundled.adventures
        for item in updates.adventures {
            if let index = entries.firstIndex(where: { $0.id == item.id }) {
                if item.contentVersion >= entries[index].contentVersion {
                    entries[index] = item
                }
            } else {
                entries.append(item)
            }
        }
        return AdventureCatalog(formatVersion: 1, adventures: entries)
    }

    private func fetch(_ filename: String, sizeLimit: Int) async throws -> Data {
        // Never accept URL components, parent paths or arbitrary external hosts from JSON.
        let name = String(filename.dropLast(5)) // strip ".json"
        guard filename.hasSuffix(".json"), StoryLoader.isSafeFilename(name),
              let url = URL(string: Self.remoteRoot + filename) else {
            throw StoryError.invalidBook("Invalid download name.")
        }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              data.count > 0, data.count <= sizeLimit else {
            throw StoryError.invalidBook("The adventure download is unavailable.")
        }
        return data
    }
}
