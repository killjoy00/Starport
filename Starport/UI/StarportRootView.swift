import SwiftUI

struct StarportRootView: View {
    @EnvironmentObject private var game: GameStore
    @EnvironmentObject private var purchases: PurchaseManager
    @EnvironmentObject private var ads: AdsController

    @AppStorage("starport.confirmed13Plus") private var ageConfirmed = false
    @State private var reading = false
    @State private var showingSettings = false
    @State private var showingAchievements = false

    var body: some View {
        ZStack {
            Starfield()
            if !ageConfirmed {
                AgeGateView(onConfirm13Plus: { ageConfirmed = true })
            } else if reading, game.engine != nil {
                AdventureScreen(onExit: { reading = false })
            } else {
                library
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if ageConfirmed, purchases.entitlementsLoaded, !purchases.isAdFree,
               ads.canShowBanner, let unitID = ads.bannerUnitID {
                AdBannerView(unitID: unitID)
                    .background(StarportTheme.panel)
                    .overlay(alignment: .top) {
                        Rectangle().fill(StarportTheme.line).frame(height: 1)
                    }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsScreen()
                .environmentObject(game)
                .environmentObject(purchases)
                .environmentObject(ads)
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsScreen()
                .environmentObject(game)
        }
        .task(id: ageConfirmed) {
            guard ageConfirmed else { return }
            await purchases.prepare()
            await ads.prepareIfNeeded()
        }
        .tint(StarportTheme.teal)
    }

    private var library: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    StarportMasthead()
                    Button { showingAchievements = true } label: {
                        Image(systemName: "trophy")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Achievements, \(game.achievements.count) unlocked")
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Settings and Remove Ads")
                }
                .padding(.top, 10)

                OrbitArtwork()
                    .frame(height: 185)

                VStack(alignment: .leading, spacing: 10) {
                    Text("CHOOSE YOUR ADVENTURE")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .tracking(1.6)
                        .foregroundStyle(StarportTheme.orange)
                    Text("Your next story starts here.")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(StarportTheme.paper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Make the decisions. Find the endings. Then try another route.")
                        .font(.body)
                        .foregroundStyle(StarportTheme.muted)
                }

                if let entries = game.catalog?.adventures {
                    ForEach(entries) { entry in
                        Button {
                            game.select(entry.id)
                            guard game.selectedID == entry.id else { return }
                            if game.engine?.isComplete == true { game.restart() }
                            game.begin()
                            reading = true
                        } label: {
                            adventureCard(entry)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Can't open the library")
                            .font(.title2.bold())
                        Text(game.errorMessage ?? "Please try opening Starport again.")
                            .foregroundStyle(StarportTheme.muted)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .foregroundStyle(StarportTheme.orange)
                        Text("More adventures will appear here.")
                            .font(.headline)
                            .foregroundStyle(StarportTheme.paper)
                    }
                    Text("New stories can be added without updating the app. Your saved adventures work offline.")
                        .foregroundStyle(StarportTheme.muted)
                        .font(.subheadline)
                    Button {
                        Task { await game.refreshLibrary() }
                    } label: {
                        HStack {
                            if game.isRefreshing { ProgressView().controlSize(.small) }
                            else { Image(systemName: "arrow.clockwise") }
                            Text(game.isRefreshing ? "Checking..." : "Check for new adventures")
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .disabled(game.isRefreshing)
                    if let message = game.libraryMessage {
                        Text(message).font(.footnote).foregroundStyle(StarportTheme.muted)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(StarportTheme.panel.opacity(0.95), in: RoundedRectangle(cornerRadius: 16))

                Text("STARPORT  ·  FOR READERS AGES 13+")
                    .font(.system(.caption2, design: .monospaced))
                    .tracking(0.7)
                    .foregroundStyle(StarportTheme.muted)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
            }
            .frame(maxWidth: 610)
            .padding(.horizontal, 23)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
        }
    }

    private func adventureCard(_ entry: AdventureListing) -> some View {
        let selected = game.selectedID == entry.id ? game.engine : nil
        let count = selected?.progress.endingsFound.count ?? 0
        return VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label(entry.genre.uppercased(), systemImage: entry.symbol)
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(StarportTheme.orange)
                Spacer()
                Text("\(entry.estimatedMinutes) MIN")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(StarportTheme.muted)
            }
            Text(entry.title)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(StarportTheme.paper)
                .multilineTextAlignment(.leading)
            Text(entry.blurb)
                .font(.subheadline)
                .foregroundStyle(StarportTheme.muted)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text(selected?.progress.started == true
                     ? "\(count) OF \(selected?.book.finalCount ?? 5) TRUE ENDINGS FOUND"
                     : "READY TO READ")
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(StarportTheme.teal)
                Spacer()
                Text(selected?.progress.started == true && selected?.isComplete == false ? "CONTINUE" : "OPEN")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(StarportTheme.teal)
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(StarportTheme.teal)
            }
            .padding(.top, 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StarportTheme.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(StarportTheme.line, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
