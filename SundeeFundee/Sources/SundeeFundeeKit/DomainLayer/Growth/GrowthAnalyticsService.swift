import Foundation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor GrowthAnalyticsService {
    private let dataClient: DataClientProtocol
    private static let recordType = "GrowthEvent"

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    public func track(
        _ name: String,
        source: String? = nil,
        properties: [String: String] = [:]
    ) async {
        // Analytics is presentation telemetry only. Unknown event names and
        // fields are rejected so arbitrary caller text cannot become telemetry.
        guard Self.allowedEventNames.contains(name) else { return }
        let safeSource = Self.allowedSources.contains(source ?? "") ? source : nil
        let safeProperties = Dictionary(uniqueKeysWithValues: properties.compactMap { key, value -> (String, String)? in
            Self.sanitizeProperty(key: key, value: value)
        })
        let propertiesJSON: String?
        if safeProperties.isEmpty {
            propertiesJSON = nil
        } else if let data = try? JSONEncoder().encode(safeProperties) {
            propertiesJSON = String(data: data, encoding: .utf8)
        } else {
            propertiesJSON = nil
        }

        let event = GrowthEvent(
            name: name,
            source: safeSource,
            propertiesJSON: propertiesJSON
        )

        try? await dataClient.save(event, recordType: Self.recordType)
    }

    private static let allowedEventNames: Set<String> = [
        GrowthEventName.onboardingStarted, GrowthEventName.onboardingCompleted,
        GrowthEventName.firstWorkoutPromptSeen, GrowthEventName.firstWorkoutStarted,
        GrowthEventName.firstWorkoutCompleted, GrowthEventName.shareSheetOpened,
        GrowthEventName.shareCompletedWorkoutTapped, GrowthEventName.sharePRTapped,
        GrowthEventName.shareChallengeTapped, GrowthEventName.challengeCreated,
        GrowthEventName.challengeInviteShared, GrowthEventName.reminderScheduled,
        GrowthEventName.reminderOpened, GrowthEventName.aiWorkoutGenerated,
        GrowthEventName.aiWorkoutStarted, GrowthEventName.painAwareSubstitutionUsed,
        GrowthEventName.cycleAwareAdjustmentShown, GrowthEventName.onDeviceCopyAttempted,
        GrowthEventName.onDeviceCopyAccepted, GrowthEventName.onDeviceCopyRejected,
        GrowthEventName.onDeviceCopyFallbackUsed, GrowthEventName.coachPlanFeedbackHelpful,
        GrowthEventName.coachPlanFeedbackNotHelpful, GrowthEventName.postWorkoutCheckInCompleted,
        GrowthEventName.bestNextWorkoutGenerated
    ]

    private static let allowedSources: Set<String> = [
        "onboarding", "active_workout", "notification", "workout_reminders", "dashboard",
        "train", "workout_completion", "challenge_card", "ai_workout", "coach_plan", "test",
        ShareSurface.completedWorkout.rawValue, ShareSurface.personalRecord.rawValue,
        ShareSurface.cycleInsight.rawValue, ShareSurface.challenge.rawValue,
        ShareSurface.starterWorkout.rawValue
    ]

    private static func sanitizeProperty(key: String, value: String) -> (String, String)? {
        // Only these structural fields are useful for funnel analysis. In
        // particular, title/from/to and generated copy are never telemetry.
        let allowedKeys = Set(["surface", "route", "equipment", "energy", "decision", "right_for_today", "sourceID", "referralCode", "challengeID", "workoutID"])
        guard allowedKeys.contains(key), value.count <= 120,
              !value.isEmpty,
              !value.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return nil }
        switch key {
        case "surface": return allowedSources.contains(value) ? (key, value) : nil
        case "route": return value == "default" || value == "challenge" ? (key, value) : nil
        case "equipment": return value.range(of: #"^[a-z_]+$"#, options: .regularExpression) != nil ? (key, value) : nil
        case "energy": return ["low", "moderate", "high"].contains(value) ? (key, value) : nil
        case "decision": return ["train", "modify", "recover"].contains(value) ? (key, value) : nil
        case "right_for_today": return value == "true" || value == "false" ? (key, value) : nil
        case "sourceID", "referralCode", "challengeID", "workoutID":
            return value.range(of: #"^[A-Za-z0-9_-]+$"#, options: .regularExpression) != nil ? (key, value) : nil
        default: return nil
        }
    }
}
