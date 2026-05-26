import XCTest
@testable import SundeeFundeeKit

final class ProgramAdaptationSummaryTests: XCTestCase {
    func testSummaryChangeHasStableIdentifier() {
        let change = ProgramAdaptationChange(
            reasonCode: .equipmentConversion,
            exerciseName: "Dumbbell Bench Press",
            detail: "Converted for dumbbell access."
        )

        XCTAssertTrue(change.id.contains("equipmentConversion"))
        XCTAssertTrue(change.id.contains("Dumbbell Bench Press"))
    }

    func testSummaryStoresHeadlineAndChanges() {
        let summary = ProgramAdaptationSummary(
            headline: "Session adapted to readiness.",
            changes: [
                ProgramAdaptationChange(
                    reasonCode: .recoveryAdjustment,
                    exerciseName: "Back Squat",
                    detail: "Reduced loading."
                )
            ]
        )

        XCTAssertEqual(summary.headline, "Session adapted to readiness.")
        XCTAssertEqual(summary.changes.count, 1)
    }
}
