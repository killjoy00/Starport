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
            } else if reading, game.readerBook != nil {
                BookReaderView(onExit: { reading = false })
            } else if reading, game.engine != nil {
                AdventureScreen(onExit: { reading = false })
            } else if AppBrand.current.isStuffyLand {
                StuffyLandShelf(
                    entries: game.catalog?.adventures ?? [],
                    onOpen: openStory,
                    onSettings: { showingSettings = true },
                    onMemories: { showingAchievements = true },
                    onRefresh: { Task { await game.refreshLibrary() } },
                    refreshing: game.isRefreshing,
                    message: game.libraryMessage ?? game.errorMessage
                )
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
                    Text("\(game.catalog?.adventures.count ?? 0) \(AppBrand.current.isStuffyLand ? "STORIES" : "ADVENTURE")")
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

    private func openStory(_ entry: AdventureListing) {
        game.select(entry.id)
        guard game.selectedID == entry.id else { return }
        if entry.format == .reader {
            reading = game.readerBook != nil
            return
        }
        if game.engine?.isComplete == true { game.restart() }
        game.begin()
        reading = game.engine != nil
    }

    private func adventureButton(_ entry: AdventureListing) -> some View {
        Button { openStory(entry) } label: {
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

                    Label("\(entry.estimatedMinutes) minute \(entry.format == .reader ? "read" : "adventure")", systemImage: "clock")
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
                if entry.format == .reader {
                    Text(game.selectedID == entry.id && game.readerBook != nil
                         ? "PAGE \(game.readerPageIndex + 1) OF \(game.readerBook?.pages.count ?? 1)"
                         : "READ OR LISTEN")
                    Spacer()
                    Text(game.selectedID == entry.id && game.readerPageIndex > 0
                         ? "CONTINUE" : "OPEN")
                } else {
                    Text(selected?.progress.started == true
                         ? "\(count) / \(selected?.book.finalCount ?? 5) ENDINGS FOUND"
                         : "READY TO EXPLORE")
                    Spacer()
                    Text(selected?.progress.started == true && selected?.isComplete == false
                         ? "CONTINUE" : "READ")
                }
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


/// Stuffy Land's own illustrated shelf. The shared engine still opens both formats.
private struct StuffyLandShelf: View {
    let entries: [AdventureListing]
    let onOpen: (AdventureListing) -> Void
    let onSettings: () -> Void
    let onMemories: () -> Void
    let onRefresh: () -> Void
    let refreshing: Bool
    let message: String?
    @State private var filter = 0
    @State private var showingNotes = false

    private var filtered: [AdventureListing] {
        entries.filter { filter == 0 || (filter == 1 ? $0.format == .reader : $0.format == .adventure) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(spacing: 10) {
                    Image("stuffy-logo").resizable().scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stuffy Land")
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(StarportTheme.paper)
                        Text("Opal & friends")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(StarportTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Button(action: onMemories) {
                        Image(systemName: "book.closed").frame(width: 44, height: 44)
                    }.accessibilityLabel("Open the memory book")
                    Button(action: onSettings) {
                        Image(systemName: "gearshape").frame(width: 44, height: 44)
                    }.accessibilityLabel("Settings")
                }

                VStack(alignment: .leading, spacing: 0) {
                    Image("stuffy-tent")
                        .resizable().scaledToFit()
                        .accessibilityLabel("Opal and her sloth lovey Lolo read together in their purple galaxy tent.")
                    VStack(alignment: .leading, spacing: 10) {
                        Label("COME ON IN", systemImage: "sparkle")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .tracking(1.8).foregroundStyle(StarportTheme.orange)
                        Text("A little wonder.\nA lot of friends.")
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                            .foregroundStyle(StarportTheme.paper)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Settle in with a story, or help Opal choose what happens next.")
                            .font(.body).foregroundStyle(StarportTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }.padding(22)
                }
                .background(StarportTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .overlay {
                    RoundedRectangle(cornerRadius: 26)
                        .strokeBorder(StarportTheme.line.opacity(0.65), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Your story shelf")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(StarportTheme.paper)
                    Text("\(entries.filter { $0.format == .reader }.count) read-alongs · \(entries.filter { $0.format == .adventure }.count) adventures")
                        .font(.subheadline).foregroundStyle(StarportTheme.muted)
                    Picker("Story format", selection: $filter) {
                        Text("All stories").tag(0)
                        Text("Read or listen").tag(1)
                        Text("Adventures").tag(2)
                    }.pickerStyle(.segmented)
                }

                if entries.isEmpty {
                    Text(message ?? "Your story shelf couldn't open. Try checking for stories below.")
                        .foregroundStyle(StarportTheme.muted)
                }
                ForEach(filtered) { entry in
                    storyCard(entry)
                }

                VStack(alignment: .leading, spacing: 13) {
                    Label("A place for more stories", systemImage: "books.vertical")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(StarportTheme.paper)
                    Text("Your place is kept for you. Come back whenever you're ready.")
                        .font(.subheadline).foregroundStyle(StarportTheme.muted)
                    Button(action: onRefresh) {
                        HStack {
                            if refreshing { ProgressView().controlSize(.small) }
                            else { Image(systemName: "arrow.clockwise") }
                            Text(refreshing ? "Checking…" : "Check for new stories")
                        }.frame(minHeight: 44)
                    }.disabled(refreshing)
                    if let message {
                        Text(message).font(.footnote).foregroundStyle(StarportTheme.muted)
                    }
                    Button("About these stories") { showingNotes = true }
                        .font(.footnote).frame(minHeight: 44)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(StarportTheme.panel, in: RoundedRectangle(cornerRadius: 22))
                Text("STUFFY LAND · FOR READERS AGES 13+")
                    .font(.caption2).foregroundStyle(StarportTheme.muted)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center)
            }
            .frame(maxWidth: 650)
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showingNotes) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Stories from Opal’s world")
                            .font(.system(.title, design: .serif, weight: .bold))
                        Text("The Giggle Games was recovered in full. Pillow-Fort Mystery and Snore-Snatcher are interactive adaptations of complete stories, with new choices and endings.")
                        Text("Nine read-alongs were newly written from recovered plot summaries. The Treasure of the Thousand Traps is a new story inspired by its surviving title and premise. Their original wording wasn't available.")
                        Text("The stories celebrate friendship, imagination, and listening. The pictures are new interpretations of the supplied Stuffy Land references.")
                    }.padding(24).frame(maxWidth: 630)
                }
                .navigationTitle("About these stories")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingNotes = false } } }
            }.tint(StarportTheme.teal)
        }
    }

    private func storyCard(_ entry: AdventureListing) -> some View {
        Button { onOpen(entry) } label: {
            VStack(alignment: .leading, spacing: 0) {
                if entry.format == .adventure, let cover = entry.coverAsset {
                    Image(cover).resizable().scaledToFit().accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 15) {
                        if entry.format == .reader {
                            Image(systemName: entry.symbol)
                                .font(.system(size: 23, weight: .regular))
                                .foregroundStyle(StarportTheme.orange)
                                .frame(width: 52, height: 64)
                                .background(StarportTheme.teal.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.format == .reader ? "READ OR LISTEN" : "CHOOSE YOUR ADVENTURE")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .tracking(1.3).foregroundStyle(StarportTheme.orange)
                            Text(entry.title)
                                .font(.system(.title3, design: .serif, weight: .semibold))
                                .foregroundStyle(StarportTheme.paper)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(entry.subtitle)
                                .font(.subheadline).foregroundStyle(StarportTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    HStack(spacing: 8) {
                        Label("About \(entry.estimatedMinutes) min", systemImage: "clock")
                            .foregroundStyle(StarportTheme.muted)
                        Spacer(minLength: 4)
                        Text(entry.format == .reader ? "Open story" : "Explore")
                        Image(systemName: "arrow.right")
                    }.font(.system(.caption, design: .rounded, weight: .semibold))
                    if let note = entry.editorialNote {
                        Text(note.hasPrefix("Original") ? "Recovered original" : (entry.format == .adventure ? "Interactive adaptation" : "Adapted from the archive"))
                            .font(.caption2).foregroundStyle(StarportTheme.muted)
                    }
                }.padding(20)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StarportTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 23))
            .overlay {
                RoundedRectangle(cornerRadius: 23)
                    .inset(by: 6)
                    .strokeBorder(StarportTheme.line.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
