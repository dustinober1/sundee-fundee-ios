import Foundation

// MARK: - MissedWorkoutRecoveryPlan

/// A user-facing recovery plan produced when workouts have been missed.
///
/// Wraps the raw `ScheduleReshuffler.ReshuffleResult` with presentable
/// copy for the dashboard card.
public struct MissedWorkoutRecoveryPlan: Sendable, Equatable {
    /// The raw reshuffle result from `ScheduleReshuffler`.
    public let result: ScheduleReshuffler.ReshuffleResult

    /// A human-readable summary for the recovery card body.
    public let userSummary: String

    /// The title for the primary action button.
    public let actionTitle: String

    public init(
        result: ScheduleReshuffler.ReshuffleResult,
        userSummary: String,
        actionTitle: String
    ) {
        self.result = result
        self.userSummary = userSummary
        self.actionTitle = actionTitle
    }
}

// MARK: - MissedWorkoutRecoveryService

/// Pure domain service that detects missed workouts and produces a
/// recovery plan by delegating to `ScheduleReshuffler`.
///
/// Returns `nil` when no recovery is needed (no missed days).
public enum MissedWorkoutRecoveryService {

    /// Produces a recovery plan for missed workout sessions.
    ///
    /// - Parameters:
    ///   - weeklyPlan: The originally planned sessions for the week.
    ///   - completedDays: Set of weekday numbers (1 = Mon, 7 = Sun) already completed.
    ///   - missedDays: Set of weekday numbers where sessions were missed.
    ///   - currentDay: The current weekday number (1-7).
    /// - Returns: A `MissedWorkoutRecoveryPlan` when recovery is needed, or `nil`.
    public static func recoveryPlan(
        weeklyPlan: [ScheduleReshuffler.PlannedSession],
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int
    ) -> MissedWorkoutRecoveryPlan? {
        guard !missedDays.isEmpty else { return nil }

        let reshuffleResult = ScheduleReshuffler.reshuffle(
            plan: weeklyPlan,
            completedDays: completedDays,
            missedDays: missedDays,
            currentDay: currentDay
        )

        let rescheduledCount = reshuffleResult.rescheduledSessions.filter { session in
            missedDays.contains { missedDay in
                weeklyPlan.contains {
                    $0.dayOfWeek == missedDay && $0.sessionName == session.sessionName
                }
            }
        }.count
        let droppedCount = reshuffleResult.droppedSessions.count

        let userSummary = buildUserSummary(
            rescheduledCount: rescheduledCount,
            droppedCount: droppedCount,
            missedCount: missedDays.count
        )

        let actionTitle = droppedCount > 0
            ? "Apply new week"
            : "Recover this week"

        return MissedWorkoutRecoveryPlan(
            result: reshuffleResult,
            userSummary: userSummary,
            actionTitle: actionTitle
        )
    }

    // MARK: - Private

    private static func buildUserSummary(
        rescheduledCount: Int,
        droppedCount: Int,
        missedCount: Int
    ) -> String {
        var parts: [String] = []

        if rescheduledCount > 0 {
            let sessionWord = rescheduledCount == 1 ? "workout" : "workouts"
            parts.append("Rescheduled \(rescheduledCount) \(sessionWord)")
        }

        if droppedCount > 0 {
            let sessionWord = droppedCount == 1 ? "session" : "sessions"
            parts.append("dropped \(droppedCount) conditioning \(sessionWord)")
        }

        if parts.isEmpty {
            return "You missed \(missedCount) \(missedCount == 1 ? "workout" : "workouts") but no changes were needed."
        }

        return parts.joined(separator: ", ")
    }
}
