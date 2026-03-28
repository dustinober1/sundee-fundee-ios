import Foundation

/// Pure-logic AI workout generation limits per subscription tier.
/// On-device generation is unlimited for all tiers.
/// Cloud AI (Anthropic) generation is gated by daily limits per tier.
enum AIWorkoutLimits {

    /// Soft nudge threshold for Premium users (show "try editing" message).
    static let premiumSoftNudgeThreshold = 7

    /// Maximum cloud AI generations per day. 0 means no cloud access.
    static func dailyCloudLimit(for tier: SubscriptionTier) -> Int {
        switch tier {
        case .free:    return 0
        case .plus:    return 1
        case .premium: return 10
        }
    }

    /// Whether the user can generate another cloud AI workout today.
    static func canGenerateCloud(tier: SubscriptionTier, generatedToday: Int) -> Bool {
        let limit = dailyCloudLimit(for: tier)
        guard limit > 0 else { return false }
        return generatedToday < limit
    }

    /// On-device AI is always available regardless of tier.
    static func canGenerateOnDevice(tier: SubscriptionTier) -> Bool {
        true
    }

    /// Whether to show the soft nudge ("try editing your workout instead") for Premium users.
    static func shouldShowSoftNudge(tier: SubscriptionTier, generatedToday: Int) -> Bool {
        tier == .premium && generatedToday >= premiumSoftNudgeThreshold
    }

    /// User-facing text showing remaining cloud AI workouts today.
    /// Returns nil for free tier (no cloud access).
    static func remainingCloudText(tier: SubscriptionTier, generatedToday: Int) -> String? {
        let limit = dailyCloudLimit(for: tier)
        guard limit > 0 else { return nil }
        let remaining = max(0, limit - generatedToday)
        if limit == 1 {
            return remaining > 0
                ? "1 cloud AI workout available today"
                : "Daily cloud AI workout used — try on-device AI or come back tomorrow"
        }
        return "\(remaining) of \(limit) cloud AI workouts left today"
    }
}
