import XCTest
@testable import SundeeFundeeKit

final class AutoregulationServiceTests: XCTestCase {

    // MARK: - Reduce Weight Tests

    func testEvaluate_RPE10_ReducesWeight() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 5,
            targetReps: 5,
            completedWeight: 100.0,
            rpe: 10,
            unit: .lbs
        )

        XCTAssertEqual(adjustment.action, .reduceWeight)
        XCTAssertEqual(adjustment.adjustedWeight, 90.0)
        XCTAssertTrue(adjustment.reason.contains("High fatigue detected (RPE 10)"))
    }

    func testEvaluate_MissedReps_ReducesWeight() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 3,
            targetReps: 5,
            completedWeight: 100.0,
            rpe: 8,
            unit: .lbs
        )

        XCTAssertEqual(adjustment.action, .reduceWeight)
        XCTAssertEqual(adjustment.adjustedWeight, 90.0)
    }

    // MARK: - Increase Weight Tests

    func testEvaluate_RPE6AndCompletedReps_IncreasesWeight() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 5,
            targetReps: 5,
            completedWeight: 100.0,
            rpe: 6,
            unit: .lbs
        )

        XCTAssertEqual(adjustment.action, .increaseWeight)
        XCTAssertEqual(adjustment.adjustedWeight, 105.0)
        XCTAssertTrue(adjustment.reason.contains("Set moved easily (RPE 6)"))
    }

    func testEvaluate_RPEBelow6_IncreasesWeight() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 8,
            targetReps: 8,
            completedWeight: 150.0,
            rpe: 5,
            unit: .lbs
        )

        XCTAssertEqual(adjustment.action, .increaseWeight)
        XCTAssertEqual(adjustment.adjustedWeight, 155.0)
    }

    func testEvaluate_RPE6_MissedRepsDoesNotIncrease() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 4,
            targetReps: 5,
            completedWeight: 100.0,
            rpe: 6,
            unit: .lbs
        )

        // 4 reps out of 5 is not < targetReps - 1, but completedReps < targetReps so it shouldn't increase
        XCTAssertEqual(adjustment.action, .maintain)
        XCTAssertEqual(adjustment.adjustedWeight, 100.0)
    }

    // MARK: - Maintain Tests

    func testEvaluate_RPE7_MaintainsWeight() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 5,
            targetReps: 5,
            completedWeight: 100.0,
            rpe: 7,
            unit: .lbs
        )

        XCTAssertEqual(adjustment.action, .maintain)
        XCTAssertEqual(adjustment.adjustedWeight, 100.0)
        XCTAssertTrue(adjustment.reason.contains("Target intensity achieved (RPE 7)"))
    }

    func testEvaluate_RPE8_MaintainsWeight() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 5,
            targetReps: 5,
            completedWeight: 100.0,
            rpe: 8,
            unit: .lbs
        )

        XCTAssertEqual(adjustment.action, .maintain)
        XCTAssertEqual(adjustment.adjustedWeight, 100.0)
    }

    func testEvaluate_NilRPE_DefaultsTo8AndMaintains() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 5,
            targetReps: 5,
            completedWeight: 100.0,
            rpe: nil,
            unit: .lbs
        )

        XCTAssertEqual(adjustment.action, .maintain)
        XCTAssertEqual(adjustment.adjustedWeight, 100.0)
        XCTAssertTrue(adjustment.reason.contains("RPE 8"))
    }

    // MARK: - Metric Unit Increments

    func testEvaluate_MetricKg_IncreasesBy2Point5() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 5,
            targetReps: 5,
            completedWeight: 60.0,
            rpe: 6,
            unit: .kg
        )

        XCTAssertEqual(adjustment.action, .increaseWeight)
        XCTAssertEqual(adjustment.adjustedWeight, 62.5)
        XCTAssertTrue(adjustment.reason.contains("kg"))
    }

    func testEvaluate_MetricKg_ReducesWithKgRounding() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 5,
            targetReps: 5,
            completedWeight: 60.0,
            rpe: 10,
            unit: .kg
        )

        XCTAssertEqual(adjustment.action, .reduceWeight)
        // 60 * 0.9 = 54.0; round to nearest 2.5 is 55.0
        XCTAssertEqual(adjustment.adjustedWeight, 55.0)
        XCTAssertTrue(adjustment.reason.contains("kg"))
    }

    // MARK: - Bodyweight Movement

    func testEvaluate_Bodyweight_MaintainsWithoutAdjustment() {
        let adjustment = AutoregulationService.evaluate(
            completedReps: 10,
            targetReps: 10,
            completedWeight: 0.0,
            rpe: 10,
            unit: .lbs
        )

        XCTAssertEqual(adjustment.action, .maintain)
        XCTAssertNil(adjustment.adjustedWeight)
        XCTAssertEqual(adjustment.reason, "Bodyweight movement maintained.")
    }
}
