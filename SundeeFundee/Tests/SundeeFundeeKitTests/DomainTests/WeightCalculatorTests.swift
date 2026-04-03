import XCTest
@testable import SundeeFundeeKit

final class WeightCalculatorTests: XCTestCase {
    func testDefaultPercentage_MapsCorrectly() {
        XCTAssertEqual(defaultPercentage(reps: 1), 1.0, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 2), 0.93, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 3), 0.85, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 5), 0.80, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 8), 0.70, accuracy: 0.01)
        XCTAssertEqual(defaultPercentage(reps: 12), 0.60, accuracy: 0.01)
    }

    func testDefaultPercentage_HigherRepsReturnsLower() {
        let fiveReps = defaultPercentage(reps: 5)
        let tenReps = defaultPercentage(reps: 10)
        XCTAssertGreaterThan(fiveReps, tenReps, "Higher reps should give lower percentage")
    }

    func testCalculatePrescribedWeight_WithMultipliers() {
        // 300lb max, 5 reps (80%), medium energy (1.0), normal cycle (1.0)
        // Expected: 300 * 0.80 * 1.0 * 1.0 = 240 lbs
        let result = calculatePrescribedWeight(
            max: 300,
            reps: 5,
            energyMultiplier: 1.0,
            cycleMultiplier: 1.0
        )
        XCTAssertEqual(result, 240, accuracy: 0.1)
    }

    func testCalculatePrescribedWeight_LowEnergy() {
        // 300lb max, 5 reps (80%), low energy (0.85)
        // Expected: 300 * 0.80 * 0.85 = 204, rounded to 205
        let result = calculatePrescribedWeight(
            max: 300,
            reps: 5,
            energyMultiplier: 0.85,
            cycleMultiplier: 1.0
        )
        XCTAssertEqual(result, 205, accuracy: 0.1)
    }

    func testRoundToNearest() {
        XCTAssertEqual(roundToNearest(183, increment: 5), 185)
        XCTAssertEqual(roundToNearest(182, increment: 5), 180)
        XCTAssertEqual(roundToNearest(185, increment: 5), 185)
    }
}
