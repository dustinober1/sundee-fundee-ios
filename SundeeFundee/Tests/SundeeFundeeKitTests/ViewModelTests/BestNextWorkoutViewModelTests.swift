import XCTest
@testable import SundeeFundeeKit

@MainActor
final class BestNextWorkoutViewModelTests: XCTestCase {
    func testBuildWorkoutUsesSettingsEnergyAndPainContext() async throws {
        let client = MockCloudKitClient()
        try await client.save(
            UserSettingsRecord(
                cycleTrackingEnabled: true,
                weightUnit: "lb",
                experienceLevel: "intermediate",
                primaryGoal: "strength",
                defaultEquipment: .homeDumbbells
            ),
            recordType: "UserSettings"
        )
        try await client.save(
            SymptomCheckInRecord(
                symptomDate: Date(),
                cramps: 0,
                fatigue: 2,
                soreness: 3,
                energy: 9
            ),
            recordType: "SymptomCheckInRecord"
        )
        try await client.save(
            DailyPainLog(
                id: "pain-1",
                locationIds: "lower_back",
                intensity: 7,
                painType: .soreness,
                date: Date()
            ),
            recordType: "DailyPainLog"
        )
        let viewModel = BestNextWorkoutViewModel(dataClient: client)

        let result = await viewModel.buildWorkout()

        XCTAssertNotNil(result)
        XCTAssertFalse(viewModel.isBuilding)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(result?.workout.name, "Best Next 20 Minutes")
        XCTAssertTrue(result?.workout.notes?.contains("Uses dumbbells movements.") == true)
        XCTAssertTrue(result?.workout.notes?.contains("Today context kept the work submaximal.") == true)
        XCTAssertTrue(result?.workout.notes?.contains("Pain log context avoided") == true)

        let events: [GrowthEvent] = try await client.fetchAll(recordType: "GrowthEvent")
        XCTAssertEqual(events.map(\.name), ["best_next_20_generated"])
    }
}
