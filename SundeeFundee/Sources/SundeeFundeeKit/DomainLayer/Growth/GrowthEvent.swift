import Foundation

public struct GrowthEvent: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let dateCreated: Date
    public let source: String?
    public let propertiesJSON: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        dateCreated: Date = Date(),
        source: String? = nil,
        propertiesJSON: String? = nil
    ) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.source = source
        self.propertiesJSON = propertiesJSON
    }
}

public enum GrowthEventName {
    public static let postWorkoutCheckInCompleted = "post_workout_check_in_completed"
    public static let bestNextWorkoutGenerated = "best_next_20_generated"
    public static let onboardingStarted = "onboarding_started"
    public static let onboardingCompleted = "onboarding_completed"
    public static let firstWorkoutPromptSeen = "first_workout_prompt_seen"
    public static let firstWorkoutStarted = "first_workout_started"
    public static let firstWorkoutCompleted = "first_workout_completed"
    public static let shareSheetOpened = "share_sheet_opened"
    public static let shareCompletedWorkoutTapped = "share_completed_workout_tapped"
    public static let sharePRTapped = "share_pr_tapped"
    public static let shareChallengeTapped = "share_challenge_tapped"
    public static let challengeCreated = "challenge_created"
    public static let challengeInviteShared = "challenge_invite_shared"
    public static let reminderScheduled = "reminder_scheduled"
    public static let reminderOpened = "reminder_opened"
    public static let aiWorkoutGenerated = "ai_workout_generated"
    public static let aiWorkoutStarted = "ai_workout_started"
    public static let painAwareSubstitutionUsed = "pain_aware_substitution_used"
    public static let cycleAwareAdjustmentShown = "cycle_aware_adjustment_shown"
    public static let onDeviceCopyAttempted = "on_device_copy_attempted"
    public static let onDeviceCopyAccepted = "on_device_copy_accepted"
    public static let onDeviceCopyRejected = "on_device_copy_rejected"
    public static let onDeviceCopyFallbackUsed = "on_device_copy_fallback_used"
    public static let coachPlanFeedbackHelpful = "coach_plan_feedback_helpful"
    public static let coachPlanFeedbackNotHelpful = "coach_plan_feedback_not_helpful"
    public static let featureTourStarted = "feature_tour_started"
    public static let featureTourCompleted = "feature_tour_completed"
    public static let featureTourSkipped = "feature_tour_skipped"
    public static let cycleEducationOpened = "cycle_education_opened"
    public static let cycleEducationPhaseExpanded = "cycle_education_phase_expanded"
}
