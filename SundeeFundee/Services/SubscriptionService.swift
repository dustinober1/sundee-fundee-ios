import Foundation
import StoreKit

// MARK: - Subscription Tier

enum SubscriptionTier: String, Sendable {
    case free
    case premium = "com.sundeefundee.premium.monthly"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
}

// MARK: - SubscriptionService

/// Manages StoreKit 2 in-app subscriptions and entitlements.
/// Observes transaction updates in real-time and maintains local cache in UserDefaults.
@Observable @MainActor
final class SubscriptionService {
    private static let isPremiumKey = "com.sundeefundee.subscription.isPremium"

    var isPremium: Bool = false
    private var transactionTask: Task<Void, Never>?

    init() {
        self.isPremium = UserDefaults.standard.bool(forKey: Self.isPremiumKey)
        startObservingTransactions()
    }

    /// Load subscription status from StoreKit, checking current entitlements.
    func loadStatus() async {
        var foundPremium = false
        for await verificationResult in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verificationResult else { continue }
            if transaction.productID == SubscriptionTier.premium.rawValue,
               transaction.revocationDate == nil {
                foundPremium = true
                break
            }
        }
        setIsPremium(foundPremium)
    }

    /// Purchase a product by its ID.
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            setIsPremium(true)

        case .userCancelled:
            break

        case .pending:
            break

        @unknown default:
            break
        }
    }

    /// Restore previous purchases from the App Store.
    func restorePurchases() async throws {
        try await AppStore.sync()
        await loadStatus()
    }

    // MARK: - Private

    private func startObservingTransactions() {
        transactionTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    if transaction.productID == SubscriptionTier.premium.rawValue {
                        self.setIsPremium(transaction.revocationDate == nil)
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private func setIsPremium(_ value: Bool) {
        self.isPremium = value
        UserDefaults.standard.set(value, forKey: Self.isPremiumKey)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.unverifiedTransaction
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - SubscriptionError

enum SubscriptionError: Error {
    case unverifiedTransaction
}
