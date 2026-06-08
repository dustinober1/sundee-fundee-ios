import Foundation

public enum MinimalNavigationTab: String, Sendable, Equatable, CaseIterable {
    case today
    case train
    case cycle
    case progress
}

public enum TodaySecondarySection: String, Sendable, Equatable, CaseIterable {
    case weeklyPlan
    case missedWorkoutPlan
    case firstWeekChecklist
    case recoveryInputs
    case activeChallenge
    case coachInsights
    case recentWins
}

public struct TodaySecondarySectionInput: Sendable, Equatable {
    public let hasWeeklyPlan: Bool
    public let hasMissedWorkoutPlan: Bool
    public let hasFirstWeekChecklist: Bool
    public let hasRecoveryInputGaps: Bool
    public let hasActiveChallenge: Bool
    public let hasCoachInsights: Bool
    public let hasRecentWins: Bool

    public init(
        hasWeeklyPlan: Bool,
        hasMissedWorkoutPlan: Bool,
        hasFirstWeekChecklist: Bool,
        hasRecoveryInputGaps: Bool,
        hasActiveChallenge: Bool,
        hasCoachInsights: Bool,
        hasRecentWins: Bool
    ) {
        self.hasWeeklyPlan = hasWeeklyPlan
        self.hasMissedWorkoutPlan = hasMissedWorkoutPlan
        self.hasFirstWeekChecklist = hasFirstWeekChecklist
        self.hasRecoveryInputGaps = hasRecoveryInputGaps
        self.hasActiveChallenge = hasActiveChallenge
        self.hasCoachInsights = hasCoachInsights
        self.hasRecentWins = hasRecentWins
    }
}

public enum ProgressDestination: String, Sendable, Equatable, CaseIterable {
    case monthlyReview
    case analytics
    case maxes
    case benchmarks
    case challenges
    case buddyCheckIns
    case export
}

public struct ProgressDestinationInput: Sendable, Equatable {
    public let hasMaxes: Bool
    public let hasBenchmarks: Bool
    public let hasChallenges: Bool
    public let hasBuddyCheckIns: Bool
    public let hasMonthlyReview: Bool
    public let hasAnalytics: Bool
    public let alwaysShowExport: Bool

    public init(
        hasMaxes: Bool,
        hasBenchmarks: Bool,
        hasChallenges: Bool,
        hasBuddyCheckIns: Bool,
        hasMonthlyReview: Bool,
        hasAnalytics: Bool,
        alwaysShowExport: Bool
    ) {
        self.hasMaxes = hasMaxes
        self.hasBenchmarks = hasBenchmarks
        self.hasChallenges = hasChallenges
        self.hasBuddyCheckIns = hasBuddyCheckIns
        self.hasMonthlyReview = hasMonthlyReview
        self.hasAnalytics = hasAnalytics
        self.alwaysShowExport = alwaysShowExport
    }
}

public enum SharePromptMoment: String, Sendable, Equatable, CaseIterable {
    case completedWorkout
    case personalRecord
    case challengeMilestone
    case monthlyReview
    case cycleInsight
}

public enum MinimalSurfacePolicy {
    public static let primaryTabs: [MinimalNavigationTab] = [.today, .train, .cycle, .progress]

    public static func todaySecondarySections(input: TodaySecondarySectionInput) -> [TodaySecondarySection] {
        var sections: [TodaySecondarySection] = []
        if input.hasWeeklyPlan { sections.append(.weeklyPlan) }
        if input.hasMissedWorkoutPlan { sections.append(.missedWorkoutPlan) }
        if input.hasFirstWeekChecklist { sections.append(.firstWeekChecklist) }
        if input.hasRecoveryInputGaps { sections.append(.recoveryInputs) }
        if input.hasActiveChallenge { sections.append(.activeChallenge) }
        if input.hasCoachInsights { sections.append(.coachInsights) }
        if input.hasRecentWins { sections.append(.recentWins) }
        return sections
    }

    public static func progressDestinations(input: ProgressDestinationInput) -> [ProgressDestination] {
        var destinations: [ProgressDestination] = []
        if input.hasMonthlyReview { destinations.append(.monthlyReview) }
        if input.hasAnalytics { destinations.append(.analytics) }
        if input.hasMaxes { destinations.append(.maxes) }
        if input.hasBenchmarks { destinations.append(.benchmarks) }
        if input.hasChallenges { destinations.append(.challenges) }
        if input.hasBuddyCheckIns { destinations.append(.buddyCheckIns) }
        if input.alwaysShowExport { destinations.append(.export) }
        return destinations
    }

    public static func shouldPromptShare(for moment: SharePromptMoment) -> Bool {
        switch moment {
        case .personalRecord, .challengeMilestone, .monthlyReview:
            return true
        case .completedWorkout, .cycleInsight:
            return false
        }
    }
}
