import XCTest
@testable import SundeeFundee

final class WeightCalculationsTests: XCTestCase {

    // MARK: - roundToNearestFive

    func testRoundToNearestFive_roundsUp() {
        XCTAssertEqual(WeightCalculations.roundToNearestFive(132), 130)
        XCTAssertEqual(WeightCalculations.roundToNearestFive(133), 135)
    }

    func testRoundToNearestFive_exactMultiple() {
        XCTAssertEqual(WeightCalculations.roundToNearestFive(135), 135)
    }

    func testRoundToNearestFive_midpoint() {
        // 2.5 rounds to nearest even → 130 (banker's rounding) or 135
        let result = WeightCalculations.roundToNearestFive(132.5)
        XCTAssertTrue(result == 130 || result == 135)
    }

    // MARK: - calculateTargetWeight

    func testCalculateTargetWeight() {
        let result = WeightCalculations.calculateTargetWeight(oneRepMax: 200, percentage: 0.65)
        XCTAssertEqual(result, 130)
    }

    func testCalculateTargetWeight_60percent() {
        let result = WeightCalculations.calculateTargetWeight(oneRepMax: 200, percentage: 0.60)
        XCTAssertEqual(result, 120)
    }

    // MARK: - getNextRecommendedWeight

    func testGetNextRecommendedWeight_first() {
        let result = WeightCalculations.getNextRecommendedWeight(
            currentWeight: 0, result: .first, oneRepMax: 200
        )
        XCTAssertEqual(result, 140) // 200 * 0.7 = 140
    }

    func testGetNextRecommendedWeight_success() {
        let result = WeightCalculations.getNextRecommendedWeight(
            currentWeight: 130, result: .success, oneRepMax: 200
        )
        XCTAssertEqual(result, 135) // 130 + 5 = 135
    }

    func testGetNextRecommendedWeight_failure() {
        let result = WeightCalculations.getNextRecommendedWeight(
            currentWeight: 130, result: .failure, oneRepMax: 200
        )
        XCTAssertEqual(result, 125) // 130 - 5 = 125
    }

    func testGetNextRecommendedWeight_failureFloor() {
        let result = WeightCalculations.getNextRecommendedWeight(
            currentWeight: 100, result: .failure, oneRepMax: 200
        )
        XCTAssertEqual(result, 100) // floor is 100 (200 * 0.5)
    }

    // MARK: - wasSetSuccessful

    func testWasSetSuccessful_success() {
        let result = WeightCalculations.wasSetSuccessful(
            actualReps: 5, prescribedReps: 5, actualWeight: 135, prescribedWeight: 135
        )
        XCTAssertTrue(result)
    }

    func testWasSetSuccessful_extraReps() {
        let result = WeightCalculations.wasSetSuccessful(
            actualReps: 7, prescribedReps: 5, actualWeight: 135, prescribedWeight: 135
        )
        XCTAssertTrue(result)
    }

    func testWasSetSuccessful_fewerReps() {
        let result = WeightCalculations.wasSetSuccessful(
            actualReps: 3, prescribedReps: 5, actualWeight: 135, prescribedWeight: 135
        )
        XCTAssertFalse(result)
    }

    func testWasSetSuccessful_lowerWeight() {
        let result = WeightCalculations.wasSetSuccessful(
            actualReps: 5, prescribedReps: 5, actualWeight: 125, prescribedWeight: 135
        )
        XCTAssertFalse(result)
    }

    func testWasSetSuccessful_noPrescribedWeight() {
        let result = WeightCalculations.wasSetSuccessful(
            actualReps: 5, prescribedReps: 5, actualWeight: 100, prescribedWeight: nil
        )
        XCTAssertTrue(result)
    }

    // MARK: - wasSessionSuccessful

    func testWasSessionSuccessful_allPass() {
        let sets: [(actualReps: Int, prescribedReps: Int, actualWeight: Double, prescribedWeight: Double?)] = [
            (5, 5, 135, 135),
            (5, 5, 135, 135),
            (5, 5, 135, 135),
        ]
        XCTAssertTrue(WeightCalculations.wasSessionSuccessful(sets: sets))
    }

    func testWasSessionSuccessful_oneFails() {
        let sets: [(actualReps: Int, prescribedReps: Int, actualWeight: Double, prescribedWeight: Double?)] = [
            (5, 5, 135, 135),
            (3, 5, 135, 135),
            (5, 5, 135, 135),
        ]
        XCTAssertFalse(WeightCalculations.wasSessionSuccessful(sets: sets))
    }

    func testWasSessionSuccessful_emptyIsVacuouslyTrue() {
        XCTAssertTrue(WeightCalculations.wasSessionSuccessful(sets: []))
    }

    // MARK: - isPersonalRecord

    func testIsPersonalRecord_true() {
        XCTAssertTrue(WeightCalculations.isPersonalRecord(weight: 140, previousMax: 135))
    }

    func testIsPersonalRecord_equal() {
        XCTAssertFalse(WeightCalculations.isPersonalRecord(weight: 135, previousMax: 135))
    }

    func testIsPersonalRecord_lower() {
        XCTAssertFalse(WeightCalculations.isPersonalRecord(weight: 130, previousMax: 135))
    }

    // MARK: - calculateVolumeLoad

    func testCalculateVolumeLoad() {
        let result = WeightCalculations.calculateVolumeLoad(weight: 135, reps: 5, sets: 3)
        XCTAssertEqual(result, 2025)
    }

    // MARK: - detectPlateau

    func testDetectPlateau_true() {
        XCTAssertTrue(WeightCalculations.detectPlateau(weights: [135, 135, 135]))
    }

    func testDetectPlateau_smallVariance() {
        XCTAssertTrue(WeightCalculations.detectPlateau(weights: [133, 135, 134]))
    }

    func testDetectPlateau_false() {
        XCTAssertFalse(WeightCalculations.detectPlateau(weights: [130, 135, 140]))
    }

    func testDetectPlateau_tooFewWeights() {
        XCTAssertFalse(WeightCalculations.detectPlateau(weights: [135, 135]))
    }

    func testDetectPlateau_usesLastThree() {
        XCTAssertTrue(WeightCalculations.detectPlateau(weights: [100, 120, 135, 135, 135]))
    }
}
