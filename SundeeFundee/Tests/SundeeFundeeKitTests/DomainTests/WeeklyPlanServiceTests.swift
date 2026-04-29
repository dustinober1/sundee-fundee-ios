import XCTest
@testable import SundeeFundeeKit

final class WeeklyPlanServiceTests: XCTestCase {
    func testProgressCountsCompletedWorkoutsInCurrentWeek() async throws {
        let client = MockCloudKitClient()
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let service = WeeklyPlanService(dataClient: client, calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_770_000_000)
        let plan = try await service.createOrUpdateCurrentPlan(
            targetWorkoutCount: 3,
            preferredWeekdays: [2, 4, 6],
            now: now
        )
        let workout = Workout(
            id: "w1",
            date: now,
            name: "Done",
            exercises: [],
            completedAt: now
        )

        let progress = await service.progress(plan: plan, workouts: [workout], now: now)

        XCTAssertEqual(progress.completed, 1)
        XCTAssertEqual(progress.target, 3)
        XCTAssertNotNil(progress.nextWorkoutWeekday)
    }
}
