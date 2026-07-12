import XCTest
@testable import SundeeFundeeKit

final class ReadinessBaselineNormalizerTests: XCTestCase {
    func testPersonalBaselineRequiresFourteenObservations() {
        let metric = ReadinessMetricSnapshot(currentValue: 50, baselineValues: Array(repeating: 50, count: 13), observedAt: Date())
        XCTAssertNil(ReadinessBaselineNormalizer.personalScore(metric, direction: .higherIsBetter))
    }

    func testBaselineMapsToSeventyFiveAndDirectionChangesDelta() {
        let history = Array(repeating: 50.0, count: 14)
        let atBaseline = ReadinessMetricSnapshot(currentValue: 50, baselineValues: history, observedAt: Date())
        let above = ReadinessMetricSnapshot(currentValue: 55, baselineValues: history, observedAt: Date())

        XCTAssertEqual(ReadinessBaselineNormalizer.personalScore(atBaseline, direction: .higherIsBetter), 75)
        XCTAssertGreaterThan(
            ReadinessBaselineNormalizer.personalScore(above, direction: .higherIsBetter)!,
            ReadinessBaselineNormalizer.personalScore(above, direction: .lowerIsBetter)!
        )
    }

    func testSleepHasAnAbsoluteFallbackWhileLearning() {
        XCTAssertEqual(ReadinessBaselineNormalizer.sleepScore(hours: 8.0, history: []), 90)
        XCTAssertEqual(ReadinessBaselineNormalizer.sleepScore(hours: 5.0, history: []), 40)
    }
}
