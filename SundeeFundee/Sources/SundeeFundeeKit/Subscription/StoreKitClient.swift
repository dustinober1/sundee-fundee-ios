import Foundation
import StoreKit
#if os(iOS)
import UIKit
#endif

// MARK: - StoreKitClient

/// Actor-based client for native Apple StoreKit 2 subscription management.
///
/// Wraps StoreKit 2 to conform to `SubscriptionClientProtocol`.
/// Handles purchasing, restoration, user identification, and subscription
/// status checking using Apple's native APIs.
///
/// ## Product IDs
/// Maps StoreKit product IDs to `SubscriptionTier`:
/// - `sundee_plus_monthly` -> `.plus`
/// - `sundee_premium_monthly` -> `.premium`
/// - No active subscription -> `.free`
public actor StoreKitClient: SubscriptionClientProtocol {
    // MARK: - Types

    // Use module-qualified names to avoid collision with StoreKit.Product.SubscriptionInfo
    private typealias SubInfo = SundeeFundeeKit.SubscriptionInfo
    private typealias SubStatus = SundeeFundeeKit.SubscriptionStatus

    // MARK: - Properties

    /// The current user ID, if identified.
    private var userId: String?

    /// Cached subscription info.
    private var _cachedSubscription: SubInfo?

    /// StoreKit product instances, loaded on first use.
    private var products: [Product] = []

    /// Task listening for transaction updates.
    private var transactionListener: Task<Void, Never>?

    // MARK: - Product IDs

    /// All subscription product IDs to request from StoreKit.
    private static let productIDs: Set<String> = [
        "sundee_plus_monthly",
        "sundee_plus_annual",
        "sundee_premium_monthly",
        "sundee_premium_annual"
    ]

    // MARK: - Pro Test Overrides

    /// Emails that are hardcoded as Pro (premium) members for testing.
    private static let proTestEmails: Set<String> = [
        "elizabethober@icloud.com",
        "dustinober@me.com"
    ]

    /// The identified user's email, if provided.
    private var userEmail: String?

    // MARK: - Initialization

    /// Creates a new StoreKit client.
    public init() {
        self._cachedSubscription = SubInfo(tier: .free, status: .active)
    }

    /// Starts listening for StoreKit transaction updates.
    /// Call once at app launch from a non-isolated context.
    public func startTransactionListener() {
        transactionListener?.cancel()
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - User Management

    /// Identifies the user for subscription tracking.
    ///
    /// - Parameters:
    ///   - userId: The unique user identifier (Apple Sign In user ID).
    ///   - email: The user's email, used for test overrides.
    public func identify(userId: String, email: String? = nil) async {
        self.userId = userId
        self.userEmail = email?.lowercased()

        // Check for pro test override
        if let email = self.userEmail, Self.proTestEmails.contains(email) {
            self._cachedSubscription = SubInfo(
                tier: .premium,
                status: .active,
                startDate: Date(),
                expiryDate: nil,
                willRenew: true,
                entitlementId: "sundee_premium_test_override"
            )
            print("[StoreKit] Pro test override active for \(email)")
            return
        }

        // Refresh from StoreKit
        await refreshSubscriptionStatus()
    }

    /// Logs out the current user.
    public func logout() async {
        self.userId = nil
        self.userEmail = nil
        self._cachedSubscription = SubInfo(tier: .free, status: .active)
    }

    // MARK: - SubscriptionClientProtocol

    public var currentSubscription: SundeeFundeeKit.SubscriptionInfo? {
        _cachedSubscription
    }

    public func getSubscriptionInfo() async throws -> SundeeFundeeKit.SubscriptionInfo {
        // Pro test override takes precedence
        if let email = userEmail, Self.proTestEmails.contains(email) {
            let override = SubInfo(
                tier: .premium,
                status: .active,
                startDate: Date(),
                expiryDate: nil,
                willRenew: true,
                entitlementId: "sundee_premium_test_override"
            )
            self._cachedSubscription = override
            return override
        }

        await refreshSubscriptionStatus()
        return _cachedSubscription ?? SubInfo(tier: .free, status: .active)
    }

    public func purchase(tier: SubscriptionTier) async throws -> SundeeFundeeKit.SubscriptionInfo {
        guard tier != .free else {
            throw SubscriptionError.productUnavailable(productId: "free")
        }

        let product = try await getProduct(for: tier)

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    throw SubscriptionError.purchaseFailed(underlying: nil)
                }
                await transaction.finish()
                await refreshSubscriptionStatus()
                return _cachedSubscription ?? SubInfo(tier: tier, status: .active)

            case .userCancelled:
                throw SubscriptionError.purchaseCancelled

            case .pending:
                throw SubscriptionError.purchaseFailed(underlying: nil)

            @unknown default:
                throw SubscriptionError.purchaseFailed(underlying: nil)
            }
        } catch let error as SubscriptionError {
            throw error
        } catch {
            throw SubscriptionError.purchaseFailed(underlying: error)
        }
    }

    public func restorePurchases() async throws -> SundeeFundeeKit.SubscriptionInfo {
        do {
            try await AppStore.sync()
            await refreshSubscriptionStatus()

            guard let subscription = _cachedSubscription, subscription.tier != .free else {
                throw SubscriptionError.noPurchasesToRestore
            }

            return subscription
        } catch let error as SubscriptionError {
            throw error
        } catch {
            throw SubscriptionError.restoreFailed(underlying: error)
        }
    }

    public func presentManageSubscriptions() async throws {
        #if os(iOS)
        await MainActor.run {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                UIApplication.shared.open(url)
            }
        }
        #endif
    }

    public func isTierAvailable(_ tier: SubscriptionTier) async -> Bool {
        guard tier != .free else { return true }
        do {
            _ = try await getProduct(for: tier)
            return true
        } catch {
            return false
        }
    }

    public func getPrice(for tier: SubscriptionTier) async -> String? {
        guard tier != .free else { return nil }
        do {
            let product = try await getProduct(for: tier)
            return product.displayPrice
        } catch {
            return nil
        }
    }

    // MARK: - Private Helpers

    /// Loads StoreKit products if not already loaded.
    private func loadProductsIfNeeded() async throws {
        guard products.isEmpty else { return }
        products = try await Product.products(for: Self.productIDs)
    }

    /// Gets the StoreKit product for a subscription tier.
    private func getProduct(for tier: SubscriptionTier) async throws -> Product {
        try await loadProductsIfNeeded()

        // Match by product ID containing the tier name
        if let product = products.first(where: {
            $0.id.contains(tier.rawValue)
        }) {
            return product
        }

        throw SubscriptionError.productUnavailable(productId: tier.rawValue)
    }

    /// Refreshes subscription status from StoreKit transaction history.
    private func refreshSubscriptionStatus() async {
        var highestTier: SubscriptionTier = .free
        var activeSubscription: SubInfo?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            let tier = Self.mapProductToTier(transaction.productID)
            if tier.ordinal > highestTier.ordinal {
                highestTier = tier

                let status: SubStatus
                if let revocationDate = transaction.revocationDate, revocationDate <= Date() {
                    status = .expired
                } else if transaction.isUpgraded {
                    continue // Skip upgraded transactions
                } else {
                    status = .active
                }

                activeSubscription = SubInfo(
                    tier: tier,
                    status: status,
                    startDate: transaction.purchaseDate,
                    expiryDate: transaction.expirationDate,
                    willRenew: transaction.revocationDate == nil,
                    entitlementId: transaction.productID,
                    originalTransactionId: String(transaction.originalID)
                )
            }
        }

        _cachedSubscription = activeSubscription ?? SubInfo(tier: .free, status: .active)
    }

    /// Maps a StoreKit product ID to a subscription tier.
    private static func mapProductToTier(_ productID: String) -> SubscriptionTier {
        if productID.contains("premium") {
            return .premium
        } else if productID.contains("plus") {
            return .plus
        }
        return .free
    }
}

// MARK: - SubscriptionTier Ordering

private extension SubscriptionTier {
    /// Numeric ordering for tier comparison.
    var ordinal: Int {
        switch self {
        case .free: return 0
        case .plus: return 1
        case .premium: return 2
        }
    }
}
