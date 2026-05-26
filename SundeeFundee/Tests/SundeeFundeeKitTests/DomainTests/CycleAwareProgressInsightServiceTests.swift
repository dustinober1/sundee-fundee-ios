import XCTest
@testable import SundeeFundeeKit

final class CycleAwareProgressInsightServiceTests: XCTestCase {
    func testStrongestPhaseInsightWhenSufficientData() {
        let cycleData = [
            CyclePerformancePoint(phase: .follicular, averageVolume: 1200, workoutCount: 3, confidence: 0.8),
            CyclePerformancePoint(phase: .luteal, averageVolume: 900, workoutCount: 3, confidence: 0.8),
        ]

        let insights = CycleAwareProgressInsightService.build(
            cycleData: cycleData,
            workouts: [Workout(date: Date(), name: "W", exercises: [])],
            maxRecords: []
        )

        XCTAssertTrue(insights.contains { $0.id == "strongest-phase" })
    }

    func testSparseDataReturnsNeedsMoreDataInsight() {
        let cycleData = [
            CyclePerformancePoint(phase: .follicular, averageVolume: 1200, workoutCount: 1, confidence: 0.9),
        ]

        let insights = CycleAwareProgressInsightService.build(
            cycleData: cycleData,
            workouts: [],
            maxRecords: []
        )

        XCTAssertEqual(insights.first?.id, "needs-more-data")
    }

    func testLowConfidencePhasesAreExcluded() {
        let cycleData = [
            CyclePerformancePoint(phase: .follicular, averageVolume: 1200, workoutCount: 4, confidence: 0.2),
            CyclePerformancePoint(phase: .luteal, averageVolume: 900, workoutCount: 4, confidence: 0.7),
        ]

        let insights = CycleAwareProgressInsightService.build(
            cycleData: cycleData,
            workouts: [],
            maxRecords: []
        )

        XCTAssertTrue(insights.contains { $0.value == "Luteal" })
        XCTAssertFalse(insights.contains { $0.value == "Follicular" && $0.id == "strongest-phase" })
    }
}
