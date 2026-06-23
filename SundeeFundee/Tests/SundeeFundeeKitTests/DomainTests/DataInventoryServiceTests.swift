import XCTest
@testable import SundeeFundeeKit

final class DataInventoryServiceTests: XCTestCase {
    func testInventoryIncludesExpectedCategories() async throws {
        let client = MockCloudKitClient()
        try await seedRecords(client)

        let service = DataInventoryService(dataClient: client)
        let summary = await service.loadInventory()
        let titles = Set(summary.items.map(\.title))

        XCTAssertTrue(titles.contains("Workouts"))
        XCTAssertTrue(titles.contains("Strength Maxes"))
        XCTAssertTrue(titles.contains("Benchmarks"))
        XCTAssertTrue(titles.contains("Cycle Logs"))
        XCTAssertTrue(titles.contains("Pain Logs"))
        XCTAssertTrue(titles.contains("HealthKit Read Access"))
        XCTAssertTrue(titles.contains("Account Profile"))
    }

    func testInventoryUsesFetchedCountsWhereAvailable() async throws {
        let client = MockCloudKitClient()
        try await seedRecords(client)

        let service = DataInventoryService(dataClient: client)
        let summary = await service.loadInventory()

        XCTAssertEqual(summary.items.first(where: { $0.id == "workouts" })?.count, 1)
        XCTAssertEqual(summary.items.first(where: { $0.id == "maxes" })?.count, 1)
        XCTAssertEqual(summary.items.first(where: { $0.id == "benchmarks" })?.count, 1)
        XCTAssertEqual(summary.items.first(where: { $0.id == "cycle" })?.count, 1)
        XCTAssertEqual(summary.items.first(where: { $0.id == "pain" })?.count, 1)
    }

    private func seedRecords(_ client: MockCloudKitClient) async throws {
        try await client.save(
            Workout(id: "w1", date: Date(), name: "W1", exercises: []),
            recordType: "Workout"
        )
        try await client.save(
            OneRepMaxRecord(id: "m1", exerciseName: "Back Squat", weight: 185, unit: .lbs, date: Date()),
            recordType: "OneRepMaxRecord"
        )
        try await client.save(
            BenchmarkResult(
                id: "b1",
                benchmarkId: "fran",
                benchmarkName: "Fran",
                score: 220,
                date: Date()
            ),
            recordType: "BenchmarkResult"
        )
        try await client.save(
            PeriodLogRecord(startDate: Date()),
            recordType: "PeriodLogRecord"
        )
        try await client.save(
            DailyPainLog(id: "p1", locationIds: "knee_left", intensity: 4, painType: .aching, date: Date()),
            recordType: "DailyPainLog"
        )
        try await client.save(
            WeeklyTrainingPlan(
                weekStartDate: Date(),
                targetWorkoutCount: 3,
                preferredWeekdays: [2, 4, 6]
            ),
            recordType: "WeeklyTrainingPlan"
        )
        try await client.save(
            UserSettingsRecord(
                cycleTrackingEnabled: true,
                weightUnit: WeightUnit.lbs.rawValue,
                experienceLevel: ExperienceLevel.beginner.rawValue,
                primaryGoal: PrimaryGoal.strength.rawValue
            ),
            recordType: "UserSettings"
        )
    }
}
