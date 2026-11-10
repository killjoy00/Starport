import SwiftUI
import UIKit

enum AppearanceMode: String, CaseIterable, Identifiable {
    case dark, light, system
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var scheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}

enum StarportTheme {
    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }
    static let ink = AppBrand.current.isStuffyLand ? adaptive(
        light: UIColor(red: 0.972, green: 0.950, blue: 0.923, alpha: 1),
        dark: UIColor(red: 0.092, green: 0.084, blue: 0.154, alpha: 1)) : adaptive(
        light: UIColor(red: 0.955, green: 0.969, blue: 0.978, alpha: 1),
        dark: UIColor(red: 0.035, green: 0.068, blue: 0.12, alpha: 1))
    static let panel = AppBrand.current.isStuffyLand ? adaptive(
        light: UIColor(red: 1, green: 0.990, blue: 0.974, alpha: 1),
        dark: UIColor(red: 0.168, green: 0.145, blue: 0.220, alpha: 1)) : adaptive(
        light: UIColor(red: 0.996, green: 0.997, blue: 1, alpha: 1),
        dark: UIColor(red: 0.085, green: 0.135, blue: 0.21, alpha: 1))
    static let line = AppBrand.current.isStuffyLand ? adaptive(
        light: UIColor(red: 0.80, green: 0.74, blue: 0.74, alpha: 1),
        dark: UIColor(red: 0.37, green: 0.31, blue: 0.42, alpha: 1)) : adaptive(
        light: UIColor(red: 0.77, green: 0.82, blue: 0.86, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.33, blue: 0.42, alpha: 1))
    static let teal = AppBrand.current.isStuffyLand ? adaptive(
        light: UIColor(red: 0.43, green: 0.27, blue: 0.58, alpha: 1),
        dark: UIColor(red: 0.83, green: 0.68, blue: 0.98, alpha: 1)) : adaptive(
        light: UIColor(red: 0.02, green: 0.42, blue: 0.44, alpha: 1),
        dark: UIColor(red: 0.47, green: 0.91, blue: 0.88, alpha: 1))
    static let orange = AppBrand.current.isStuffyLand ? adaptive(
        light: UIColor(red: 0.66, green: 0.33, blue: 0.29, alpha: 1),
        dark: UIColor(red: 0.98, green: 0.73, blue: 0.57, alpha: 1)) : adaptive(
        light: UIColor(red: 0.63, green: 0.28, blue: 0.12, alpha: 1),
        dark: UIColor(red: 1, green: 0.66, blue: 0.40, alpha: 1))
    static let paper = AppBrand.current.isStuffyLand ? adaptive(
        light: UIColor(red: 0.20, green: 0.16, blue: 0.24, alpha: 1),
        dark: UIColor(red: 0.98, green: 0.95, blue: 0.94, alpha: 1)) : adaptive(
        light: UIColor(red: 0.075, green: 0.13, blue: 0.20, alpha: 1),
        dark: UIColor(red: 0.95, green: 0.96, blue: 0.95, alpha: 1))
    static let muted = AppBrand.current.isStuffyLand ? adaptive(
        light: UIColor(red: 0.43, green: 0.38, blue: 0.46, alpha: 1),
        dark: UIColor(red: 0.79, green: 0.72, blue: 0.83, alpha: 1)) : adaptive(
        light: UIColor(red: 0.31, green: 0.40, blue: 0.45, alpha: 1),
        dark: UIColor(red: 0.68, green: 0.76, blue: 0.79, alpha: 1))
}

struct Starfield: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [StarportTheme.ink, StarportTheme.panel.opacity(0.8), StarportTheme.ink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Canvas { context, size in
                    for index in 0..<90 {
                        let x = CGFloat((index * 127 + 37) % 997) / 997 * size.width
                        let y = CGFloat((index * 293 + 79) % 991) / 991 * size.height
                        let diameter = index.isMultiple(of: 9) ? 3.2 : 1.3
                        let opacity = index.isMultiple(of: 5) ? 0.35 : 0.16
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                            with: .color((scheme == .dark ? Color.white : Color.black).opacity(opacity))
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
        if AppBrand.current.isStuffyLand {
            StorybookPlushArtwork()
        } else {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack {
                Ellipse()
                    .stroke(StarportTheme.line.opacity(0.7), lineWidth: 1)
                    .frame(width: width * 0.90, height: width * 0.34)
                    .rotationEffect(.degrees(-25))
                Ellipse()
                    .stroke(StarportTheme.teal.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 9]))
                    .frame(width: width * 0.94, height: width * 0.37)
                    .rotationEffect(.degrees(28))
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.orange, Color(red: 0.68, green: 0.26, blue: 0.27),
                                     Color(red: 0.25, green: 0.17, blue: 0.25)],
                            center: .init(x: 0.25, y: 0.23),
                            startRadius: 4, endRadius: width * 0.4
                        )
                    )
                    .frame(width: width * 0.43, height: width * 0.43)
                    .overlay { Circle().stroke(.white.opacity(0.15), lineWidth: 1) }
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
}


struct StorybookPlushArtwork: View {
    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                Ellipse()
                    .fill(StarportTheme.teal.opacity(0.2))
                    .frame(width: side * 1.4, height: side * 0.6)
                    .offset(y: side * 0.35)
                Circle()
                    .fill(StarportTheme.orange)
                    .frame(width: side * 0.27, height: side * 0.27)
                    .offset(x: -side * 0.24, y: -side * 0.20)
                Circle()
                    .fill(StarportTheme.orange)
                    .frame(width: side * 0.27, height: side * 0.27)
                    .offset(x: side * 0.24, y: -side * 0.20)
                Capsule()
                    .fill(StarportTheme.orange)
                    .frame(width: side * 0.50, height: side * 0.48)
                    .offset(y: side * 0.30)
                Circle()
                    .fill(StarportTheme.orange)
                    .frame(width: side * 0.62, height: side * 0.57)
                HStack(spacing: side * 0.22) {
                    Circle().fill(StarportTheme.ink).frame(width: 7, height: 7)
                    Circle().fill(StarportTheme.ink).frame(width: 7, height: 7)
                }
                .offset(y: -side * 0.06)
                Ellipse()
                    .fill(StarportTheme.paper.opacity(0.80))
                    .frame(width: side * 0.22, height: side * 0.14)
                    .offset(y: side * 0.10)
                Image(systemName: "heart.fill")
                    .font(.system(size: side * 0.10))
                    .foregroundStyle(StarportTheme.teal)
                    .offset(y: side * 0.34)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }
}

struct StarportMasthead: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: AppBrand.current.isStuffyLand ? "heart.fill" : "dot.radiowaves.left.and.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(StarportTheme.teal)
            Text(AppBrand.current.masthead)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .tracking(3)
                .foregroundStyle(StarportTheme.paper)
            Spacer()
            Text(AppBrand.current.tagline)
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
            Text(AppBrand.current.statTitle(stat).uppercased())
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
        .accessibilityLabel("\(AppBrand.current.statTitle(stat)), \(value) out of 5")
    }
}

struct PrimaryAction: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label).font(.headline)
                Spacer()
                Image(systemName: "arrow.up.right").font(.headline)
            }
            .foregroundStyle(StarportTheme.ink)
            .padding(19)
            .background(StarportTheme.teal, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
    }
}
