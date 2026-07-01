import XCTest
@testable import SundeeFundeeKit

final class BestNextWorkoutRequestBuilderTests: XCTestCase {
    func testLowPainAndDefaultEquipmentBuildsModifyRequest() {
        let request = BestNextWorkoutRequestBuilder.build(
            defaultEquipment: .homeDumbbells,
            latestEnergy: .high,
            painLogs: [],
            todayDecisionKind: .modify
        )

        XCTAssertEqual(request.timeMinutes, 20)
        XCTAssertEqual(request.energyLevel, .high)
        XCTAssertEqual(request.equipment, .homeDumbbells)
        XCTAssertEqual(request.todayDecisionKind, .modify)
    }

    func testHighPainBuildsRecoveryRequest() {
        let log = DailyPainLog(
            id: "pain-1",
            locationIds: "lower_back",
            intensity: 7,
            painType: .soreness,
            date: Date(),
            notes: nil
        )

        let request = BestNextWorkoutRequestBuilder.build(
            defaultEquipment: .fullGym,
            latestEnergy: .medium,
            painLogs: [log],
            todayDecisionKind: .modify
        )

        XCTAssertEqual(request.energyLevel, .low)
        XCTAssertEqual(request.todayDecisionKind, .recover)
        XCTAssertEqual(request.painLogs.count, 1)
    }
}
