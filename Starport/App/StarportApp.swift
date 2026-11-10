import SwiftUI

@main
struct StarportApp: App {
    @StateObject private var game = GameStore()
    @StateObject private var purchases = PurchaseManager()
    @StateObject private var ads = AdsController()
    @AppStorage("starport.appearance") private var appearance = AppearanceMode.dark.rawValue

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
