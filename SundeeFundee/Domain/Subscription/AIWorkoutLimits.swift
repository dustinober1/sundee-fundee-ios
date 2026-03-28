import Foundation

/// Pure-logic AI workout generation limits per subscription tier.
/// No framework dependencies — fully unit tested.
enum AIWorkoutLimits {

    /// Maximum AI workouts per calendar month. Returns nil for unlimited.
    static func monthlyLimit(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free:    return 3
        case .plus:    return 15
        case .premium: return nil
        }
    }

    /// Whether the user can generate another AI workout this month.
    static func canGenerate(tier: SubscriptionTier, generatedThisMonth: Int) -> Bool {
        guard let limit = monthlyLimit(for: tier) else { return true }
        return generatedThisMonth < limit
    }

    /// Number of remaining AI workouts this month, or nil if unlimited.
    static func remainingGenerations(tier: SubscriptionTier, generatedThisMonth: Int) -> Int? {
        guard let limit = monthlyLimit(for: tier) else { return nil }
        return max(0, limit - generatedThisMonth)
    }

    /// User-facing text showing remaining AI workouts.
    static func remainingText(tier: SubscriptionTier, generatedThisMonth: Int) -> String? {
        guard let limit = monthlyLimit(for: tier) else { return nil }
        let remaining = max(0, limit - generatedThisMonth)
        return "\(remaining) of \(limit) AI workouts left this month"
    }
}
