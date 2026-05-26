import XCTest
@testable import SundeeFundeeKit

final class QuickWorkoutBuilderTests: XCTestCase {
    func testBuildsWorkoutWithinTwentyMinuteCap() {
        let result = QuickWorkoutBuilder.build(
            request: QuickWorkoutRequest(
                timeMinutes: 20,
                focus: .fullBody,
                energyLevel: .medium,
                equipment: .homeDumbbells,
                todayDecisionKind: .modify,
                recoveryScoreTotal: 55,
                painLogs: []
            )
        )

        XCTAssertLessThanOrEqual(result.estimatedMinutes, 20)
        XCTAssertEqual(result.workout.duration, 20)
        XCTAssertFalse(result.workout.exercises.isEmpty)
    }

    func testLowRecoveryAvoidsMaxEffortBarbellWork() {
        let result = QuickWorkoutBuilder.build(
            request: QuickWorkoutRequest(
                timeMinutes: 20,
                focus: .lowerBody,
                energyLevel: .low,
                equipment: .fullGym,
                todayDecisionKind: .recover,
                recoveryScoreTotal: 32,
                painLogs: []
            )
        )

        let names = result.workout.exercises.map(\.name).joined(separator: " ")
        XCTAssertFalse(names.localizedCaseInsensitiveContains("1RM"))
        XCTAssertFalse(names.localizedCaseInsensitiveContains("Max"))
        XCTAssertTrue(result.reasons.contains(where: { $0.localizedCaseInsensitiveContains("recovery") }))
    }
}
