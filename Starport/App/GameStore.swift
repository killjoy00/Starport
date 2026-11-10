import Foundation
import SwiftUI

/// Owns the library and per-adventure progress. No user accounts or telemetry.
@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var catalog: AdventureCatalog?
    @Published private(set) var selectedID: String?
    @Published private(set) var engine: AdventureEngine?
    @Published private(set) var readerBook: RegularBook?
    @Published private(set) var readerPageIndex = 0
    @Published private(set) var errorMessage: String?
    @Published private(set) var libraryMessage: String?
    @Published private(set) var isRefreshing = false
    @Published private(set) var achievements: Set<String> = []
    @Published private(set) var lastAchievement: Achievement?

    private let defaults: UserDefaults
    private var repository: AdventureRepository?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        achievements = Set(defaults.stringArray(forKey: "\(AppBrand.current.storagePrefix).achievements.v1") ?? [])
        do {
            let shelf = try AdventureRepository()
            repository = shelf
            catalog = shelf.catalog
            let selected = defaults.string(forKey: "\(AppBrand.current.storagePrefix).lastAdventure") ??
                shelf.catalog.adventures[0].id
            if shelf.catalog.adventures.contains(where: { $0.id == selected }) {
                select(selected)
            } else {
                select(shelf.catalog.adventures[0].id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(_ id: String) {
        guard let entry = catalog?.adventures.first(where: { $0.id == id }),
              let repository else {
            errorMessage = "That adventure isn't available yet."
            return
        }
        do {
            if entry.format == .reader {
                let book = try repository.loadReader(entry)
                let bookmark = defaults.integer(forKey: readerProgressKey(id, version: book.contentVersion))
                readerBook = book
                readerPageIndex = min(max(0, bookmark), book.pages.count - 1)
                engine = nil
            } else {
                let book = try repository.load(entry)
                let restored = defaults.data(forKey: progressKey(id))
                let loaded = try AdventureEngine(book: book, restored: restored)
                engine = loaded
                readerBook = nil
                readerPageIndex = 0
            }
            selectedID = id
            defaults.set(id, forKey: "\(AppBrand.current.storagePrefix).lastAdventure")
            errorMessage = nil
            if engine != nil { awardAchievements(event: .newRun) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// The bookmark is local, per book and per content version. A new edition
    /// starts from the beginning instead of reopening a stale page index.
    func goToReaderPage(_ index: Int) {
        guard let book = readerBook, !book.pages.isEmpty else { return }
        readerPageIndex = max(0, min(index, book.pages.count - 1))
        defaults.set(readerPageIndex, forKey: readerProgressKey(book.id, version: book.contentVersion))
    }

    func nextReaderPage() { goToReaderPage(readerPageIndex + 1) }
    func previousReaderPage() { goToReaderPage(readerPageIndex - 1) }

    func begin() {
        guard var current = engine else { return }
        current.begin()
        engine = current
        save()
    }

    func choose(_ id: String) {
        guard var current = engine else { return }
        do {
            try current.choose(id)
            engine = current
            errorMessage = nil
            awardAchievements(event: .choice)
            save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rewindDetour() {
        guard var current = engine else { return }
        do {
            try current.rewindDetour()
            engine = current
            errorMessage = nil
            awardAchievements(event: .rewind)
            save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restart() {
        guard var current = engine else { return }
        current.restart()
        engine = current
        errorMessage = nil
        save()
    }

    func refreshLibrary() async {
        guard let repository, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let refreshed = try await repository.refresh()
            catalog = refreshed
            libraryMessage = "Library checked. \(refreshed.adventures.count) adventure(s) available."
            if let id = selectedID {
                // Load new version if the content was updated; each saved run is versioned.
                select(id)
            }
        } catch {
            libraryMessage = "Could not check for adventures. The downloaded stories on this device still work."
        }
    }

    func dismissAchievement() { lastAchievement = nil }
    func dismissError() { errorMessage = nil }

    private func awardAchievements(event: AchievementEvent) {
        guard let engine else { return }
        let eligible = AchievementCatalog.unlockedBy(engine, event: event, stuffyLand: AppBrand.current.isStuffyLand)
        let newlyEarned = eligible.subtracting(achievements)
        guard !newlyEarned.isEmpty else { return }
        achievements.formUnion(newlyEarned)
        defaults.set(achievements.sorted(), forKey: "\(AppBrand.current.storagePrefix).achievements.v1")
        lastAchievement = AchievementCatalog.all(forStuffyLand: AppBrand.current.isStuffyLand).first { newlyEarned.contains($0.id) }
    }
    func clearLibraryMessage() { libraryMessage = nil }

    private func readerProgressKey(_ id: String, version: Int) -> String {
        "\(AppBrand.current.storagePrefix).reader.\(id).v\(version)"
    }

    private func progressKey(_ id: String) -> String { "\(AppBrand.current.storagePrefix).progress.\(id).v2" }

    private func save() {
        guard let engine, let selectedID else { return }
        do {
            defaults.set(try engine.encodedProgress(), forKey: progressKey(selectedID))
        } catch {
            errorMessage = "Couldn't save the adventure. Try again."
        }
    }
}
