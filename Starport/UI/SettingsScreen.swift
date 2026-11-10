import SwiftUI

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var game: GameStore
    @EnvironmentObject private var purchases: PurchaseManager
    @EnvironmentObject private var ads: AdsController
    @AppStorage("starport.appearance") private var appearance = AppearanceMode.dark.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Dark mode is the default. Your choice is saved on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Reading appearance")
                }

                Section {
                    if purchases.isAdFree {
                        Label("Ads removed", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(StarportTheme.teal)
                        Text("Thank you for supporting \(AppBrand.current.name). Your purchase is linked to your Apple Account.")
                            .font(.footnote)
                    } else {
                        Text("A one-time purchase removes the banner from every adventure. No subscription.")
                            .font(.subheadline)
                        if let product = purchases.product {
                            Button {
                                Task { await purchases.buy() }
                            } label: {
                                HStack {
                                    Text("Remove Ads")
                                    Spacer()
                                    Text(product.displayPrice)
                                }
                            }
                            .disabled(purchases.busy)
                        } else {
                            Text("Remove Ads will be available after its App Store product is configured.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("Restore purchases") {
                        Task { await purchases.restore() }
                    }
                    .disabled(purchases.busy)
                    Text("Ask a parent or guardian before making a purchase.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let message = purchases.message {
                        Text(message).font(.footnote).foregroundStyle(StarportTheme.teal)
                        Button("Dismiss message") { purchases.dismissMessage() }
                            .font(.footnote)
                    }
                } header: {
                    Text("Purchases")
                }

                Section {
                    Button {
                        Task { await game.refreshLibrary() }
                    } label: {
                        HStack {
                            Text("Check for new adventures")
                            Spacer()
                            if game.isRefreshing { ProgressView() }
                            else { Image(systemName: "arrow.clockwise") }
                        }
                    }
                    .disabled(game.isRefreshing)
                    if let status = game.libraryMessage {
                        Text(status).font(.footnote).foregroundStyle(.secondary)
                    }
                    Text("Downloaded stories and your reading progress remain on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Adventure library")
                }

                Section {
                    if ads.privacyOptionsRequired {
                        Button("Advertising privacy options") {
                            Task { await ads.showPrivacyOptions() }
                        }
                    }
                    Text("\(AppBrand.current.name) is for ages 13+. Ads use teen age treatment, general-rated creative, and non-personalized settings. We don't request your advertising identifier.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("To report an inappropriate ad, tap AdChoices on the banner, then Why this ad? and Report ad.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Link("How to report an ad", destination:
                        URL(string: "https://support.google.com/My-Ad-Center-Help/answer/13861201")!)
                        .font(.subheadline)
                    if let message = ads.message {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Ads and privacy")
                }

                Section {
                    Link("Support and feedback", destination: URL(string: "https://github.com/killjoy00/Starport/blob/main/docs/support.md")!)
                    Link("Privacy policy", destination: URL(string: "https://github.com/killjoy00/Starport/blob/main/docs/privacy.md")!)
                } header: {
                    Text("Help")
                }

                Section {
                    Text(AppBrand.current.isStuffyLand ? "Stuffy Land currently has a 13+ development age gate. Its intended audience and child-safety rules must be finalized before release." : "Starport is for ages 13 and up only. Stories use accessible, middle-grade-style science-fiction prose; that is a writing choice, not an invitation for younger users.")
                        .font(.subheadline)
                    Text("Version 0.2 · Stories are fictional. No account is required.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About \(AppBrand.current.name)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(StarportTheme.ink)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(StarportTheme.teal)
    }
}
