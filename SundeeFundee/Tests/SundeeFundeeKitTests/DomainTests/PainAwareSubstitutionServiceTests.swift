import XCTest
@testable import SundeeFundeeKit

final class PainAwareSubstitutionServiceTests: XCTestCase {
    func testPainAwareSubstitutionsIncludePainReason() {
        let log = DailyPainLog(
            id: "pain",
            locationIds: "knee_left",
            intensity: 6,
            painType: .aching,
            date: Date()
        )

        let substitutions = PainAwareSubstitutionService.rank(
            currentExercise: "Back Squat",
            recentPainLogs: [log],
            injuries: [],
            equipment: .fullGym
        )

        XCTAssertFalse(substitutions.isEmpty)
        XCTAssertTrue(substitutions.first?.reason.lowercased().contains("knee") == true)
    }

    func testNoPainLogsPreserveGenericRankingReason() {
        let substitutions = PainAwareSubstitutionService.rank(
            currentExercise: "Back Squat",
            recentPainLogs: [],
            injuries: [],
            equipment: .fullGym
        )

        XCTAssertFalse(substitutions.isEmpty)
        XCTAssertFalse(substitutions.first?.reason.lowercased().contains("logged recently") == true)
    }
}
