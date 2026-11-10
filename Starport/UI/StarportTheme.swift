import SwiftUI

enum StarportTheme {
    static let ink = Color(red: 0.035, green: 0.068, blue: 0.12)
    static let panel = Color(red: 0.085, green: 0.135, blue: 0.21)
    static let line = Color(red: 0.24, green: 0.33, blue: 0.42)
    static let teal = Color(red: 0.47, green: 0.91, blue: 0.88)
    static let orange = Color(red: 1, green: 0.66, blue: 0.40)
    static let paper = Color(red: 0.95, green: 0.96, blue: 0.95)
    static let muted = Color(red: 0.68, green: 0.76, blue: 0.79)
}

struct Starfield: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [StarportTheme.ink, Color(red: 0.06, green: 0.11, blue: 0.19), StarportTheme.ink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Canvas { context, size in
                    // Repeatable star positions, so the background never jumps on redraw.
                    for index in 0..<90 {
                        let x = CGFloat((index * 127 + 37) % 997) / 997 * size.width
                        let y = CGFloat((index * 293 + 79) % 991) / 991 * size.height
                        let radius = index.isMultiple(of: 9) ? 1.6 : 0.65
                        let opacity = index.isMultiple(of: 5) ? 0.6 : 0.25
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                            with: .color(.white.opacity(opacity))
                        )
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct OrbitArtwork: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack {
                Ellipse()
                    .stroke(StarportTheme.line.opacity(0.7), lineWidth: 1)
                    .frame(width: width * 0.90, height: width * 0.34)
                    .rotationEffect(.degrees(-25))
                Ellipse()
                    .stroke(StarportTheme.teal.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [4, 9]))
                    .frame(width: width * 0.94, height: width * 0.37)
                    .rotationEffect(.degrees(28))
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [StarportTheme.orange, Color(red: 0.68, green: 0.26, blue: 0.27), Color(red: 0.25, green: 0.17, blue: 0.25)],
                            center: .init(x: 0.25, y: 0.23),
                            startRadius: 4,
                            endRadius: width * 0.4
                        )
                    )
                    .frame(width: width * 0.43, height: width * 0.43)
                    .overlay {
                        Circle().stroke(.white.opacity(0.15), lineWidth: 1)
                    }
                    .shadow(color: StarportTheme.orange.opacity(0.12), radius: 32)
                Image(systemName: "airplane")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(StarportTheme.teal)
                    .rotationEffect(.degrees(-35))
                    .offset(x: width * 0.33, y: -width * 0.10)
                Circle()
                    .fill(StarportTheme.teal)
                    .frame(width: 6, height: 6)
                    .offset(x: -width * 0.4, y: width * 0.06)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }
}

struct StarportMasthead: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(StarportTheme.teal)
            Text("STARPORT")
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .tracking(3)
                .foregroundStyle(StarportTheme.paper)
            Spacer()
            Text("EST. 2187")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(StarportTheme.muted)
        }
    }
}

struct StatPill: View {
    let stat: StoryStat
    let value: Int

    private var color: Color {
        switch stat {
        case .clues: return StarportTheme.teal
        case .power: return StarportTheme.orange
        case .trust: return StarportTheme.paper
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(stat.title.uppercased())
                .font(.system(.caption2, design: .monospaced, weight: .semibold))
                .tracking(1)
                .foregroundStyle(StarportTheme.muted)
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < value ? color : StarportTheme.line)
                        .frame(height: 5)
                }
            }
            Text("\(value)/5")
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stat.title), \(value) out of 5")
    }
}

struct PrimaryAction: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.headline)
            }
            .foregroundStyle(StarportTheme.ink)
            .padding(19)
            .background(StarportTheme.teal, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }
}
