import SwiftUI
import UIKit

/// Illustrations are optional. Stuffy Land uses drawn placeholders until
/// its distinct cover art and story-scene illustrations are finalized.
struct StoryIllustrationView: View {
    let illustration: StoryIllustration

    var body: some View {
        Group {
            if let image = UIImage(named: illustration.asset) {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            } else if AppBrand.current.isStuffyLand {
                ZStack {
                    LinearGradient(
                        colors: [StarportTheme.teal.opacity(0.18),
                                 StarportTheme.orange.opacity(0.18),
                                 StarportTheme.panel],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    HStack(spacing: 26) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 29, weight: .light))
                            .offset(y: -36)
                        StorybookPlushArtwork()
                            .frame(width: 132, height: 132)
                        Image(systemName: "leaf")
                            .font(.system(size: 35, weight: .light))
                            .offset(y: 32)
                    }
                    .foregroundStyle(StarportTheme.teal)
                }
            }
        }
        .frame(height: 188)
        .background(StarportTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(StarportTheme.line.opacity(0.75), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(illustration.alt)
        .accessibilityAddTraits(.isImage)
        .padding(.vertical, 5)
    }
}

struct AdventureCoverView: View {
    let assetName: String

    var body: some View {
        Group {
            if let image = UIImage(named: assetName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(2.0 / 3.0, contentMode: .fill)
            } else if AppBrand.current.isStuffyLand {
                ZStack {
                    LinearGradient(
                        colors: [StarportTheme.teal.opacity(0.44),
                                 StarportTheme.orange.opacity(0.36),
                                 StarportTheme.panel],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VStack(spacing: 10) {
                        Image(systemName: "sparkle")
                            .foregroundStyle(StarportTheme.paper)
                        StorybookPlushArtwork()
                            .frame(width: 102, height: 108)
                        Text("STUFFY LAND")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(1.4)
                            .foregroundStyle(StarportTheme.paper)
                    }
                }
            }
        }
        .frame(width: 125, height: 188)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
        .accessibilityLabel(AppBrand.current.isStuffyLand
            ? "Storybook cover illustration"
            : "Illustrated adventure cover")
        .accessibilityAddTraits(.isImage)
    }
}
