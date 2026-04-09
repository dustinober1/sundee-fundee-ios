import Foundation

// MARK: - FreeSubscriptionClient

/// Free-app subscription client that always returns premium-level access.
///
/// Replaces `StoreKitClient` for the free app launch. All features are
/// fully accessible without a subscription — every protocol method returns
/// premium-tier info with active status. Purchase and restore are no-ops.
public struct FreeSubscriptionClient: SubscriptionClientProtocol {

    public init() {}

    private var premiumInfo: SubscriptionInfo {
        SubscriptionInfo(tier: .premium, status: .active)
    }

    public var currentSubscription: SubscriptionInfo? {
        premiumInfo
    }

    public func getSubscriptionInfo() async throws -> SubscriptionInfo {
        premiumInfo
    }

    public func purchase(tier: SubscriptionTier) async throws -> SubscriptionInfo {
        premiumInfo
    }

    public func restorePurchases() async throws -> SubscriptionInfo {
        premiumInfo
    }

    public func presentManageSubscriptions() async throws {
        // No-op: no subscription management in free app
    }

    public func isTierAvailable(_ tier: SubscriptionTier) async -> Bool {
        true
    }

    public func getPrice(for tier: SubscriptionTier) async -> String? {
        nil
    }
}
