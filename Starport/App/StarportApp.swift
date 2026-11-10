import SwiftUI

@main
struct StarportApp: App {
    @StateObject private var game = GameStore()

    var body: some Scene {
        WindowGroup {
            StarportRootView()
                .environmentObject(game)
                .preferredColorScheme(.dark)
        }
    }
}
