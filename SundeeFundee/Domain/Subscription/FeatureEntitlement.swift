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
        case .painTrends:        return "Pain Trend Analysis"
        case .effortTrends:      return "Effort Trends"
        case .wodExecution:      return "WOD Execution"
        case .unlimitedLifts:    return "Unlimited Lift Tracking"
        case .unlimitedInjuries: return "Unlimited Injury Profiles"
        case .unlimitedHistory:  return "Unlimited Workout History"
        case .rehabSessions:     return "Rehab Sessions"
        case .aiWorkoutHistory:  return "AI Workout History & Favorites"
        case .exportData:        return "Export Workout Data"
        }
    }

    var featureDescription: String {
        switch self {
        case .customBenchmarks:  return "Create and track your own custom benchmark workouts."
        case .painTrends:        return "Visualize pain trends over time with sparkline charts."
        case .effortTrends:      return "See your average perceived effort across recent workouts."
        case .wodExecution:      return "Execute the daily Workout of the Day with full logging."
        case .unlimitedLifts:    return "Track unlimited lifts and one-rep maxes."
        case .unlimitedInjuries: return "Manage multiple active injury profiles simultaneously."
        case .unlimitedHistory:  return "Access your complete workout history without time limits."
        case .rehabSessions:     return "Auto-generated recovery sessions tailored to your injuries."
        case .aiWorkoutHistory:  return "Save, favorite, and revisit your AI-generated workouts."
        case .exportData:        return "Export your workout data for analysis in other tools."
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
