import Foundation

public enum TodayActionKind: Equatable, Sendable {
    case resumeWorkout(workoutID: String)
    case resumeProgramSession
    case startScheduledWorkout
    case completeFirstWeekChecklist(FirstWeekChecklistKind)
    case startFirstWorkout
}

public struct TodayAction: Equatable, Sendable {
    public let kind: TodayActionKind
    public let title: String
    public let subtitle: String
    public let systemImage: String

    public init(
        kind: TodayActionKind,
        title: String,
        subtitle: String,
        systemImage: String
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

public enum FirstWeekChecklistKind: Equatable, Sendable {
    case firstWorkout
    case logMax
    case weeklySchedule
}

public struct FirstWeekChecklistItem: Equatable, Identifiable, Sendable {
    public let kind: FirstWeekChecklistKind
    public let title: String
    public let actionTitle: String
    public let isComplete: Bool

    public var id: String {
        switch kind {
        case .firstWorkout: return "first-workout"
        case .logMax: return "log-max"
        case .weeklySchedule: return "weekly-schedule"
        }
    }

    public init(
        kind: FirstWeekChecklistKind,
        title: String,
        actionTitle: String,
        isComplete: Bool
    ) {
        self.kind = kind
        self.title = title
        self.actionTitle = actionTitle
        self.isComplete = isComplete
    }
}

public enum TodayGuidanceService {
    private static let recentWorkoutWindow: TimeInterval = 24 * 60 * 60

    public static func primaryAction(
        workouts: [Workout],
        weeklyPlanProgress: WeeklyPlanProgress?,
        firstWeekChecklist: [FirstWeekChecklistItem],
        now: Date = Date()
    ) -> TodayAction {
        if let workout = mostRecentIncompleteWorkout(in: workouts, now: now) {
            return TodayAction(
                kind: .resumeWorkout(workoutID: workout.id),
                title: "Resume \(workout.name)",
                subtitle: "Pick up where you left off and finish this session.",
                systemImage: "arrow.forward.circle.fill"
            )
        }

        if let weeklyPlanProgress,
           weeklyPlanProgress.completed < weeklyPlanProgress.target,
           weeklyPlanProgress.nextWorkoutWeekday != nil {
            return TodayAction(
                kind: .startScheduledWorkout,
                title: "Start this week's workout",
                subtitle: weeklyPlanProgress.displayText,
                systemImage: "calendar.badge.clock"
            )
        }

        if let incomplete = firstWeekChecklist.first(where: { !$0.isComplete }) {
            return TodayAction(
                kind: .completeFirstWeekChecklist(incomplete.kind),
                title: incomplete.actionTitle,
                subtitle: incomplete.title,
                systemImage: "checklist"
            )
        }

        return TodayAction(
            kind: .startFirstWorkout,
            title: "Start a workout",
            subtitle: "Build a Coach Plan for today.",
            systemImage: "figure.strengthtraining.traditional"
        )
    }

    public static func firstWeekChecklist(
        completedWorkoutCount: Int,
        maxCount: Int,
        hasWeeklyPlan: Bool
    ) -> [FirstWeekChecklistItem] {
        [
            FirstWeekChecklistItem(
                kind: .firstWorkout,
                title: "Complete your first workout",
                actionTitle: "Start first workout",
                isComplete: completedWorkoutCount > 0
            ),
            FirstWeekChecklistItem(
                kind: .logMax,
                title: "Log one strength max",
                actionTitle: "Log a max",
                isComplete: maxCount > 0
            ),
            FirstWeekChecklistItem(
                kind: .weeklySchedule,
                title: "Set your weekly schedule",
                actionTitle: "Set schedule",
                isComplete: hasWeeklyPlan
            )
        ]
    }

    private static func mostRecentIncompleteWorkout(in workouts: [Workout], now: Date) -> Workout? {
        workouts
            .filter { workout in
                let age = now.timeIntervalSince(workout.date)
                return workout.completedAt == nil && age >= 0 && age < recentWorkoutWindow
            }
            .sorted { $0.date > $1.date }
            .first
    }
}
