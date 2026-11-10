import SwiftUI

struct StarportRootView: View {
    @EnvironmentObject private var game: GameStore
    @State private var reading = false

    var body: some View {
        ZStack {
            Starfield()
            if game.engine == nil {
                unavailable
            } else if reading {
                AdventureScreen(onExit: { reading = false })
            } else {
                home
            }
        }
        .tint(StarportTheme.teal)
    }

    private var unavailable: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(StarportTheme.orange)
            Text("Signal lost")
                .font(.title.bold())
            Text(game.errorMessage ?? "The story could not be loaded.")
                .foregroundStyle(StarportTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(30)
    }

    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                StarportMasthead()
                    .padding(.top, 18)

                OrbitArtwork()
                    .frame(height: 240)
                    .padding(.vertical, 5)

                VStack(alignment: .leading, spacing: 12) {
                    Text("EPISODE 01  /  SCI-FI MYSTERY")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .tracking(1.7)
                        .foregroundStyle(StarportTheme.orange)

                    Text("The Door That Opens Tomorrow")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(StarportTheme.paper)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("A ship that's due tomorrow sends a warning today. You're the one who hears it.")
                        .font(.title3)
                        .foregroundStyle(StarportTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                            .foregroundStyle(StarportTheme.orange)
                        Text("Your choices change the story.")
                            .foregroundStyle(StarportTheme.paper)
                            .font(.headline)
                    }
                    Text("Collect clues. Decide who to trust. Keep enough power for the moment that counts. Six endings are waiting to be found.")
                        .font(.body)
                        .foregroundStyle(StarportTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Text("\(game.engine?.progress.endingsFound.count ?? 0) OF 6 ENDINGS DISCOVERED")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .tracking(0.8)
                        Spacer()
                        Image(systemName: "bookmark")
                    }
                    .foregroundStyle(StarportTheme.teal)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(StarportTheme.panel.opacity(0.9), in: RoundedRectangle(cornerRadius: 17))
                .overlay {
                    RoundedRectangle(cornerRadius: 17)
                        .strokeBorder(StarportTheme.line.opacity(0.7))
                }

                PrimaryAction(label: startLabel) {
                    if game.engine?.isComplete == true {
                        game.restart()
                    } else {
                        game.begin()
                    }
                    reading = true
                }

                Text("Offline adventure  ·  No account needed  ·  Progress saved on this device")
                    .font(.footnote)
                    .foregroundStyle(StarportTheme.muted)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
        }
    }

    private var startLabel: String {
        guard let engine = game.engine else { return "Read the adventure" }
        if engine.isComplete { return "Find another ending" }
        return engine.progress.started ? "Continue adventure" : "Begin adventure"
    }
}
