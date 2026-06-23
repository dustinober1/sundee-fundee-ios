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
                painLogs: []
            )
        )

        XCTAssertLessThanOrEqual(result.estimatedMinutes, 20)
        XCTAssertEqual(result.workout.duration, 20)
        XCTAssertFalse(result.workout.exercises.isEmpty)
    }

    func testRecoverDecisionAvoidsMaxEffortBarbellWork() {
        let result = QuickWorkoutBuilder.build(
            request: QuickWorkoutRequest(
                timeMinutes: 20,
                focus: .lowerBody,
                energyLevel: .low,
                equipment: .fullGym,
                todayDecisionKind: .recover,
                painLogs: []
            )
        )

        let names = result.workout.exercises.map(\.name).joined(separator: " ")
        XCTAssertFalse(names.localizedCaseInsensitiveContains("1RM"))
        XCTAssertFalse(names.localizedCaseInsensitiveContains("Max"))
        XCTAssertTrue(result.reasons.contains(where: { $0.localizedCaseInsensitiveContains("today context") }))
    }

    func testKneePainAvoidsBodyweightSquatAndLungePatterns() {
        let result = QuickWorkoutBuilder.build(
            request: QuickWorkoutRequest(
                timeMinutes: 20,
                focus: .lowerBody,
                energyLevel: .medium,
                equipment: .bodyweightOnly,
                todayDecisionKind: .modify,
                painLogs: [
                    DailyPainLog(
                        id: "knee-pain",
                        locationIds: "knee_left",
                        intensity: 7,
                        painType: .acute,
                        date: Date()
                    )
                ]
            )
        )

        let names = result.workout.exercises.map(\.name).joined(separator: " ")
        XCTAssertFalse(names.localizedCaseInsensitiveContains("Squat"))
        XCTAssertFalse(names.localizedCaseInsensitiveContains("Lunge"))
        XCTAssertTrue(result.reasons.contains(where: { $0.localizedCaseInsensitiveContains("pain") }))
    }

    func testUnsupportedPainRegionDoesNotClaimPainAvoidance() {
        let result = QuickWorkoutBuilder.build(
            request: QuickWorkoutRequest(
                timeMinutes: 20,
                focus: .fullBody,
                energyLevel: .medium,
                equipment: .homeDumbbells,
                todayDecisionKind: .modify,
                painLogs: [
                    DailyPainLog(
                        id: "head-pain",
                        locationIds: "head",
                        intensity: 7,
                        painType: .acute,
                        date: Date()
                    )
                ]
            )
        )

        XCTAssertFalse(result.reasons.contains(where: { $0.localizedCaseInsensitiveContains("pain") }))
    }

    func testVeryShortRequestTrimsToSingleExerciseWhenItFits() {
        let result = QuickWorkoutBuilder.build(
            request: QuickWorkoutRequest(
                timeMinutes: 3,
                focus: .core,
                energyLevel: .low,
                equipment: .bodyweightOnly,
                todayDecisionKind: .modify,
                painLogs: []
            )
        )

        XCTAssertEqual(result.workout.exercises.count, 1)
        XCTAssertLessThanOrEqual(result.estimatedMinutes, 3)
        XCTAssertFalse(result.reasons.contains(where: { $0.localizedCaseInsensitiveContains("exceeds") }))
    }

    func testTinyRequestReportsActualMinimumEstimateWhenItCannotFit() {
        let result = QuickWorkoutBuilder.build(
            request: QuickWorkoutRequest(
                timeMinutes: 1,
                focus: .core,
                energyLevel: .low,
                equipment: .bodyweightOnly,
                todayDecisionKind: .modify,
                painLogs: []
            )
        )

        XCTAssertEqual(result.workout.exercises.count, 1)
        XCTAssertGreaterThan(result.estimatedMinutes, 1)
        XCTAssertTrue(result.reasons.contains(where: { $0.localizedCaseInsensitiveContains("exceeds") }))
        XCTAssertFalse(result.reasons.contains(where: { $0.localizedCaseInsensitiveContains("built to fit") }))
    }
}
