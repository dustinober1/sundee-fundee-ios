import Foundation

// MARK: - RevenueCatClient

/// Actor-based client for RevenueCat subscription management.
///
/// `RevenueCatClient` provides a thread-safe interface to RevenueCat's
/// subscription management functionality. It handles purchasing, restoration,
/// and subscription status checking.
///
/// ## Setup
/// Initialize with your RevenueCat API key:
/// ```swift
/// let client = RevenueCatClient(apiKey: "your_api_key")
/// await client.identify(userId: "user_123")
/// ```
///
/// ## Thread Safety
/// As an actor, `RevenueCatClient` ensures all subscription operations are
/// serialized and thread-safe. Call methods from any queue or task without
/// worrying about data races.
///
/// ## Note
/// This is a stub implementation. Full implementation requires the
/// RevenueCat SDK dependency. Add to Package.swift:
/// ```
/// .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "4.0.0")
/// ```
public actor RevenueCatClient: SubscriptionClientProtocol {
    // MARK: - Properties

    /// The RevenueCat API key.
    private let apiKey: String

    /// The current user ID, if identified.
    private var userId: String?

    /// Cached subscription info.
    private var cachedSubscription: SubscriptionInfo?

    // MARK: - Initialization

    /// Creates a new RevenueCat client.
    ///
    /// - Parameter apiKey: Your RevenueCat API key.
    public init(apiKey: String) {
        self.apiKey = apiKey
        self.cachedSubscription = SubscriptionInfo(
            tier: .free,
            status: .active
        )
    }

    // MARK: - Configuration

    /// Identifies the user with RevenueCat.
    ///
    /// Call this after sign-in to associate subscription data with the user.
    ///
    /// - Parameter userId: The unique user identifier.
    public func identify(userId: String) async {
        self.userId = userId
        // In full implementation, this would call:
        // Purchases.shared.attribution.collectDeviceIdentifiers()
        // Purchases.shared.logIn(userId)
    }

    /// Logs out the current user.
    ///
    /// Call this after sign-out to clear user-specific subscription data.
    public func logout() async {
        self.userId = nil
        self.cachedSubscription = SubscriptionInfo(
            tier: .free,
            status: .active
        )
        // In full implementation, this would call:
        // Purchases.shared.logOut()
    }

    // MARK: - SubscriptionClientProtocol

    public var currentSubscription: SubscriptionInfo? {
        cachedSubscription
    }

    public func getSubscriptionInfo() async throws -> SubscriptionInfo {
        // In full implementation, this would call:
        // let customerInfo = try await Purchases.shared.customerInfo()
        // return mapCustomerInfoToSubscriptionInfo(customerInfo)

        // Stub: Return cached subscription or free tier
        return cachedSubscription ?? SubscriptionInfo(
            tier: .free,
            status: .active
        )
    }

    public func purchase(tier: SubscriptionTier) async throws -> SubscriptionInfo {
        guard tier != .free else {
            throw SubscriptionError.productUnavailable(productId: "free")
        }

        // In full implementation, this would call:
        // let package = try await getPackage(for: tier)
        // let result = try await Purchases.shared.purchase(package: package)
        // return mapCustomerInfoToSubscriptionInfo(result.customerInfo)

        // Stub: Simulate successful purchase
        let subscription = SubscriptionInfo(
            tier: tier,
            status: .active,
            startDate: Date(),
            expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            willRenew: true,
            entitlementId: "sundee_\(tier.rawValue)"
        )
        self.cachedSubscription = subscription
        return subscription
    }

    public func restorePurchases() async throws -> SubscriptionInfo {
        // In full implementation, this would call:
        // let customerInfo = try await Purchases.shared.restorePurchases()
        // return mapCustomerInfoToSubscriptionInfo(customerInfo)

        // Stub: Check if we have a cached subscription
        if let cached = cachedSubscription, cached.tier != .free {
            return cached
        }

        throw SubscriptionError.noPurchasesToRestore
    }

    public func presentManageSubscriptions() async throws {
        // In full implementation, this would open App Store:
        // if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
        //     await UIApplication.shared.open(url)
        // }

        // Stub: No-op
    }

    public func isTierAvailable(_ tier: SubscriptionTier) async -> Bool {
        // In full implementation, this would check offerings:
        // let offerings = try? await Purchases.shared.offerings()
        // return offerings?.all.first { $0.identifier == tier.rawValue } != nil

        // Stub: All paid tiers are "available"
        return tier != .free
    }

    public func getPrice(for tier: SubscriptionTier) async -> String? {
        // In full implementation, this would get localized price:
        // let package = try? await getPackage(for: tier)
        // return package?.storeProduct.localizedPriceString

        // Stub: Return placeholder prices
        switch tier {
        case .free:
            return nil
        case .plus:
            return "$9.99/month"
        case .premium:
            return "$19.99/month"
        }
    }

    // MARK: - Private Helpers

    /// Gets the RevenueCat package for a tier.
    ///
    /// - Parameter tier: The subscription tier.
    /// - Returns: The RevenueCat package for the tier.
    /// - Throws: `SubscriptionError.productUnavailable` if not found.
    private func getPackage(for tier: SubscriptionTier) async throws -> Any {
        // Stub - in full implementation this would fetch from RevenueCat offerings
        // let offerings = try await Purchases.shared.offerings()
        // guard let offering = offerings.current,
        //       let package = offering.availablePackages.first(where: { $0.identifier.contains(tier.rawValue) }) else {
        //     throw SubscriptionError.productUnavailable(productId: tier.rawValue)
        // }
        // return package
        throw SubscriptionError.productUnavailable(productId: tier.rawValue)
    }
}
