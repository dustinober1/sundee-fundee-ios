import Foundation
@preconcurrency import RevenueCat

// MARK: - RevenueCatClient

/// Actor-based client for RevenueCat subscription management.
///
/// Wraps the RevenueCat SDK to conform to `SubscriptionClientProtocol`.
/// Handles purchasing, restoration, user identification, and subscription
/// status checking.
///
/// ## Setup
/// Configure once at app launch, then identify after sign-in:
/// ```swift
/// RevenueCatClient.configure(apiKey: "appl_your_api_key")
/// let client = RevenueCatClient()
/// await client.identify(userId: "user_123")
/// ```
///
/// ## Entitlements
/// Maps RevenueCat entitlements to `SubscriptionTier`:
/// - `sundee_plus` -> `.plus`
/// - `sundee_premium` -> `.premium`
/// - No active entitlement -> `.free`
public actor RevenueCatClient: SubscriptionClientProtocol {
    // MARK: - Properties

    /// The current user ID, if identified.
    private var userId: String?

    /// Cached subscription info.
    private var cachedSubscription: SubscriptionInfo?

    // MARK: - Static Configuration

    /// Whether RevenueCat SDK has been configured.
    private static let configuredLock = NSLock()
    private static var _configured = false
    private static var isConfigured: Bool {
        get { configuredLock.withLock { _configured } }
        set { configuredLock.withLock { _configured = newValue } }
    }

    /// Configures the RevenueCat SDK. Call once at app launch.
    ///
    /// - Parameter apiKey: Your RevenueCat Apple API key (starts with `appl_`).
    @MainActor
    public static func configure(apiKey: String) {
        guard !isConfigured else { return }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true
    }

    // MARK: - Initialization

    /// Creates a new RevenueCat client.
    ///
    /// Call `RevenueCatClient.configure(apiKey:)` before creating instances.
    public init() {
        self.cachedSubscription = SubscriptionInfo(tier: .free, status: .active)
    }

    // MARK: - User Management

    /// Identifies the user with RevenueCat.
    ///
    /// Call this after sign-in to associate subscription data with the user.
    /// This syncs the user's purchase history across devices.
    ///
    /// - Parameter userId: The unique user identifier (Apple Sign In user ID).
    public func identify(userId: String) async {
        self.userId = userId
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            self.cachedSubscription = Self.mapCustomerInfo(customerInfo)
        } catch {
            print("[RevenueCat] Failed to identify user: \(error)")
        }
    }

    /// Logs out the current user.
    ///
    /// Call this after sign-out to clear user-specific subscription data.
    /// RevenueCat will create a new anonymous user.
    public func logout() async {
        self.userId = nil
        do {
            let customerInfo = try await Purchases.shared.logOut()
            self.cachedSubscription = Self.mapCustomerInfo(customerInfo)
        } catch {
            print("[RevenueCat] Failed to logout: \(error)")
            self.cachedSubscription = SubscriptionInfo(tier: .free, status: .active)
        }
    }

    // MARK: - SubscriptionClientProtocol

    public var currentSubscription: SubscriptionInfo? {
        cachedSubscription
    }

    public func getSubscriptionInfo() async throws -> SubscriptionInfo {
        let customerInfo = try await Purchases.shared.customerInfo()
        let subscription = Self.mapCustomerInfo(customerInfo)
        self.cachedSubscription = subscription
        return subscription
    }

    public func purchase(tier: SubscriptionTier) async throws -> SubscriptionInfo {
        guard tier != .free else {
            throw SubscriptionError.productUnavailable(productId: "free")
        }

        let package = try await getPackage(for: tier)

        do {
            let result = try await Purchases.shared.purchase(package: package)

            if result.userCancelled {
                throw SubscriptionError.purchaseCancelled
            }

            let subscription = Self.mapCustomerInfo(result.customerInfo)
            self.cachedSubscription = subscription
            return subscription
        } catch let error as SubscriptionError {
            throw error
        } catch {
            throw SubscriptionError.purchaseFailed(underlying: error)
        }
    }

    public func restorePurchases() async throws -> SubscriptionInfo {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let subscription = Self.mapCustomerInfo(customerInfo)

            guard subscription.tier != .free else {
                throw SubscriptionError.noPurchasesToRestore
            }

            self.cachedSubscription = subscription
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
            _ = try await getPackage(for: tier)
            return true
        } catch {
            return false
        }
    }

    public func getPrice(for tier: SubscriptionTier) async -> String? {
        guard tier != .free else { return nil }
        do {
            let package = try await getPackage(for: tier)
            return package.localizedPriceString
        } catch {
            return nil
        }
    }

    // MARK: - Private Helpers

    /// Fetches the RevenueCat package for a subscription tier.
    private func getPackage(for tier: SubscriptionTier) async throws -> Package {
        let offerings = try await Purchases.shared.offerings()

        guard let offering = offerings.current else {
            throw SubscriptionError.productUnavailable(productId: tier.rawValue)
        }

        // Look for a package whose identifier matches the tier
        // Convention: package identifiers are "plus" and "premium"
        if let package = offering.package(identifier: tier.rawValue) {
            return package
        }

        // Fallback: match by offering package type
        // plus -> monthly, premium -> annual (or adjust to your offering setup)
        if let package = offering.availablePackages.first(where: {
            $0.identifier.localizedCaseInsensitiveContains(tier.rawValue)
        }) {
            return package
        }

        throw SubscriptionError.productUnavailable(productId: tier.rawValue)
    }

    // MARK: - Mapping

    /// Maps RevenueCat `CustomerInfo` to our `SubscriptionInfo`.
    ///
    /// Checks entitlements in order of highest tier first:
    /// 1. `sundee_premium` -> `.premium`
    /// 2. `sundee_plus` -> `.plus`
    /// 3. No active entitlement -> `.free`
    private static func mapCustomerInfo(_ customerInfo: CustomerInfo) -> SubscriptionInfo {
        // Check premium first (highest tier)
        if let premiumEntitlement = customerInfo.entitlements["sundee_premium"],
           premiumEntitlement.isActive {
            return SubscriptionInfo(
                tier: .premium,
                status: mapEntitlementStatus(premiumEntitlement),
                startDate: premiumEntitlement.originalPurchaseDate,
                expiryDate: premiumEntitlement.expirationDate,
                willRenew: premiumEntitlement.willRenew,
                entitlementId: "sundee_premium",
                originalTransactionId: premiumEntitlement.originalPurchaseDate?.description
            )
        }

        // Check plus
        if let plusEntitlement = customerInfo.entitlements["sundee_plus"],
           plusEntitlement.isActive {
            return SubscriptionInfo(
                tier: .plus,
                status: mapEntitlementStatus(plusEntitlement),
                startDate: plusEntitlement.originalPurchaseDate,
                expiryDate: plusEntitlement.expirationDate,
                willRenew: plusEntitlement.willRenew,
                entitlementId: "sundee_plus",
                originalTransactionId: plusEntitlement.originalPurchaseDate?.description
            )
        }

        // Check for any expired entitlements (for showing "expired" state)
        for (identifier, entitlement) in customerInfo.entitlements.all {
            if !entitlement.isActive, let expiryDate = entitlement.expirationDate {
                let tier: SubscriptionTier = identifier.contains("premium") ? .premium : .plus
                return SubscriptionInfo(
                    tier: tier,
                    status: .expired,
                    startDate: entitlement.originalPurchaseDate,
                    expiryDate: expiryDate,
                    willRenew: false,
                    entitlementId: identifier
                )
            }
        }

        // No subscription
        return SubscriptionInfo(tier: .free, status: .active)
    }

    /// Maps entitlement period type to our subscription status.
    private static func mapEntitlementStatus(_ entitlement: EntitlementInfo) -> SubscriptionStatus {
        if entitlement.unsubscribeDetectedAt != nil && !entitlement.willRenew {
            return .cancelled
        }
        if entitlement.billingIssueDetectedAt != nil {
            return .pastDue
        }
        return .active
    }
}
