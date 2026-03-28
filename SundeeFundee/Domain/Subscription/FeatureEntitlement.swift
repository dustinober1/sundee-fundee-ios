import Foundation

/// Features that can be gated behind a subscription tier.
enum GatedFeature: String, CaseIterable, Sendable {
    case customBenchmarks
    case painTrends
    case effortTrends
    case wodExecution
    case unlimitedLifts
    case unlimitedInjuries
    case unlimitedHistory
    case rehabSessions
    case aiWorkoutHistory
    case exportData

    var displayName: String {
        switch self {
        case .customBenchmarks:  return "Custom Benchmarks"
        case .painTrends:        return "Recovery Trend Insights"
        case .effortTrends:      return "Workout Intelligence Trends"
        case .wodExecution:      return "WOD Execution"
        case .unlimitedLifts:    return "Unlimited Lift Tracking"
        case .unlimitedInjuries: return "Unlimited Injury Profiles"
        case .unlimitedHistory:  return "Unlimited Workout History"
        case .rehabSessions:     return "Personalized Recovery Coaching"
        case .aiWorkoutHistory:  return "Coach Memory & Saved AI Workouts"
        case .exportData:        return "Progress Exports"
        }
    }

    var featureDescription: String {
        switch self {
        case .customBenchmarks:  return "Create and track your own custom benchmark workouts."
        case .painTrends:        return "Unlock smarter recovery trend insights and pattern detection."
        case .effortTrends:      return "See advanced workout intelligence across your recent sessions."
        case .wodExecution:      return "Execute and log the daily Workout of the Day."
        case .unlimitedLifts:    return "Track unlimited lifts and one-rep maxes."
        case .unlimitedInjuries: return "Manage multiple active injury profiles simultaneously."
        case .unlimitedHistory:  return "Access your complete workout history without time limits."
        case .rehabSessions:     return "Get premium recovery coaching tailored to your current needs."
        case .aiWorkoutHistory:  return "Save workouts with coach memory for more personalized follow-ups."
        case .exportData:        return "Export progress data and coaching-ready summaries."
        }
    }
}

/// Pure-logic feature gating — no framework dependencies. All static for testability.
enum FeatureEntitlement {

    // MARK: - Tracking Limits

    /// Maximum tracked lifts. Returns nil for unlimited.
    static func maxTrackedLifts(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free:    return 5
        case .plus:    return nil
        case .premium: return nil
        }
    }

    /// Maximum active injury profiles. Returns nil for unlimited.
    static func maxActiveInjuries(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free:    return 1
        case .plus:    return nil
        case .premium: return nil
        }
    }

    /// Workout history day limit. Returns nil for unlimited.
    static func workoutHistoryDaysLimit(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free:    return 30
        case .plus:    return nil
        case .premium: return nil
        }
    }

    // MARK: - Feature Access

    static func canAccess(feature: GatedFeature, tier: SubscriptionTier) -> Bool {
        tier.rank >= minimumTierRequired(for: feature).rank
    }

    static func minimumTierRequired(for feature: GatedFeature) -> SubscriptionTier {
        switch feature {
        case .customBenchmarks, .painTrends, .effortTrends, .wodExecution,
             .unlimitedLifts, .unlimitedInjuries, .unlimitedHistory:
            return .plus
        case .rehabSessions, .aiWorkoutHistory, .exportData:
            return .premium
        }
    }
}
