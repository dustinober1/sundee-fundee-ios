import Foundation
import StoreKit

// MARK: - Subscription Tier

enum SubscriptionTier: String, Sendable, Comparable {
    case free
    case plus
    case pro

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Plus"
        case .pro: return "Pro"
        }
    }

    var dailyAILimit: Int {
        switch self {
        case .free: 0
        case .plus: 1
        case .pro: 3
        }
    }

    var productID: String? {
        switch self {
        case .free: nil
        case .plus: "com.sundeefundee.app.plus.monthly"
        case .pro: "com.sundeefundee.app.pro.monthly"
        }
    }

    static let allProductIDs: Set<String> = [
        "com.sundeefundee.app.plus.monthly",
        "com.sundeefundee.app.pro.monthly"
    ]

    static func from(productID: String) -> SubscriptionTier {
        switch productID {
        case "com.sundeefundee.app.plus.monthly": .plus
        case "com.sundeefundee.app.pro.monthly": .pro
        default: .free
        }
    }

    static func highest(_ tiers: [SubscriptionTier]) -> SubscriptionTier {
        tiers.max() ?? .free
    }

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        let order: [SubscriptionTier] = [.free, .plus, .pro]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }
}

// MARK: - SubscriptionService

@Observable @MainActor
final class SubscriptionService {
    private static let tierKey = "com.sundeefundee.subscription.tier"

    private(set) var currentTier: SubscriptionTier = .free
    var isPremium: Bool { currentTier != .free }
    private var transactionTask: Task<Void, Never>?

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.tierKey) ?? "free"
        self.currentTier = SubscriptionTier(rawValue: raw) ?? .free
        startObservingTransactions()
    }

    func loadStatus() async {
        var activeTiers: [SubscriptionTier] = []
        for await verificationResult in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verificationResult else { continue }
            if transaction.revocationDate == nil {
                activeTiers.append(SubscriptionTier.from(productID: transaction.productID))
            }
        }
        setTier(SubscriptionTier.highest(activeTiers))
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            setTier(SubscriptionTier.from(productID: transaction.productID))
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await loadStatus()
    }

    #if DEBUG
    func setTierForTesting(_ tier: SubscriptionTier) {
        setTier(tier)
    }
    #endif

    // MARK: - Private

    private func startObservingTransactions() {
        transactionTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    let tier = SubscriptionTier.from(productID: transaction.productID)
                    if transaction.revocationDate == nil {
                        self.setTier(tier)
                    } else {
                        await self.loadStatus()
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private func setTier(_ tier: SubscriptionTier) {
        self.currentTier = tier
        UserDefaults.standard.set(tier.rawValue, forKey: Self.tierKey)
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
