import SwiftUI
import GoogleMobileAds

/// A small fixed 320x50 banner, separate from story choices in a bottom inset.
/// The ad view disappears entirely after a verified Remove Ads purchase.
struct AdBannerView: View {
    let unitID: String

    var body: some View {
        VStack(spacing: 5) {
            Text("ADVERTISEMENT")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(.secondary)
            BannerContainer(unitID: unitID)
                .frame(width: 320, height: 50)
                .accessibilityLabel("Advertisement")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

private struct BannerContainer: UIViewRepresentable {
    let unitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = unitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
