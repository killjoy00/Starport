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

                VStack(alignment: .leading, spacing: 11) {
                    HStack(spacing: 7) {
                        Image(systemName: "sparkle")
                        Text(AppBrand.current.heroEyebrow)
                    }
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(StarportTheme.orange)

                    Text(AppBrand.current.heroTitle)
                        .font(.system(size: 33, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(StarportTheme.paper)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(AppBrand.current.heroDescription)
                        .font(.body)
                        .foregroundStyle(StarportTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Text("THE LIBRARY")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .tracking(1.6)
                        .foregroundStyle(StarportTheme.teal)
                    Spacer()
                    Text("\(game.catalog?.adventures.count ?? 0) ADVENTURE")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(StarportTheme.muted)
                }

                if let entries = game.catalog?.adventures {
                    if AppBrand.current.isStuffyLand {
                        ForEach(Array(Set(entries.map { $0.collection ?? "Other Adventures" })).sorted(), id: \.self) { shelf in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(shelf.uppercased())
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundStyle(StarportTheme.orange)
                                ForEach(entries.filter { ($0.collection ?? "Other Adventures") == shelf }) { entry in
                                    adventureButton(entry)
                                }
                            }
                        }
                    } else {
                        ForEach(entries) { entry in
                            adventureButton(entry)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Can't open the library")
                            .font(.title2.bold())
                        Text(game.errorMessage ?? "Please try opening \(AppBrand.current.name) again.")
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

                Text("\(AppBrand.current.masthead)  ·  FOR READERS AGES 13+")
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

    private func adventureButton(_ entry: AdventureListing) -> some View {
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

    private func adventureCard(_ entry: AdventureListing) -> some View {
        let selected = game.selectedID == entry.id ? game.engine : nil
        let count = selected?.progress.endingsFound.count ?? 0

        return VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top, spacing: 16) {
                if let cover = entry.coverAsset {
                    AdventureCoverView(assetName: cover)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(entry.genre.uppercased())
                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(StarportTheme.orange)

                    Text(entry.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(StarportTheme.paper)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(entry.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(StarportTheme.muted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Label("\(entry.estimatedMinutes) minute adventure", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(StarportTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Rectangle()
                .fill(StarportTheme.line.opacity(0.6))
                .frame(height: 1)

            HStack(spacing: 8) {
                Image(systemName: "bookmark")
                Text(selected?.progress.started == true
                     ? "\(count) / \(selected?.book.finalCount ?? 5) ENDINGS FOUND"
                     : "READY TO EXPLORE")
                Spacer()
                Text(selected?.progress.started == true && selected?.isComplete == false
                     ? "CONTINUE" : "READ")
                Image(systemName: "arrow.up.right")
            }
            .font(.system(.caption, design: .monospaced, weight: .bold))
            .foregroundStyle(StarportTheme.teal)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StarportTheme.panel, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(StarportTheme.line.opacity(0.8), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
