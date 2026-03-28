import Foundation

/// Event taxonomy for monetization and feature usage analytics.
/// Raw string values provide stable event identifiers for analytics backends.
enum AnalyticsEvent: String, CaseIterable, Sendable {
    // Paywall
    case paywallImpression = "paywall_impression"
    case paywallDismissed = "paywall_dismissed"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseCancelled = "purchase_cancelled"
    case purchaseFailed = "purchase_failed"
    case restoreStarted = "restore_started"
    case restoreCompleted = "restore_completed"

    // Feature gating
    case featureGateTapped = "feature_gate_tapped"
    case limitReached = "limit_reached"

    // Subscription lifecycle
    case subscriptionChanged = "subscription_changed"
    case trialStarted = "trial_started"

    // Cloud AI
    case cloudAIWorkoutGenerated = "cloud_ai_workout_generated"
    case cloudAIDailyLimitReached = "cloud_ai_daily_limit_reached"
    case cloudAISoftNudgeShown = "cloud_ai_soft_nudge_shown"
    case workoutEditedBeforeStart = "workout_edited_before_start"

    static func eventName(for event: AnalyticsEvent) -> String {
        event.rawValue
    }
}
