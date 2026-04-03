import Foundation

// MARK: - SubscriptionTier

/// The available subscription tiers for Sundee Fundee.
///
/// Each tier offers different feature limits and capabilities.
/// Tier benefits are cumulative - Premium includes all Plus benefits.
public enum SubscriptionTier: String, Sendable, Equatable, Codable, CaseIterable {
    /// Free tier with limited features.
    /// - 5 lifts tracked
    /// - 1 injury profile
    /// - 30-day workout history
    /// - 0 cloud AI generations per day
    case free = "free"

    /// Sundee Plus subscription.
    /// - Unlimited lifts and injuries
    /// - Full workout history
    /// - 1 cloud AI generation per day
    /// - Custom benchmarks
    /// - Pain trend analysis
    case plus = "plus"

    /// Sundee Premium subscription.
    /// - All Plus features
    /// - 10 cloud AI generations per day
    /// - Rehab session recommendations
    /// - AI coach memory
    /// - Plateau detection
    case premium = "premium"

    // MARK: - Feature Limits

    /// Maximum number of lifts that can be tracked.
    public var maxLifts: Int? {
        switch self {
        case .free: return 5
        case .plus, .premium: return nil // Unlimited
        }
    }

    /// Maximum number of injury profiles.
    public var maxInjuries: Int? {
        switch self {
        case .free: return 1
        case .plus, .premium: return nil // Unlimited
        }
    }

    /// Maximum days of workout history retained.
    public var maxHistoryDays: Int? {
        switch self {
        case .free: return 30
        case .plus, .premium: return nil // Unlimited
        }
    }

    /// Number of cloud AI generations allowed per day.
    public var dailyAIGenerations: Int {
        switch self {
        case .free: return 0
        case .plus: return 1
        case .premium: return 10
        }
    }

    /// Whether custom benchmarks are available.
    public var hasCustomBenchmarks: Bool {
        self != .free
    }

    /// Whether pain trend analysis is available.
    public var hasPainTrends: Bool {
        self != .free
    }

    /// Whether rehab session recommendations are available.
    public var hasRehabSessions: Bool {
        self == .premium
    }

    /// Whether AI coach memory is available.
    public var hasAICoachMemory: Bool {
        self == .premium
    }

    /// Whether plateau detection is available.
    public var hasPlateauDetection: Bool {
        self == .premium
    }
}

// MARK: - SubscriptionStatus

/// The current status of a subscription.
public enum SubscriptionStatus: String, Sendable, Equatable, Codable {
    /// Subscription is active and in good standing.
    case active = "active"

    /// Subscription is past due but still active (grace period).
    case pastDue = "past_due"

    /// Subscription is paused (e.g., for vacation).
    case paused = "paused"

    /// Subscription has been cancelled but not yet expired.
    case cancelled = "cancelled"

    /// Subscription has expired.
    case expired = "expired"

    /// Whether the subscription grants access to paid features.
    public var hasAccess: Bool {
        switch self {
        case .active, .pastDue:
            return true
        case .paused, .cancelled, .expired:
            return false
        }
    }
}

// MARK: - SubscriptionInfo

/// Complete information about a user's subscription.
public struct SubscriptionInfo: Sendable, Equatable, Codable {
    /// The current subscription tier.
    public let tier: SubscriptionTier

    /// The current subscription status.
    public let status: SubscriptionStatus

    /// When the subscription started (or will renew).
    public let startDate: Date?

    /// When the current billing period ends.
    public let expiryDate: Date?

    /// Whether the subscription will auto-renew.
    public let willRenew: Bool

    /// The RevenueCat entitlement identifier.
    public let entitlementId: String?

    /// The original transaction ID from App Store.
    public let originalTransactionId: String?

    /// Creates new subscription info.
    public init(
        tier: SubscriptionTier,
        status: SubscriptionStatus,
        startDate: Date? = nil,
        expiryDate: Date? = nil,
        willRenew: Bool = true,
        entitlementId: String? = nil,
        originalTransactionId: String? = nil
    ) {
        self.tier = tier
        self.status = status
        self.startDate = startDate
        self.expiryDate = expiryDate
        self.willRenew = willRenew
        self.entitlementId = entitlementId
        self.originalTransactionId = originalTransactionId
    }

    /// Whether the subscription currently grants access to paid features.
    public var hasAccess: Bool {
        status.hasAccess && tier != .free
    }

    /// Days until the subscription expires (nil if no expiry or unlimited).
    public var daysUntilExpiry: Int? {
        guard let expiry = expiryDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiry)
        return components.day
    }
}
