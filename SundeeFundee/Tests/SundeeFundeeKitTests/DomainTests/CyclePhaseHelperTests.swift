import XCTest
@testable import SundeeFundeeKit

final class CyclePhaseHelperTests: XCTestCase {

    // MARK: - convertToPeriodLogs

    func testConvertToPeriodLogs_EmptySamples() {
        let logs = CyclePhaseHelper.convertToPeriodLogs([])
        XCTAssertTrue(logs.isEmpty)
    }

    // MARK: - calculateConfidence

    func testConfidence_NoPeriodLogs() {
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 0,
            lastPeriodStart: nil
        )
        XCTAssertEqual(confidence, 0.0)
    }

    func testConfidence_OnePeriodLog_Recent() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 1,
            lastPeriodStart: lastStart
        )
        // 1 log = 0.4 base, recent = 1.0 multiplier
        XCTAssertEqual(confidence, 0.4, accuracy: 0.01)
    }

    func testConfidence_ThreePeriodLogs_Recent() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 3,
            lastPeriodStart: lastStart
        )
        // 3 logs = 0.8 base, recent = 1.0 multiplier
        XCTAssertEqual(confidence, 0.8, accuracy: 0.01)
    }

    func testConfidence_ManyPeriodLogs_Recent() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 6,
            lastPeriodStart: lastStart
        )
        // 6+ logs = 0.9 base, recent = 1.0 multiplier
        XCTAssertEqual(confidence, 0.9, accuracy: 0.01)
    }

    func testConfidence_StaleData() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 3,
            lastPeriodStart: lastStart
        )
        // 3 logs = 0.8 base, >60 days = 0.5 multiplier
        XCTAssertEqual(confidence, 0.4, accuracy: 0.01)
    }

    func testConfidence_ModeratelyStale() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -45, to: Date())!
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 3,
            lastPeriodStart: lastStart
        )
        // 3 logs = 0.8 base, 35-60 days = 0.8 multiplier
        XCTAssertEqual(confidence, 0.64, accuracy: 0.01)
    }
}
