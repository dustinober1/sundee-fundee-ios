import XCTest
@testable import SundeeFundeeKit

final class TodayGuidanceServiceTests: XCTestCase {
    func testTodayActionPrefersRecentIncompleteWorkoutOverWeeklyPlan() {
        let now = Date()
        let workout = Workout(
            id: "resume-1",
            date: now.addingTimeInterval(-30 * 60),
            name: "Upper Body",
            exercises: [],
            completedAt: nil
        )
        let progress = WeeklyPlanProgress(completed: 0, target: 3, nextWorkoutWeekday: 2)

        let action = TodayGuidanceService.primaryAction(
            workouts: [workout],
            weeklyPlanProgress: progress,
            firstWeekChecklist: [],
            recoveryInputs: []
        )

        XCTAssertEqual(action.kind, .resumeWorkout(workoutID: "resume-1"))
        XCTAssertEqual(action.title, "Resume Upper Body")
    }

    func testTodayActionIgnoresStaleIncompleteWorkout() {
        let now = Date()
        let workout = Workout(
            id: "stale",
            date: now.addingTimeInterval(-26 * 60 * 60),
            name: "Old Session",
            exercises: [],
            completedAt: nil
        )
        let progress = WeeklyPlanProgress(completed: 1, target: 3, nextWorkoutWeekday: 4)

        let action = TodayGuidanceService.primaryAction(
            workouts: [workout],
            weeklyPlanProgress: progress,
            firstWeekChecklist: [],
            recoveryInputs: []
        )

        XCTAssertEqual(action.kind, .startScheduledWorkout)
        XCTAssertEqual(action.title, "Start this week's workout")
    }

    func testFirstWeekChecklistReflectsWorkoutMaxAndWeeklyPlan() {
        let items = TodayGuidanceService.firstWeekChecklist(
            completedWorkoutCount: 1,
            maxCount: 0,
            hasWeeklyPlan: true
        )

        XCTAssertEqual(items.map(\.isComplete), [true, false, true])
        XCTAssertEqual(items.first(where: { !$0.isComplete })?.kind, .logMax)
    }

    func testRecoveryChecklistMarksMissingInputsWithActions() {
        let items = TodayGuidanceService.recoveryInputStatuses(
            hasRecentWorkout: true,
            hasPainLogToday: false,
            hasCyclePhase: false,
            hasSleep: true,
            hasHRV: false
        )

        XCTAssertEqual(items.filter(\.isAvailable).map(\.kind), [.recentWorkout, .sleep])
        XCTAssertEqual(items.filter { !$0.isAvailable }.map(\.kind), [.painLog, .cyclePhase, .hrv])
        XCTAssertTrue(items.first { $0.kind == .painLog }?.actionTitle == "Log pain")
    }
}
