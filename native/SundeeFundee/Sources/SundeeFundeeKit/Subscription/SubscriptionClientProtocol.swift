import Foundation

// MARK: - SubscriptionClientProtocol

/// Protocol defining subscription management operations.
///
/// Implementations handle subscription status checking, purchasing,
/// restoration, and customer info management.
///
/// ## Example Usage
/// ```swift
/// // Check current subscription
/// let info = try await subscriptionClient.getSubscriptionInfo()
/// if info.hasAccess {
///     // Enable premium features
/// }
///
/// // Purchase a subscription
/// try await subscriptionClient.purchase(tier: .plus)
///
/// // Restore previous purchases
/// try await subscriptionClient.restorePurchases()
/// ```
public protocol SubscriptionClientProtocol: Sendable {
    /// The current subscription info, if any.
    ///
    /// Returns cached subscription info without making network requests.
    /// May return a free tier if no subscription is active.
    var currentSubscription: SubscriptionInfo? { get async }

    /// Gets the latest subscription info from the server.
    ///
    /// - Returns: The current subscription information.
    /// - Throws: `SubscriptionError` if the fetch fails.
    func getSubscriptionInfo() async throws -> SubscriptionInfo

    /// Purchases a subscription for the specified tier.
    ///
    /// - Parameter tier: The subscription tier to purchase.
    /// - Returns: The updated subscription info after purchase.
    /// - Throws: `SubscriptionError` if the purchase fails.
    func purchase(tier: SubscriptionTier) async throws -> SubscriptionInfo

    /// Restores previous purchases for the current Apple ID.
    ///
    /// - Returns: The restored subscription info, if any.
    /// - Throws: `SubscriptionError` if restoration fails or no purchases found.
    func restorePurchases() async throws -> SubscriptionInfo

    /// Presents the App Store's manage subscriptions UI.
    ///
    /// This opens the App Store where users can manage their subscription.
    func presentManageSubscriptions() async throws

    /// Checks if a specific tier is available for purchase.
    ///
    /// - Parameter tier: The tier to check.
    /// - Returns: Whether the tier is available.
    func isTierAvailable(_ tier: SubscriptionTier) async -> Bool

    /// Gets the localized price string for a tier.
    ///
    /// - Parameter tier: The tier to get pricing for.
    /// - Returns: The localized price (e.g., "$9.99/month") or nil if unavailable.
    func getPrice(for tier: SubscriptionTier) async -> String?
}
