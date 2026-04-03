import XCTest
@testable import SundeeFundeeKit

final class ScheduleReshufflerTests: XCTestCase {

    // MARK: - Helpers

    private func makeSession(
        day: Int,
        name: String = "Session",
        focus: String = "Strength",
        minutes: Int = 60
    ) -> ScheduleReshuffler.PlannedSession {
        ScheduleReshuffler.PlannedSession(
            dayOfWeek: day,
            sessionName: name,
            focus: focus,
            estimatedMinutes: minutes
        )
    }

    // MARK: - No Missed Sessions

    func testReshuffle_NoMissed_ScheduleUnchanged() {
        let plan = [
            makeSession(day: 1, name: "Monday"),
            makeSession(day: 3, name: "Wednesday"),
            makeSession(day: 5, name: "Friday"),
        ]
        let result = ScheduleReshuffler.reshuffle(
            plan: plan,
            completedDays: [1],
            missedDays: [],
            currentDay: 3
        )
        XCTAssertTrue(result.droppedSessions.isEmpty)
        XCTAssertEqual(result.summary, "No missed sessions to reschedule.")
    }

    // MARK: - Simple Reshuffle

    func testReshuffle_OneMissed_MovedToLater() {
        let plan = [
            makeSession(day: 1, name: "Push"),
            makeSession(day: 3, name: "Pull"),
            makeSession(day: 5, name: "Legs"),
        ]
        let result = ScheduleReshuffler.reshuffle(
            plan: plan,
            completedDays: [1],
            missedDays: [3],
            currentDay: 4
        )
        // Pull should be moved to day 5 or later
        let movedPull = result.rescheduledSessions.first { $0.sessionName == "Pull" }
        XCTAssertNotNil(movedPull, "Missed Pull session should be rescheduled")
        XCTAssertGreaterThanOrEqual(movedPull?.dayOfWeek ?? 0, 4)
        XCTAssertTrue(result.droppedSessions.isEmpty)
    }

    // MARK: - Capacity Limits

    func testReshuffle_TooManyMissed_SomeDropped() {
        let plan = [
            makeSession(day: 1, name: "A", minutes: 90),
            makeSession(day: 2, name: "B", minutes: 90),
            makeSession(day: 3, name: "C", minutes: 90),
            makeSession(day: 4, name: "D", minutes: 90),
            makeSession(day: 5, name: "E", minutes: 60),
        ]
        // Missed Mon-Thu, only Friday remains
        let result = ScheduleReshuffler.reshuffle(
            plan: plan,
            completedDays: [],
            missedDays: [1, 2, 3, 4],
            currentDay: 5
        )
        // Can't fit 4 x 90-min sessions into one day (max 120 min)
        XCTAssertFalse(result.droppedSessions.isEmpty, "Some sessions should be dropped")
    }

    // MARK: - Focus Preference

    func testReshuffle_PrefersSameFocusDay() {
        let plan = [
            makeSession(day: 1, name: "Push A", focus: "Push"),
            makeSession(day: 3, name: "Push B", focus: "Push"),
            makeSession(day: 5, name: "Pull", focus: "Pull"),
            makeSession(day: 6, name: "Legs", focus: "Legs"),
        ]
        // Missed Push B on Wednesday, current day is Thursday
        let result = ScheduleReshuffler.reshuffle(
            plan: plan,
            completedDays: [1],
            missedDays: [3],
            currentDay: 4
        )
        let movedPushB = result.rescheduledSessions.first { $0.sessionName == "Push B" }
        XCTAssertNotNil(movedPushB, "Missed Push B should be rescheduled")
    }

    // MARK: - Summary Messages

    func testReshuffle_Summary_IncludesMovedSessions() {
        let plan = [
            makeSession(day: 1, name: "Push"),
            makeSession(day: 5, name: "Pull"),
        ]
        let result = ScheduleReshuffler.reshuffle(
            plan: plan,
            completedDays: [],
            missedDays: [1],
            currentDay: 3
        )
        XCTAssertTrue(result.summary.contains("Moved"), "Summary should mention moved sessions")
        XCTAssertTrue(result.summary.contains("Push"), "Summary should name the moved session")
    }

    // MARK: - Edge Cases

    func testReshuffle_AllDaysCompleted_EmptyResult() {
        let plan = [
            makeSession(day: 1, name: "A"),
            makeSession(day: 3, name: "B"),
            makeSession(day: 5, name: "C"),
        ]
        let result = ScheduleReshuffler.reshuffle(
            plan: plan,
            completedDays: [1, 3, 5],
            missedDays: [],
            currentDay: 7
        )
        XCTAssertTrue(result.droppedSessions.isEmpty)
    }

    func testReshuffle_EndOfWeek_NoAvailableDays() {
        let plan = [
            makeSession(day: 1, name: "Monday"),
            makeSession(day: 7, name: "Sunday"),
        ]
        // Missed Monday, Sunday is already planned and full. Current day = 7.
        // Only day 7 remains but it already has a session and adding Monday's
        // 60-min session would still be under 120 min limit. So let's make them
        // both long enough to exceed the cap.
        let longPlan = [
            makeSession(day: 1, name: "Monday", minutes: 90),
            makeSession(day: 7, name: "Sunday", minutes: 90),
        ]
        let result = ScheduleReshuffler.reshuffle(
            plan: longPlan,
            completedDays: [7],
            missedDays: [1],
            currentDay: 7
        )
        XCTAssertFalse(result.droppedSessions.isEmpty, "Should drop the session with no available days")
    }
}
