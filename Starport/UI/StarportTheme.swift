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
    private static func palette(_ light: UInt32, _ dark: UInt32, _ starLight: UInt32, _ starDark: UInt32) -> Color {
        func ui(_ hex: UInt32) -> UIColor {
            UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                    green: CGFloat((hex >> 8) & 255) / 255,
                    blue: CGFloat(hex & 255) / 255, alpha: 1)
        }
        let isStuffy = AppBrand.current.isStuffyLand
        let day = ui(isStuffy ? light : starLight)
        let night = ui(isStuffy ? dark : starDark)
        return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? night : day })
    }
    static let ink = palette(0xF8F1E8, 0x21152E, 0xF4F7F9, 0x09111F)
    static let panel = palette(0xFFFBF5, 0x32213F, 0xFEFEFF, 0x162236)
    static let line = palette(0xD2C1D7, 0x695274, 0xC4D1DB, 0x3D546B)
    static let teal = palette(0x714391, 0xD8B9F2, 0x056B70, 0x78E8E0)
    static let orange = palette(0x91551D, 0xF3C477, 0xA1471F, 0xFFA866)
    static let paper = palette(0x302438, 0xF8F0E7, 0x132133, 0xF2F5F2)
    static let muted = palette(0x6C5A74, 0xCCBED8, 0x4F6673, 0xADC2C9)
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
                    for index in 0..<(AppBrand.current.isStuffyLand ? 24 : 90) {
                        let x = CGFloat((index * 127 + 37) % 997) / 997 * size.width
                        let y = CGFloat((index * 293 + 79) % 991) / 991 * size.height
                        let diameter = index.isMultiple(of: 9) ? 3.2 : 1.3
                        let opacity = index.isMultiple(of: 5) ? 0.35 : 0.16
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                            with: .color((AppBrand.current.isStuffyLand ? StarportTheme.orange : (scheme == .dark ? Color.white : Color.black)).opacity(AppBrand.current.isStuffyLand ? opacity * 0.35 : opacity))
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
        Image("stuffy-logo")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 24))
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
