import SwiftUI

/// A separate installable iOS app sharing the tested story engine and reader UI.
@main
struct StuffyLandApp: App {
    @StateObject private var game = GameStore()
    @StateObject private var purchases = PurchaseManager()
    @StateObject private var ads = AdsController()
    @AppStorage("stuffyland.appearance") private var appearance = AppearanceMode.dark.rawValue

    var body: some Scene {
        WindowGroup {
            StarportRootView()
                .environmentObject(game)
                .environmentObject(purchases)
                .environmentObject(ads)
                .preferredColorScheme(AppearanceMode(rawValue: appearance)?.scheme)
        }
    }
}
