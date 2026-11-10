import SwiftUI

/// A distraction-free paged reader for linear stories. The same shelf also
/// contains branching games, but these books never show choices or endings.
struct BookReaderView: View {
    @EnvironmentObject private var game: GameStore
    let onExit: () -> Void

    @StateObject private var narrator = StoryNarrator()
    @AppStorage("stuffyland.readerTextSize") private var textSize = 19
    @AppStorage("stuffyland.readerSpeechSpeed") private var speechSpeed = 1.0

    private var book: RegularBook? { game.readerBook }

    private var page: RegularBookPage? {
        guard let book, book.pages.indices.contains(game.readerPageIndex) else { return nil }
        return book.pages[game.readerPageIndex]
    }

    var body: some View {
        ZStack {
            Starfield()
            if let book, let page {
                ScrollViewReader { scroll in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 23) {
                            HStack {
                                Button {
                                    narrator.stop()
                                    onExit()
                                } label: {
                                    Label("Library", systemImage: "arrow.left")
                                }
                                .accessibilityHint("Your place in this book is saved.")
                                Spacer()
                                Text("READING MODE")
                                    .font(.system(.caption2, design: .rounded, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundStyle(StarportTheme.muted)
                            }
                            .font(.subheadline.weight(.semibold))
                            .id("page-top")

                            VStack(alignment: .leading, spacing: 8) {
                                Text(book.title)
                                    .font(.system(.title2, design: .serif, weight: .bold))
                                    .foregroundStyle(StarportTheme.paper)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let author = book.author {
                                    Text("By \(author)")
                                        .font(.subheadline)
                                        .foregroundStyle(StarportTheme.muted)
                                }
                                Text("PAGE \(game.readerPageIndex + 1) OF \(book.pages.count)")
                                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                                    .tracking(1.2)
                                    .foregroundStyle(StarportTheme.teal)
                                ProgressView(
                                    value: Double(game.readerPageIndex + 1),
                                    total: Double(book.pages.count)
                                )
                                .tint(StarportTheme.teal)
                                .accessibilityLabel(
                                    "Page \(game.readerPageIndex + 1) of \(book.pages.count)"
                                )
                            }

                            narrationControls

                            VStack(alignment: .leading, spacing: 20) {
                                if let heading = page.heading {
                                    Text(heading)
                                        .font(.system(size: CGFloat(textSize + 7),
                                                      weight: .semibold, design: .serif))
                                        .foregroundStyle(StarportTheme.paper)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                if let illustration = page.illustration {
                                    StoryIllustrationView(illustration: illustration)
                                }
                                ForEach(Array(page.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                                    Text(paragraph)
                                        .font(.system(size: CGFloat(textSize), design: .serif))
                                        .lineSpacing(8)
                                        .foregroundStyle(StarportTheme.paper)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)

                            HStack(spacing: 13) {
                                Button {
                                    narrator.stop()
                                    game.previousReaderPage()
                                } label: {
                                    Label("Previous", systemImage: "arrow.left")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(.bordered)
                                .disabled(game.readerPageIndex == 0)

                                if game.readerPageIndex + 1 < book.pages.count {
                                    Button {
                                        narrator.stop()
                                        game.nextReaderPage()
                                    } label: {
                                        Label("Next", systemImage: "arrow.right")
                                            .labelStyle(.titleAndIcon)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                    }
                                    .buttonStyle(.borderedProminent)
                                } else {
                                    Button {
                                        narrator.stop()
                                        onExit()
                                    } label: {
                                        Label("Close book", systemImage: "checkmark")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.top, 5)

                            Text("Your place is saved automatically on this device.")
                                .font(.footnote)
                                .foregroundStyle(StarportTheme.muted)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: 630)
                        .padding(.horizontal, 24)
                        .padding(.top, 17)
                        .padding(.bottom, 48)
                        .frame(maxWidth: .infinity)
                    }
                    .onChange(of: game.readerPageIndex) { _, _ in
                        withAnimation(.easeOut(duration: 0.18)) {
                            scroll.scrollTo("page-top", anchor: .top)
                        }
                    }
                }
            }
        }
        .tint(StarportTheme.teal)
        .onDisappear { narrator.stop() }
    }

    private var narrationControls: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Label("READ ALOUD", systemImage: "waveform")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(StarportTheme.orange)
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "textformat.size.smaller")
                    Button("A−") { textSize = max(15, textSize - 2) }
                        .accessibilityLabel("Decrease text size")
                    Button("A+") { textSize = min(27, textSize + 2) }
                        .accessibilityLabel("Increase text size")
                }
                .font(.subheadline.weight(.semibold))
            }

            HStack(spacing: 12) {
                if narrator.isPlaying {
                    Button {
                        if narrator.isPaused { narrator.resume() }
                        else { narrator.pause() }
                    } label: {
                        Label(narrator.isPaused ? "Resume" : "Pause",
                              systemImage: narrator.isPaused ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    Button {
                        narrator.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        readCurrentPage()
                    } label: {
                        Label("Read to me", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .font(.subheadline.weight(.semibold))
            .controlSize(.large)

            HStack {
                Text("Voice speed")
                    .font(.footnote)
                    .foregroundStyle(StarportTheme.muted)
                Spacer()
                Picker("Voice speed", selection: $speechSpeed) {
                    Text("Slow").tag(0.85)
                    Text("Normal").tag(1.0)
                    Text("Fast").tag(1.15)
                }
                .pickerStyle(.menu)
                .disabled(narrator.isPlaying)
            }
            Text("Uses your iPhone's built-in voice. Narration continues through the book until you pause or stop.")
                .font(.footnote)
                .foregroundStyle(StarportTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(17)
        .background(StarportTheme.panel, in: RoundedRectangle(cornerRadius: 17))
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .strokeBorder(StarportTheme.line, lineWidth: 1)
        }
    }

    private func readCurrentPage() {
        guard let book, let page else { return }
        let lines = ([page.heading ?? book.title] + page.paragraphs).joined(separator: "\n\n")
        narrator.read(lines, speed: Float(speechSpeed)) {
            guard let book = game.readerBook,
                  game.readerPageIndex + 1 < book.pages.count else { return }
            game.nextReaderPage()
            readCurrentPage()
        }
    }
}
