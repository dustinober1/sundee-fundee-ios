import XCTest
@testable import SundeeFundeeKit

final class StreakServiceTests: XCTestCase {
    func testCalculatesCurrentAndLongestWeeklyStreak() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let now = Date(timeIntervalSince1970: 1_770_000_000)
        let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
        let workouts = [now, previousWeek].map {
            Workout(date: $0, name: "Workout", exercises: [], completedAt: $0)
        }

        let streak = StreakService.calculate(workouts: workouts, calendar: calendar, now: now)

        XCTAssertEqual(streak.currentWeeklyStreak, 2)
        XCTAssertEqual(streak.longestWeeklyStreak, 2)
        XCTAssertNotNil(streak.lastWorkoutDate)
    }
}
