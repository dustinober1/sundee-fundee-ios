import Foundation

// MARK: - MockSubscriptionClient

/// Mock subscription client for testing.
///
/// `MockSubscriptionClient` provides an in-memory implementation of
/// `SubscriptionClientProtocol` for unit testing without actual purchases.
///
/// ## Example Usage
/// ```swift
/// let mock = MockSubscriptionClient()
///
/// // Seed with a subscription
/// await mock.seedSubscription(.init(tier: .premium, status: .active))
///
/// // Test subscription check
/// let info = try await mock.getSubscriptionInfo()
/// XCTAssertEqual(info.tier, .premium)
///
/// // Simulate purchase failure
/// await mock.setSimulatePurchaseFailure(true)
/// await assertThrows(try await mock.purchase(tier: .plus))
/// ```
public actor MockSubscriptionClient: SubscriptionClientProtocol {
    // MARK: - Properties

    /// The current subscription info.
    private var subscription: SubscriptionInfo?

    /// Available tiers and their prices.
    private var availableTiers: [SubscriptionTier: String] = [
        .plus: "$9.99/month",
        .premium: "$19.99/month"
    ]

    /// Whether to simulate purchase failures.
    public var simulatePurchaseFailure = false

    /// Whether to simulate restore failures.
    public var simulateRestoreFailure = false

    /// The error to throw when simulating failures.
    public var simulatedError: SubscriptionError = .purchaseFailed(underlying: nil)

    // MARK: - Initialization

    /// Creates a new mock subscription client.
    ///
    /// - Parameter subscription: Optional initial subscription state.
    public init(subscription: SubscriptionInfo? = nil) {
        self.subscription = subscription
    }

    // MARK: - Seeding Methods

    /// Seeds the client with a subscription.
    ///
    /// - Parameter subscription: The subscription to use.
    public func seedSubscription(_ subscription: SubscriptionInfo?) {
        self.subscription = subscription
    }

    /// Sets the available tiers and their prices.
    ///
    /// - Parameter tiers: Dictionary of tiers to prices.
    public func setAvailableTiers(_ tiers: [SubscriptionTier: String]) {
        self.availableTiers = tiers
    }

    /// Sets whether to simulate purchase failures.
    public func setSimulatePurchaseFailure(_ value: Bool) {
        self.simulatePurchaseFailure = value
    }

    /// Sets whether to simulate restore failures.
    public func setSimulateRestoreFailure(_ value: Bool) {
        self.simulateRestoreFailure = value
    }

    /// Sets the error to throw when simulating failures.
    public func setSimulatedError(_ error: SubscriptionError) {
        self.simulatedError = error
    }

    // MARK: - SubscriptionClientProtocol

    public var currentSubscription: SubscriptionInfo? {
        subscription ?? SubscriptionInfo(tier: .free, status: .active)
    }

    public func getSubscriptionInfo() async throws -> SubscriptionInfo {
        subscription ?? SubscriptionInfo(tier: .free, status: .active)
    }

    public func purchase(tier: SubscriptionTier) async throws -> SubscriptionInfo {
        if simulatePurchaseFailure {
            throw simulatedError
        }

        guard tier != .free else {
            throw SubscriptionError.productUnavailable(productId: "free")
        }

        let newSubscription = SubscriptionInfo(
            tier: tier,
            status: .active,
            startDate: Date(),
            expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            willRenew: true,
            entitlementId: "sundee_\(tier.rawValue)"
        )
        subscription = newSubscription
        return newSubscription
    }

    public func restorePurchases() async throws -> SubscriptionInfo {
        if simulateRestoreFailure {
            throw simulatedError
        }

        guard let existing = subscription, existing.tier != .free else {
            throw SubscriptionError.noPurchasesToRestore
        }

        return existing
    }

    public func presentManageSubscriptions() async throws {
        // No-op in mock
    }

    public func isTierAvailable(_ tier: SubscriptionTier) async -> Bool {
        tier == .free || availableTiers[tier] != nil
    }

    public func getPrice(for tier: SubscriptionTier) async -> String? {
        availableTiers[tier]
    }
}

// MARK: - Convenience Factory Methods

extension MockSubscriptionClient {
    /// Creates a mock client with a Plus subscription.
    public static func plus() -> MockSubscriptionClient {
        MockSubscriptionClient(subscription: SubscriptionInfo(
            tier: .plus,
            status: .active,
            startDate: Date(),
            expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            willRenew: true,
            entitlementId: "sundee_plus"
        ))
    }

    /// Creates a mock client with a Premium subscription.
    public static func premium() -> MockSubscriptionClient {
        MockSubscriptionClient(subscription: SubscriptionInfo(
            tier: .premium,
            status: .active,
            startDate: Date(),
            expiryDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            willRenew: true,
            entitlementId: "sundee_premium"
        ))
    }

    /// Creates a mock client with an expired subscription.
    public static func expired(tier: SubscriptionTier = .plus) -> MockSubscriptionClient {
        MockSubscriptionClient(subscription: SubscriptionInfo(
            tier: tier,
            status: .expired,
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
            expiryDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
            willRenew: false,
            entitlementId: "sundee_\(tier.rawValue)"
        ))
    }
}
