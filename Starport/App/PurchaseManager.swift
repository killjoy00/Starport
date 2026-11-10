import Foundation
import StoreKit

/// One-time, non-consumable "Remove Ads" entitlement through StoreKit 2.
@MainActor
final class PurchaseManager: ObservableObject {
    static var productID: String { AppBrand.current.removeAdsProductID }

    @Published private(set) var product: Product?
    @Published private(set) var isAdFree = false
    @Published private(set) var entitlementsLoaded = false
    @Published private(set) var busy = false
    @Published var message: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await verification in Transaction.updates {
                guard let self else { break }
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                }
                await self.refreshEntitlements()
            }
        }
    }

    func prepare() async {
        await refreshEntitlements()
        await loadProduct()
    }

    func refreshEntitlements() async {
        var valid = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                valid = true
            }
        }
        isAdFree = valid
        entitlementsLoaded = true
    }

    private func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            message = "The App Store is unavailable. You can still read every adventure."
        }
    }

    func buy() async {
        guard let product, !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    message = "The purchase could not be verified."
                    return
                }
                await transaction.finish()
                await refreshEntitlements()
                if isAdFree { message = "Ads have been removed on this Apple Account." }
            case .pending:
                message = "The purchase is pending approval. Ads will disappear once it is approved."
            case .userCancelled:
                break
            @unknown default:
                message = "The App Store did not finish that purchase."
            }
        } catch {
            message = "Couldn't complete the purchase. No charge was confirmed."
        }
    }

    func restore() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = isAdFree ? "Your ad-free purchase was restored." : "No Remove Ads purchase was found for this Apple Account."
        } catch {
            message = "Couldn't reach the App Store. Please try again later."
        }
    }

    func dismissMessage() { message = nil }
}
