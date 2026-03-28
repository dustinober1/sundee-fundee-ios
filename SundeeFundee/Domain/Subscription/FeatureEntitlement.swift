import Foundation

/// Features that can be gated behind a subscription tier.
enum GatedFeature: String, CaseIterable, Sendable {
    // Plus features
    case customBenchmarks
    case painTrends
    case effortTrends
    case unlimitedLifts
    case unlimitedInjuries
    case unlimitedHistory
    case programBuilder
    case periodizationTemplates
    case autoDeload
    case advancedAnalytics
    case streaksAchievements

    // Premium features
    case rehabSessions
    case aiWorkoutHistory
    case exportData
    case aiCoachMemory
    case mesocyclePlans
    case progressiveOverload
    case plateauDetection
    case weeklyReports
    case smartSubstitutions

    var displayName: String {
        switch self {
        case .customBenchmarks:       return "Custom Benchmarks"
        case .painTrends:             return "Recovery Trend Insights"
        case .effortTrends:           return "Workout Intelligence Trends"
        case .unlimitedLifts:         return "Unlimited Lift Tracking"
        case .unlimitedInjuries:      return "Unlimited Injury Profiles"
        case .unlimitedHistory:       return "Unlimited Workout History"
        case .programBuilder:         return "Custom Program Builder"
        case .periodizationTemplates: return "Periodization Templates"
        case .autoDeload:             return "Auto-Deload Scheduling"
        case .advancedAnalytics:      return "Advanced Analytics Dashboard"
        case .streaksAchievements:    return "Streaks & Achievements"
        case .rehabSessions:          return "Personalized Recovery Coaching"
        case .aiWorkoutHistory:       return "Coach Memory & Saved AI Workouts"
        case .exportData:             return "Progress Exports"
        case .aiCoachMemory:          return "Persistent AI Coach Memory"
        case .mesocyclePlans:         return "AI Mesocycle Plans"
        case .progressiveOverload:    return "Progressive Overload Tracking"
        case .plateauDetection:       return "Plateau Detection & Recommendations"
        case .weeklyReports:          return "Weekly AI Training Reports"
        case .smartSubstitutions:     return "Smart Exercise Substitutions"
        }
    }

    var featureDescription: String {
        switch self {
        case .customBenchmarks:       return "Create and track your own custom benchmark workouts."
        case .painTrends:             return "Unlock smarter recovery trend insights and pattern detection."
        case .effortTrends:           return "See advanced workout intelligence across your recent sessions."
        case .unlimitedLifts:         return "Track unlimited lifts and one-rep maxes."
        case .unlimitedInjuries:      return "Manage multiple active injury profiles simultaneously."
        case .unlimitedHistory:       return "Access your complete workout history without time limits."
        case .programBuilder:         return "Create your own multi-week training programs."
        case .periodizationTemplates: return "Use pre-built linear, undulating, and block periodization structures."
        case .autoDeload:             return "AI suggests deload weeks based on training volume and fatigue."
        case .advancedAnalytics:      return "Volume trends, intensity tracking, and muscle group balance."
        case .streaksAchievements:    return "Track consistency streaks and earn milestone badges."
        case .rehabSessions:          return "Get premium recovery coaching tailored to your current needs."
        case .aiWorkoutHistory:       return "Save workouts with coach memory for more personalized follow-ups."
        case .exportData:             return "Export progress data and coaching-ready summaries."
        case .aiCoachMemory:          return "Your AI coach remembers your training history and preferences."
        case .mesocyclePlans:         return "Multi-week periodized plans tailored to your cycle phase and goals."
        case .progressiveOverload:    return "Automatic load progression suggestions based on your performance."
        case .plateauDetection:       return "AI identifies stalls and suggests programming changes."
        case .weeklyReports:          return "Weekly summary of volume, intensity, recovery, and recommendations."
        case .smartSubstitutions:     return "Context-aware exercise swaps based on equipment, injuries, and fatigue."
        }
    }
}

/// Pure-logic feature gating — no framework dependencies. All static for testability.
enum FeatureEntitlement {

    // MARK: - Tracking Limits

    static func maxTrackedLifts(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free:    return 5
        case .plus:    return nil
        case .premium: return nil
        }
    }

    static func maxActiveInjuries(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free:    return 1
        case .plus:    return nil
        case .premium: return nil
        }
    }

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
        case .customBenchmarks, .painTrends, .effortTrends,
             .unlimitedLifts, .unlimitedInjuries, .unlimitedHistory,
             .programBuilder, .periodizationTemplates, .autoDeload,
             .advancedAnalytics, .streaksAchievements:
            return .plus
        case .rehabSessions, .aiWorkoutHistory, .exportData,
             .aiCoachMemory, .mesocyclePlans, .progressiveOverload,
             .plateauDetection, .weeklyReports, .smartSubstitutions:
            return .premium
        }
    }
}
