import SwiftUI

struct StarportRootView: View {
    @EnvironmentObject private var game: GameStore
    @EnvironmentObject private var purchases: PurchaseManager
    @EnvironmentObject private var ads: AdsController

    @AppStorage("starport.confirmed13Plus") private var ageConfirmed = false
    private var canOpenLibrary: Bool { !AppBrand.current.requiresInAppAgeConfirmation || ageConfirmed }
    @State private var reading = false
    @State private var showingSettings = false
    @State private var showingAchievements = false

    var body: some View {
        ZStack {
            Starfield()
            if !canOpenLibrary {
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
            if canOpenLibrary, purchases.entitlementsLoaded, !purchases.isAdFree,
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
        .task(id: canOpenLibrary) {
            guard canOpenLibrary else { return }
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


/// Stuffy Land's compact bookshelf. Open a book straight from the shelf;
/// the first screen is for choosing a story, not reading marketing copy.
private struct StuffyLandShelf: View {
    @EnvironmentObject private var game: GameStore

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
        entries.filter {
            filter == 0 || (filter == 1 ? $0.format == .reader : $0.format == .adventure)
        }
    }

    // Don't offer "Continue" until someone has actually begun reading.
    // The selected ID belongs to this app and persists between launches.
    private var unfinishedStory: AdventureListing? {
        guard let selectedID = game.selectedID,
              let entry = entries.first(where: { $0.id == selectedID }) else {
            return nil
        }
        if entry.format == .reader {
            return game.readerBook != nil && game.readerPageIndex > 0 ? entry : nil
        }
        guard let engine = game.engine,
              engine.progress.started, !engine.isComplete else {
            return nil
        }
        return entry
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 11) {
                    Image("stuffy-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .accessibilityHidden(true)
                    Text("Stuffy Land")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(StarportTheme.paper)

                    Spacer(minLength: 4)

                    Button(action: onMemories) {
                        Image(systemName: "book.closed")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Memory book")

                    Button(action: onSettings) {
                        Image(systemName: "gearshape")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Settings")
                }
                .padding(.bottom, 4)

                if let unfinishedStory {
                    Button { onOpen(unfinishedStory) } label: {
                        HStack(spacing: 13) {
                            storyCover(unfinishedStory, size: 60)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Continue")
                                    .font(.system(.caption, design: .rounded, weight: .bold))
                                    .foregroundStyle(StarportTheme.orange)
                                Text(unfinishedStory.title)
                                    .font(.system(.body, design: .serif, weight: .semibold))
                                    .foregroundStyle(StarportTheme.paper)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(StarportTheme.teal)
                        }
                        .padding(12)
                        .background(StarportTheme.panel,
                                    in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(StarportTheme.teal.opacity(0.45), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Continue \(unfinishedStory.title)")
                }

                HStack {
                    Text("Stories")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(StarportTheme.paper)
                    Spacer()
                }
                .padding(.top, 3)

                Picker("Story format", selection: $filter) {
                    Text("All").tag(0)
                    Text("Read-alongs").tag(1)
                    Text("Adventures").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 3)

                if entries.isEmpty {
                    Text(message ?? "Couldn't open the story shelf. Please try again.")
                        .foregroundStyle(StarportTheme.muted)
                        .padding(.vertical, 20)
                }

                ForEach(filtered) { entry in
                    storyRow(entry)
                }

                HStack(spacing: 22) {
                    Button {
                        onRefresh()
                    } label: {
                        Label(refreshing ? "Checking…" : "Check for stories",
                              systemImage: "arrow.clockwise")
                            .frame(minHeight: 44)
                    }
                    .disabled(refreshing)

                    Spacer(minLength: 0)

                    Button("About these stories") {
                        showingNotes = true
                    }
                    .frame(minHeight: 44)
                }
                .font(.footnote.weight(.medium))
                .padding(.top, 12)

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(StarportTheme.muted)
                }
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
        .sheet(isPresented: $showingNotes) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("About the stories")
                            .font(.system(.title, design: .serif, weight: .bold))
                        Text("The Giggle Games preserves the recovered original story. Pillow-Fort Mystery and Snore-Snatcher adapt complete stories with new choices and endings.")
                        Text("Nine read-alongs are based on surviving story summaries. The Treasure of the Thousand Traps is new fiction inspired by its surviving title and premise.")
                        Text("Opal and the Great Sundae Switch is a new original choose-your-own-adventure.")
                    }
                    .padding(24)
                    .frame(maxWidth: 600)
                }
                .navigationTitle("About")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingNotes = false }
                    }
                }
            }
            .tint(StarportTheme.teal)
        }
    }

    @ViewBuilder
    private func storyCover(_ entry: AdventureListing, size: CGFloat) -> some View {
        if let cover = entry.coverAsset {
            Image(cover)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
        } else {
            Image(systemName: entry.symbol)
                .font(.system(size: size * 0.34))
                .foregroundStyle(StarportTheme.orange)
                .frame(width: size, height: size)
                .background(StarportTheme.teal.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
        }
    }

    private func storyRow(_ entry: AdventureListing) -> some View {
        Button { onOpen(entry) } label: {
            HStack(spacing: 14) {
                storyCover(entry, size: 72)

                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.title)
                        .font(.system(.body, design: .serif, weight: .semibold))
                        .foregroundStyle(StarportTheme.paper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(entry.format == .reader ? "Read or listen" : "Choose an adventure")
                        .font(.caption)
                        .foregroundStyle(StarportTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(StarportTheme.teal)
            }
            .padding(11)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .background(StarportTheme.panel,
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(StarportTheme.line.opacity(0.55), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.title). \(entry.format == .reader ? "Read or listen" : "Choose an adventure").")
        .accessibilityHint("Open story")
    }
}
