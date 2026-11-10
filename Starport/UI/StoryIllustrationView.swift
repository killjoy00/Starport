import SwiftUI
import UIKit

/// A restrained, accessible illustration placed between the scene title and prose.
/// Optional artwork never prevents a story from loading or a choice from working.
struct StoryIllustrationView: View {
    let illustration: StoryIllustration
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let image = UIImage(named: illustration.asset) {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
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
}

/// The adventure art lives in an asset catalog so it displays without a network.
struct AdventureCoverView: View {
    let assetName: String

    var body: some View {
        if let image = UIImage(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(2.0 / 3.0, contentMode: .fill)
                .frame(width: 125, height: 188)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(.white.opacity(0.16), lineWidth: 1)
                }
                .accessibilityLabel("Illustrated cover for The Door That Opens Tomorrow")
                .accessibilityAddTraits(.isImage)
        }
    }
}
