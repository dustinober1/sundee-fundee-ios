import Foundation

// MARK: - SubscriptionTier

/// The available subscription tiers for Sundee Fundee.
///
/// Each tier offers different feature limits and capabilities.
/// Tier benefits are cumulative - Pro includes all Plus benefits.
///
/// Internal enum values stay as `.free`, `.plus`, `.premium` to avoid
/// migration churn. Customer-facing copy uses "Pro" via `displayName`.
public enum SubscriptionTier: String, Sendable, Equatable, Codable, CaseIterable {
    /// Free tier with limited features.
    /// - 5 lifts tracked
    /// - 1 injury profile
    /// - 30-day workout history
    /// - Basic workout suggestions
    /// - Prebuilt benchmarks only
    /// - Basic cycle-aware training hints
    case free = "free"

    /// Sundee Plus ($2.99/mo).
    /// - Unlimited lifts, injuries, and history
    /// - Advanced charts (volume, consistency, muscle balance, pain/effort trends)
    /// - Custom benchmarks
    /// - On-device AI workout builder
    /// - Edit-before-save workout flow
    /// - Saved templates and prompt presets
    /// - Weekly planner draft
    /// - Smart lighter-day adjustments (energy/cycle phase)
    case plus = "plus"

    /// Sundee Pro ($4.99/mo). Internal key remains `premium`.
    /// - Everything in Plus
    /// - Coach memory across sessions
    /// - Adaptive weekly programming
    /// - Missed-workout reshuffle
    /// - Plateau detection with specific next steps
    /// - Smart substitutions (pain, equipment, time)
    /// - Weekly recap + next-week recommendations
    /// - Preference learning from edits and accepted swaps
    /// - Export/share plan summaries
    case premium = "premium"

    // MARK: - Display

    /// Customer-facing tier name.
    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Plus"
        case .premium: return "Pro"
        }
    }

    /// Short marketing tagline for each tier.
    public var tagline: String {
        switch self {
        case .free: return "Get started"
        case .plus: return "Smarter planning on demand"
        case .premium: return "A coach that remembers and adapts"
        }
    }

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
        case .plus: return 3
        case .premium: return 10
        }
    }

    // MARK: - Capability Flags

    /// Whether custom benchmarks are available.
    public var hasCustomBenchmarks: Bool {
        self != .free
    }

    /// Whether pain/effort trend analysis is available.
    public var hasPainTrends: Bool {
        self != .free
    }

    /// Whether advanced analytics (volume, consistency, muscle balance) are available.
    public var hasAdvancedInsights: Bool {
        self != .free
    }

    /// Whether the on-device AI workout builder is available.
    public var hasAIBuilder: Bool {
        self != .free
    }

    /// Whether recovery-aware training adjustments are available.
    /// Replaces the previous "rehab sessions" concept with broader
    /// pain-aware movement modifications and lighter-day suggestions.
    public var hasRecoveryAdjustments: Bool {
        self != .free
    }

    /// Whether adaptive weekly programming (reshuffle, auto-adjust) is available.
    public var hasAdaptivePlanner: Bool {
        self == .premium
    }

    /// Whether AI coach memory persists across sessions.
    public var hasCoachMemory: Bool {
        self == .premium
    }

    /// Whether smart exercise substitutions (pain, equipment, time) are available.
    public var hasSmartSubstitutions: Bool {
        self == .premium
    }

    /// Whether plateau detection with actionable recommendations is available.
    public var hasPlateauDetection: Bool {
        self == .premium
    }

    /// Whether preference learning from edits and accepted swaps is available.
    public var hasPreferenceLearning: Bool {
        self == .premium
    }

    /// Whether weekly recap and next-week recommendations are available.
    public var hasWeeklyRecap: Bool {
        self == .premium
    }

    /// Whether plan export/share is available.
    public var hasExportShare: Bool {
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
