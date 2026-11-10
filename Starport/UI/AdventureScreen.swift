import SwiftUI

struct AdventureScreen: View {
    @EnvironmentObject private var game: GameStore
    let onExit: () -> Void

    @State private var confirmRestart = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if let engine = game.engine {
                    VStack(alignment: .leading, spacing: 23) {
                        Color.clear.frame(height: 0).id("top")
                        header
                        HStack(spacing: 13) {
                            ForEach(StoryStat.allCases, id: \.self) { stat in
                                StatPill(stat: stat, value: engine.progress.stats[stat])
                            }
                        }
                        .padding(16)
                        .background(StarportTheme.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 15))

                        VStack(alignment: .leading, spacing: 13) {
                            Text(engine.node.act)
                                .font(.system(.caption, design: .monospaced, weight: .bold))
                                .tracking(1.2)
                                .foregroundStyle(StarportTheme.orange)

                            Text(engine.node.title)
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(StarportTheme.paper)
                                .fixedSize(horizontal: false, vertical: true)

                            Rectangle()
                                .fill(StarportTheme.orange)
                                .frame(width: 36, height: 3)
                                .padding(.vertical, 5)

                            ForEach(Array(engine.node.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                                Text(paragraph)
                                    .font(.body)
                                    .foregroundStyle(StarportTheme.paper)
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.bottom, 5)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if let ending = engine.node.ending {
                            endingPanel(ending)
                        } else {
                            VStack(alignment: .leading, spacing: 13) {
                                Text("WHAT DO YOU DO?")
                                    .font(.system(.caption, design: .monospaced, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundStyle(StarportTheme.teal)

                                ForEach(engine.choices) { choice in
                                    ChoiceButton(
                                        choice: choice,
                                        stats: engine.progress.stats,
                                        flags: engine.progress.flags
                                    ) {
                                        game.choose(choice.id)
                                    }
                                }
                            }
                        }

                        Text("STARPORT NINE  /  FIELD NOTES")
                            .font(.system(.caption2, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(StarportTheme.muted.opacity(0.65))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    }
                    .frame(maxWidth: 650)
                    .padding(.horizontal, 22)
                    .padding(.top, 15)
                    .padding(.bottom, 45)
                    .frame(maxWidth: .infinity)
                }
            }
            .onChange(of: game.engine?.progress.nodeID) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
        .confirmationDialog(
            "Start again?",
            isPresented: $confirmRestart,
            titleVisibility: .visible
        ) {
            Button("Start a new run", role: .destructive) { game.restart() }
        } message: {
            Text("Your current choices will reset. Discovered endings will be kept.")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { game.errorMessage != nil },
            set: { isShowing in if !isShowing { game.dismissError() } }
        )) {
            Button("OK") { game.dismissError() }
        } message: {
            Text(game.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Button(action: onExit) {
                Label("Library", systemImage: "arrow.left")
                    .font(.subheadline.weight(.semibold))
            }
            .accessibilityHint("Your progress is saved automatically.")
            Spacer()
            Text("STARPORT  /  01")
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .tracking(1)
                .foregroundStyle(StarportTheme.muted)
            Spacer()
            Button {
                confirmRestart = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Restart adventure")
        }
    }

    private func endingPanel(_ ending: StoryEnding) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("ENDING FOUND", systemImage: "star.fill")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .tracking(1)
                .foregroundStyle(StarportTheme.orange)
            Text(ending.title)
                .font(.title2.bold())
                .foregroundStyle(StarportTheme.paper)
            Text(ending.note)
                .foregroundStyle(StarportTheme.muted)
            Text("\(game.engine?.progress.endingsFound.count ?? 0) of 6 endings discovered")
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(StarportTheme.teal)
                .padding(.bottom, 5)
            PrimaryAction(label: "Try a different path") {
                game.restart()
            }
            Button("Back to library", action: onExit)
                .font(.subheadline.weight(.semibold))
                .padding(.top, 5)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StarportTheme.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(StarportTheme.orange.opacity(0.75), lineWidth: 1)
        }
    }
}

private struct ChoiceButton: View {
    let choice: StoryChoice
    let stats: AdventureStats
    let flags: Set<String>
    let onSelect: () -> Void

    private var available: Bool {
        choice.isAvailable(stats: stats, flags: flags)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Text(choice.label)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Image(systemName: available ? "arrow.up.right" : "lock.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(available ? StarportTheme.teal : StarportTheme.muted)
                }
                if let detail = choice.detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(StarportTheme.muted)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let reason = choice.lockedReason(stats: stats, flags: flags) {
                    Text(reason)
                        .font(.system(.caption, design: .monospaced, weight: .semibold))
                        .foregroundStyle(StarportTheme.orange)
                        .multilineTextAlignment(.leading)
                } else {
                    let changes = (choice.effects ?? []).compactMap { effect -> String? in
                        guard let stat = effect.stat, let delta = effect.delta else { return nil }
                        return "\(delta > 0 ? "+" : "")\(delta) \(stat.title)"
                    }
                    if !changes.isEmpty {
                        Text(changes.joined(separator: "   ·   "))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(StarportTheme.teal)
                    }
                }
            }
            .foregroundStyle(available ? StarportTheme.paper : StarportTheme.muted)
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StarportTheme.panel.opacity(available ? 0.98 : 0.55), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(available ? StarportTheme.line : StarportTheme.line.opacity(0.45), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!available)
        .accessibilityLabel(available ? choice.label : "\(choice.label). Locked. \(choice.lockedReason(stats: stats, flags: flags) ?? "")")
    }
}
