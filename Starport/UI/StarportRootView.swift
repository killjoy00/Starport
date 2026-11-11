import SwiftUI
import UIKit

struct StarportRootView: View {
    @EnvironmentObject private var game: GameStore
    @EnvironmentObject private var purchases: PurchaseManager
    @EnvironmentObject private var ads: AdsController

    @AppStorage("starport.confirmed13Plus") private var ageConfirmed = false
    private var canOpenLibrary: Bool { !AppBrand.current.requiresInAppAgeConfirmation || ageConfirmed }
    @State private var reading = false
    @State private var showingSettings = false
    @State private var showingAchievements = false
    // This brief, skippable opening belongs only to the Stuffy Land app.
    @State private var showingStuffyOpening = AppBrand.current.isStuffyLand

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
            if AppBrand.current.isStuffyLand && showingStuffyOpening {
                StuffyOpeningSequence {
                    withAnimation(.easeOut(duration: 0.22)) {
                        showingStuffyOpening = false
                    }
                }
                .transition(.opacity)
                .zIndex(20)
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

    // StarPort's home is separate from the Stuffy Land bookshelf below.
    private var featuredStory: AdventureListing? {
        let entries = game.catalog?.adventures ?? []
        return entries.first(where: { $0.id == game.selectedID }) ?? entries.first
    }

    private var library: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 21) {
                HStack(spacing: 8) {
                    Text("StarPort")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(StarportTheme.paper)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 4)
                    Button { showingAchievements = true } label: {
                        Label("Endings", systemImage: "trophy")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(StarportTheme.paper)
                            .padding(.horizontal, 8)
                            .frame(minHeight: 44)
                    }
                    .accessibilityLabel("Discovered endings and achievements")
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundStyle(StarportTheme.paper)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Settings")
                }

                if let feature = featuredStory {
                    Text(featuredAction(for: feature).hasPrefix("Continue") ? "KEEP READING" : "FEATURED STORY")
                        .font(.caption.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(StarportTheme.muted)
                    featuredCard(feature)

                    let otherStories = (game.catalog?.adventures ?? []).filter { $0.id != feature.id }
                    if !otherStories.isEmpty {
                        Text("More stories")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(StarportTheme.paper)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, 5)
                        ForEach(otherStories) { entry in
                            compactStoryRow(entry)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your stories couldn't load")
                            .font(.title2.bold())
                            .foregroundStyle(StarportTheme.paper)
                        Text(game.errorMessage ?? "Try checking for stories or reopening StarPort.")
                            .font(.subheadline)
                            .foregroundStyle(StarportTheme.muted)
                    }
                }

                Button {
                    Task { await game.refreshLibrary() }
                } label: {
                    HStack(spacing: 9) {
                        if game.isRefreshing { ProgressView().controlSize(.small) }
                        else { Image(systemName: "arrow.clockwise") }
                        Text(game.isRefreshing ? "Checking stories…" : "Check for new stories")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(StarportTheme.teal)
                    .frame(minHeight: 44)
                }
                .disabled(game.isRefreshing)

                if let note = game.libraryMessage ?? game.errorMessage {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(StarportTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: 620)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity)
        }
    }

    private func featuredAction(for entry: AdventureListing) -> String {
        guard game.selectedID == entry.id else {
            return entry.format == .reader ? "Read story" : "Start adventure"
        }
        if entry.format == .reader {
            return game.readerPageIndex > 0 ? "Continue reading" : "Read story"
        }
        guard let engine = game.engine, engine.progress.started else { return "Start adventure" }
        return engine.isComplete ? "Find another ending" : "Continue adventure"
    }

    private func featuredStatus(for entry: AdventureListing) -> String {
        guard game.selectedID == entry.id else { return "About \(entry.estimatedMinutes) min" }
        if entry.format == .reader, let book = game.readerBook {
            return "Page \(game.readerPageIndex + 1) of \(book.pages.count)"
        }
        if let engine = game.engine {
            if engine.progress.started && !engine.isComplete {
                return "\(engine.progress.decisionCount) decisions made · \(engine.progress.endingsFound.count) endings found"
            }
            if !engine.progress.endingsFound.isEmpty {
                return "\(engine.progress.endingsFound.count) of \(engine.book.finalCount) endings found"
            }
        }
        return "About \(entry.estimatedMinutes) min"
    }

    private func featuredCard(_ entry: AdventureListing) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 15) {
                if let cover = entry.coverAsset {
                    Image(cover)
                        .resizable().scaledToFill()
                        .frame(width: 112, height: 168)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: entry.symbol)
                        .font(.system(size: 35))
                        .foregroundStyle(StarportTheme.orange)
                        .frame(width: 112, height: 168)
                        .background(StarportTheme.ink, in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.format == .reader ? "READ OR LISTEN" : "CHOOSE YOUR PATH")
                        .font(.caption2.weight(.semibold))
                        .tracking(0.5)
                        .foregroundStyle(StarportTheme.orange)
                    Text(entry.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .tracking(-0.4)
                        .foregroundStyle(StarportTheme.paper)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(entry.blurb)
                        .font(.subheadline)
                        .foregroundStyle(StarportTheme.muted)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Label(featuredStatus(for: entry), systemImage: "bookmark")
                .font(.caption)
                .foregroundStyle(StarportTheme.muted)
            Button { openStory(entry) } label: {
                HStack {
                    Text(featuredAction(for: entry))
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(StarportTheme.ink)
                .padding(.horizontal, 18)
                .frame(minHeight: 54)
                .background(StarportTheme.teal, in: RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Open \(entry.title)")
        }
        .padding(18)
        .background(StarportTheme.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(StarportTheme.line.opacity(0.6), lineWidth: 1)
        }
    }

    private func compactStoryRow(_ entry: AdventureListing) -> some View {
        Button { openStory(entry) } label: {
            HStack(spacing: 13) {
                if let cover = entry.coverAsset {
                    Image(cover)
                        .resizable().scaledToFill()
                        .frame(width: 59, height: 84)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: entry.symbol)
                        .foregroundStyle(StarportTheme.orange)
                        .frame(width: 59, height: 84)
                        .background(StarportTheme.ink, in: RoundedRectangle(cornerRadius: 7))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(StarportTheme.paper)
                        .multilineTextAlignment(.leading)
                    Text(entry.subtitle)
                        .font(.caption)
                        .foregroundStyle(StarportTheme.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(entry.format == .reader ? "Read or listen" : "Interactive story")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(StarportTheme.teal)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(StarportTheme.muted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StarportTheme.panel, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Open \(entry.title)")
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


/// A short storybook curtain-raising sequence for Stuffy Land only.
/// The six hand-illustrated frames are cropped from one asset-catalog atlas.
/// Runs once per app launch, never when returning to the shelf or a saved book.
private struct StuffyOpeningSequence: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frameIndex = 0

    private static let frames: [UIImage] = {
        guard let source = UIImage(named: "stuffy-intro-frames")?.cgImage else {
            return []
        }
        let columns = 3
        let frameWidth = source.width / columns
        let frameHeight = source.height / 2
        return (0..<6).compactMap { number in
            let rect = CGRect(
                x: (number % columns) * frameWidth,
                y: (number / columns) * frameHeight,
                width: frameWidth,
                height: frameHeight
            )
            guard let cropped = source.cropping(to: rect) else { return nil }
            return UIImage(cgImage: cropped)
        }
    }()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Color(red: 0.13, green: 0.07, blue: 0.2)
                if Self.frames.indices.contains(frameIndex) {
                    Image(uiImage: Self.frames[frameIndex])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width,
                               height: geometry.size.height)
                        .clipped()
                        .accessibilityHidden(true)
                }

                Button(action: onFinish) {
                    Text("Skip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 17)
                        .frame(minHeight: 44)
                        .background(.black.opacity(0.42),
                                    in: Capsule())
                }
                .accessibilityLabel("Skip Stuffy Land opening")
                .padding(.trailing, 20)
                .padding(.top, 54)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .onTapGesture(perform: onFinish)
        }
        .ignoresSafeArea()
        .task {
            // Respect Reduce Motion and avoid delaying a reader who needs
            // an immediate, predictable path to the shelf.
            if reduceMotion || Self.frames.count != 6 {
                onFinish()
                return
            }
            for next in 1..<6 {
                do {
                    try await Task.sleep(nanoseconds: 270_000_000)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                frameIndex = next
            }
            do {
                try await Task.sleep(nanoseconds: 550_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            onFinish()
        }
    }
}
