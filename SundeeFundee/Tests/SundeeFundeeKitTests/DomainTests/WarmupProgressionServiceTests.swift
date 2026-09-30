import XCTest
@testable import SundeeFundeeKit

final class WarmupProgressionServiceTests: XCTestCase {

    func testTargetEqualsBarWeight_ReturnsSingleWorkingSet() {
        let progression = WarmupProgressionService.generateProgression(
            targetWeight: 45.0,
            barWeight: 45.0,
            unit: .lbs,
            targetReps: 5
        )

        XCTAssertEqual(progression.sets.count, 1)
        let firstSet = progression.sets[0]
        XCTAssertEqual(firstSet.weight, 45.0)
        XCTAssertEqual(firstSet.targetReps, 5)
        XCTAssertTrue(firstSet.isWorkingSet)
        XCTAssertEqual(firstSet.plateSummary, "Bar only")
    }

    func testTargetBelowBarWeight_ReturnsSingleWorkingSet() {
        let progression = WarmupProgressionService.generateProgression(
            targetWeight: 35.0,
            barWeight: 45.0,
            unit: .lbs,
            targetReps: 8
        )

        XCTAssertEqual(progression.sets.count, 1)
        let firstSet = progression.sets[0]
        XCTAssertEqual(firstSet.weight, 35.0)
        XCTAssertEqual(firstSet.targetReps, 8)
        XCTAssertTrue(firstSet.isWorkingSet)
    }

    func testStandardImperialProgression_225lbs() {
        let progression = WarmupProgressionService.generateProgression(
            targetWeight: 225.0,
            barWeight: 45.0,
            unit: .lbs,
            targetReps: 5
        )

        // Should have empty bar + 3 warmups + working set = 5 sets
        XCTAssertEqual(progression.sets.count, 5)

        // Set 1: Empty bar
        XCTAssertEqual(progression.sets[0].weight, 45.0)
        XCTAssertEqual(progression.sets[0].targetReps, 10)
        XCTAssertFalse(progression.sets[0].isWorkingSet)
        XCTAssertEqual(progression.sets[0].plateSummary, "Bar only")

        // Set 2: ~50% (112.5 -> 115 lbs)
        XCTAssertEqual(progression.sets[1].weight, 115.0)
        XCTAssertEqual(progression.sets[1].targetReps, 5)
        XCTAssertFalse(progression.sets[1].isWorkingSet)

        // Set 3: ~70% (157.5 -> 160 lbs)
        XCTAssertEqual(progression.sets[2].weight, 160.0)
        XCTAssertEqual(progression.sets[2].targetReps, 3)
        XCTAssertFalse(progression.sets[2].isWorkingSet)

        // Set 4: ~85% (191.25 -> 190 lbs)
        XCTAssertEqual(progression.sets[3].weight, 190.0)
        XCTAssertEqual(progression.sets[3].targetReps, 2)
        XCTAssertFalse(progression.sets[3].isWorkingSet)

        // Set 5: Working set (225 lbs)
        XCTAssertEqual(progression.sets[4].weight, 225.0)
        XCTAssertEqual(progression.sets[4].targetReps, 5)
        XCTAssertTrue(progression.sets[4].isWorkingSet)
        XCTAssertEqual(progression.sets[4].plateSummary, "2×45 lb / side")

        // Strictly ascending
        for i in 0..<(progression.sets.count - 1) {
            XCTAssertLessThan(progression.sets[i].weight, progression.sets[i + 1].weight)
        }
    }

    func testHeavyTargetProgression_HeavyRepsAdaptation() {
        // Target reps <= 3 uses 1 rep on final warmup set
        let progression = WarmupProgressionService.generateProgression(
            targetWeight: 315.0,
            barWeight: 45.0,
            unit: .lbs,
            targetReps: 2
        )

        let finalWarmup = progression.sets[progression.sets.count - 2]
        XCTAssertEqual(finalWarmup.targetReps, 1)

        let workingSet = progression.sets.last!
        XCTAssertEqual(workingSet.weight, 315.0)
        XCTAssertEqual(workingSet.targetReps, 2)
        XCTAssertTrue(workingSet.isWorkingSet)
    }

    func testMetricProgression_100kg() {
        let progression = WarmupProgressionService.generateProgression(
            targetWeight: 100.0,
            barWeight: 20.0,
            unit: .kg,
            targetReps: 5
        )

        XCTAssertGreaterThanOrEqual(progression.sets.count, 4)

        // First set is empty 20kg bar
        XCTAssertEqual(progression.sets[0].weight, 20.0)
        XCTAssertEqual(progression.sets[0].plateSummary, "Bar only")

        // Last set is 100kg
        let workingSet = progression.sets.last!
        XCTAssertEqual(workingSet.weight, 100.0)
        XCTAssertTrue(workingSet.isWorkingSet)
        XCTAssertTrue(workingSet.plateSummary.contains("kg / side"))

        // Strictly ascending
        for i in 0..<(progression.sets.count - 1) {
            XCTAssertLessThan(progression.sets[i].weight, progression.sets[i + 1].weight)
        }
    }

    func testFormatPlateSummary() {
        let empty = WarmupProgressionService.formatPlateSummary([], unit: .lbs)
        XCTAssertEqual(empty, "Bar only")

        let single = WarmupProgressionService.formatPlateSummary(
            [PlateCount(weight: 45.0, countPerSide: 1)],
            unit: .lbs
        )
        XCTAssertEqual(single, "45 lb / side")

        let multiple = WarmupProgressionService.formatPlateSummary(
            [PlateCount(weight: 45.0, countPerSide: 2), PlateCount(weight: 25.0, countPerSide: 1)],
            unit: .lbs
        )
        XCTAssertEqual(multiple, "2×45, 25 lb / side")

        let metricFraction = WarmupProgressionService.formatPlateSummary(
            [PlateCount(weight: 1.25, countPerSide: 1)],
            unit: .kg
        )
        XCTAssertEqual(metricFraction, "1.25 kg / side")
    }
}
