import Foundation
import GoogleMobileAds
import UserMessagingPlatform

/// Starport is 13+. For its teen audience, ads receive teen age treatment,
/// general-audience creative ratings, and no personalized advertising.
/// No ads are requested until the UMP consent status permits them.
/// DEBUG uses only Google's sample app + banner IDs. Production remains OFF
/// until both real IDs and the release approval flag are configured.
@MainActor
final class AdsController: ObservableObject {
    @Published private(set) var canShowBanner = false
    @Published private(set) var privacyOptionsRequired = false
    @Published private(set) var message: String?

    private var didPrepare = false

    var bannerUnitID: String? {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716"
        #else
        guard Self.isReleaseConfigured else { return nil }
        return Bundle.main.object(forInfoDictionaryKey: "STARPORT_BANNER_UNIT_ID") as? String
        #endif
    }

    private static var isReleaseConfigured: Bool {
        #if DEBUG
        return true
        #else
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
              let unit = Bundle.main.object(forInfoDictionaryKey: "STARPORT_BANNER_UNIT_ID") as? String,
              appID.hasPrefix("ca-app-pub-"),
              unit.hasPrefix("ca-app-pub-"),
              !appID.contains("3940256099942544"),
              !unit.contains("3940256099942544"),
              Bundle.main.object(forInfoDictionaryKey: "STARPORT_ADS_LIVE_APPROVED") as? String == "YES"
        else { return false }
        return true
        #endif
    }

    func prepareIfNeeded() async {
        guard !didPrepare, Self.isReleaseConfigured else { return }
        didPrepare = true

        let configuration = MobileAds.shared.requestConfiguration
        configuration.ageRestrictedTreatment = .teen
        configuration.maxAdContentRating = .general
        configuration.publisherPrivacyPersonalizationState = .disabled

        let consent = ConsentInformation.shared
        let parameters = RequestParameters()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            consent.requestConsentInfoUpdate(with: parameters) { _ in
                continuation.resume()
            }
        }
        do {
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            // Never bypass a required consent form after a failure.
            message = "Ads are unavailable while privacy settings are checked."
        }

        privacyOptionsRequired = consent.privacyOptionsRequirementStatus == .required
        guard consent.canRequestAds else { return }
        _ = await MobileAds.shared.start()
        canShowBanner = true
    }

    func showPrivacyOptions() async {
        guard privacyOptionsRequired else { return }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            message = "Privacy options couldn't open. Please try again."
        }
    }

    func dismissMessage() { message = nil }
}
