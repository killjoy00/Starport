import Foundation
import SwiftUI

/// Saves every decision locally. No account, network calls, or analytics.
@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var engine: AdventureEngine?
    @Published private(set) var errorMessage: String?

    private let defaults: UserDefaults
    private let saveKey = "starport.adventure.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        do {
            let book = try StoryLoader.load()
            engine = try AdventureEngine(book: book, restored: defaults.data(forKey: saveKey))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

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

    private func save() {
        guard let engine else { return }
        do {
            defaults.set(try engine.encodedProgress(), forKey: saveKey)
        } catch {
            errorMessage = "Couldn't save the adventure. Try again."
        }
    }
}
