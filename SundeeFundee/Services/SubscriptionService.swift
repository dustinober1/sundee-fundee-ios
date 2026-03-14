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
        print("[SubscriptionService] Starting purchase for product: \(product.id)")
        let result = try await product.purchase()
        print("[SubscriptionService] Purchase result: \(result)")
        switch result {
        case .success(let verification):
            print("[SubscriptionService] Purchase succeeded, verifying transaction...")
            let transaction = try checkVerified(verification)
            print("[SubscriptionService] Transaction verified: \(transaction.id)")
            await transaction.finish()
            setTier(SubscriptionTier.from(productID: transaction.productID))
            print("[SubscriptionService] Tier set to: \(SubscriptionTier.from(productID: transaction.productID))")
        case .userCancelled:
            print("[SubscriptionService] Purchase cancelled by user")
            throw PurchaseError.userCancelled
        case .pending:
            print("[SubscriptionService] Purchase pending")
            throw PurchaseError.pending
        @unknown default:
            print("[SubscriptionService] Unknown purchase result")
            throw PurchaseError.unknown
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

// MARK: - PurchaseError

enum PurchaseError: Error, LocalizedError {
    case userCancelled
    case pending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userCancelled: return "Purchase was cancelled"
        case .pending: return "Purchase is pending"
        case .unknown: return "An unknown error occurred"
        }
    }
}
