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

    func testCycleAwarePlanningShiftsFirstRecommendedDay() async throws {
        let client = MockCloudKitClient()
        let calendar = Calendar(identifier: .gregorian)
        let service = WeeklyPlanService(dataClient: client, calendar: calendar)
        let now = date(2026, 5, 18) // Monday

        let plan = try await service.createOrUpdateCurrentPlan(
            targetWorkoutCount: 3,
            preferredWeekdays: [2, 4, 6],
            cycleAwarePlanningEnabled: true,
            now: now
        )

        let progress = await service.progress(
            plan: plan,
            workouts: [],
            cyclePhase: .menstrual,
            recoveryScore: 70,
            now: now
        )

        XCTAssertEqual(progress.nextWorkoutWeekday, 4)
    }

    func testTimeAvailabilityPrioritizesLongerWindows() async throws {
        let client = MockCloudKitClient()
        let calendar = Calendar(identifier: .gregorian)
        let service = WeeklyPlanService(dataClient: client, calendar: calendar)
        let now = date(2026, 5, 19) // Tuesday

        let plan = try await service.createOrUpdateCurrentPlan(
            targetWorkoutCount: 3,
            preferredWeekdays: [3, 4, 6],
            timeAvailableMinutesByWeekdayRaw: ["3": 20, "4": 50, "6": 40],
            now: now
        )

        let progress = await service.progress(plan: plan, workouts: [], now: now)
        XCTAssertEqual(progress.nextWorkoutWeekday, 4)
    }

    func testNoRecommendationWhenTargetComplete() async throws {
        let client = MockCloudKitClient()
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let service = WeeklyPlanService(dataClient: client, calendar: calendar)
        let now = date(2026, 5, 18)

        let plan = try await service.createOrUpdateCurrentPlan(
            targetWorkoutCount: 1,
            preferredWeekdays: [2, 4, 6],
            now: now
        )
        let completedWorkout = Workout(
            id: "done",
            date: now,
            name: "Done",
            exercises: [],
            completedAt: now
        )

        let progress = await service.progress(plan: plan, workouts: [completedWorkout], now: now)
        XCTAssertNil(progress.nextWorkoutWeekday)
    }

    func testRecoveryAwarePlanningSkipsEarliestDayWhenVeryLowRecovery() async throws {
        let client = MockCloudKitClient()
        let calendar = Calendar(identifier: .gregorian)
        let service = WeeklyPlanService(dataClient: client, calendar: calendar)
        let now = date(2026, 5, 18) // Monday

        let plan = try await service.createOrUpdateCurrentPlan(
            targetWorkoutCount: 3,
            preferredWeekdays: [2, 4, 6],
            recoveryAwarePlanningEnabled: true,
            now: now
        )

        let progress = await service.progress(
            plan: plan,
            workouts: [],
            cyclePhase: nil,
            recoveryScore: 35,
            now: now
        )

        XCTAssertEqual(progress.nextWorkoutWeekday, 4)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }
}
