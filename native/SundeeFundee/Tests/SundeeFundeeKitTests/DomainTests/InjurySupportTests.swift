import XCTest
@testable import SundeeFundeeKit

final class InjurySupportTests: XCTestCase {

    // MARK: - Load Multipliers

    func testLoadMultipliers_Acute_AllZeros() {
        let m = loadMultipliers[.acute]!
        XCTAssertEqual(m.load, 0, accuracy: 0.01)
        XCTAssertEqual(m.sets, 0, accuracy: 0.01)
        XCTAssertEqual(m.reps, 0, accuracy: 0.01)
    }

    func testLoadMultipliers_Rehab() {
        let m = loadMultipliers[.rehab]!
        XCTAssertEqual(m.load, 0.30, accuracy: 0.01)
        XCTAssertEqual(m.sets, 0.50, accuracy: 0.01)
        XCTAssertEqual(m.reps, 0.70, accuracy: 0.01)
    }

    func testLoadMultipliers_LightLoad() {
        let m = loadMultipliers[.lightLoad]!
        XCTAssertEqual(m.load, 0.50, accuracy: 0.01)
        XCTAssertEqual(m.sets, 0.75, accuracy: 0.01)
        XCTAssertEqual(m.reps, 0.85, accuracy: 0.01)
    }

    func testLoadMultipliers_ReturnToPlay() {
        let m = loadMultipliers[.returnToPlay]!
        XCTAssertEqual(m.load, 0.80, accuracy: 0.01)
        XCTAssertEqual(m.sets, 0.90, accuracy: 0.01)
        XCTAssertEqual(m.reps, 1.0, accuracy: 0.01)
    }

    func testLoadMultipliers_Resolved_AllOnes() {
        let m = loadMultipliers[.resolved]!
        XCTAssertEqual(m.load, 1.0, accuracy: 0.01)
        XCTAssertEqual(m.sets, 1.0, accuracy: 0.01)
        XCTAssertEqual(m.reps, 1.0, accuracy: 0.01)
    }

    // MARK: - adjustExerciseValueByMultiplier

    func testAdjustFixed_ScalesValue() {
        let result = adjustExerciseValueByMultiplier(.fixed(value: 10), multiplier: 0.5)
        XCTAssertEqual(result, .fixed(value: 5))
    }

    func testAdjustFixed_MinimumOfOne() {
        let result = adjustExerciseValueByMultiplier(.fixed(value: 1), multiplier: 0.0)
        if case .fixed(let v) = result {
            XCTAssertGreaterThanOrEqual(v, 1)
        } else {
            XCTFail("Expected fixed value")
        }
    }

    func testAdjustRange_ScalesValues() {
        let result = adjustExerciseValueByMultiplier(.range(low: 8, high: 12), multiplier: 0.5)
        XCTAssertEqual(result, .range(low: 4, high: 6))
    }

    func testAdjustAmrap_Unchanged() {
        let result = adjustExerciseValueByMultiplier(.amrap, multiplier: 0.5)
        XCTAssertEqual(result, .amrap)
    }

    func testAdjustText_Unchanged() {
        let result = adjustExerciseValueByMultiplier(.text(value: "hold"), multiplier: 0.5)
        XCTAssertEqual(result, .text(value: "hold"))
    }

    // MARK: - adjustLoad

    func testAdjustLoad_ScalesPercent() {
        let result = adjustLoad(0.8, multiplier: 0.5)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 0.4, accuracy: 0.01)
    }

    func testAdjustLoad_NilReturnsNil() {
        XCTAssertNil(adjustLoad(nil, multiplier: 0.5))
    }

    // MARK: - analyzePainTrend

    func testAnalyzePainTrend_EmptyLogs() {
        let result = analyzePainTrend(logs: [])
        XCTAssertEqual(result.trailingAverage, 0, accuracy: 0.01)
        XCTAssertFalse(result.isImproving)
        XCTAssertNil(result.latestPainLevel)
        XCTAssertEqual(result.readingCount, 0)
    }

    func testAnalyzePainTrend_ImprovingTrend() {
        let now = Date()
        let logs = [
            PainLog(injuryId: "i1", painLevel: 8, recordedAt: now.addingTimeInterval(-4 * 86400)),
            PainLog(injuryId: "i1", painLevel: 7, recordedAt: now.addingTimeInterval(-3 * 86400)),
            PainLog(injuryId: "i1", painLevel: 5, recordedAt: now.addingTimeInterval(-2 * 86400)),
            PainLog(injuryId: "i1", painLevel: 3, recordedAt: now.addingTimeInterval(-1 * 86400)),
        ]
        let result = analyzePainTrend(logs: logs)
        XCTAssertTrue(result.isImproving)
        XCTAssertEqual(result.latestPainLevel, 3)
        XCTAssertEqual(result.readingCount, 4)
    }

    func testAnalyzePainTrend_NotImproving() {
        let now = Date()
        let logs = [
            PainLog(injuryId: "i1", painLevel: 3, recordedAt: now.addingTimeInterval(-2 * 86400)),
            PainLog(injuryId: "i1", painLevel: 5, recordedAt: now.addingTimeInterval(-1 * 86400)),
            PainLog(injuryId: "i1", painLevel: 7, recordedAt: now),
        ]
        let result = analyzePainTrend(logs: logs)
        XCTAssertFalse(result.isImproving)
    }

    // MARK: - hasRecentLog

    func testHasRecentLog_WithinWindow() {
        let now = Date()
        let logs = [PainLog(injuryId: "i1", painLevel: 5, recordedAt: now.addingTimeInterval(-3600))]
        XCTAssertTrue(hasRecentLog(logs: logs, referenceDate: now))
    }

    func testHasRecentLog_OutsideWindow() {
        let now = Date()
        let logs = [PainLog(injuryId: "i1", painLevel: 5, recordedAt: now.addingTimeInterval(-25 * 3600))]
        XCTAssertFalse(hasRecentLog(logs: logs, referenceDate: now))
    }

    func testHasRecentLog_EmptyLogs() {
        XCTAssertFalse(hasRecentLog(logs: []))
    }

    // MARK: - sparklineData

    func testSparklineData_ReturnsChronological() {
        let now = Date()
        let logs = [
            PainLog(injuryId: "i1", painLevel: 8, recordedAt: now.addingTimeInterval(-3 * 86400)),
            PainLog(injuryId: "i1", painLevel: 5, recordedAt: now.addingTimeInterval(-2 * 86400)),
            PainLog(injuryId: "i1", painLevel: 3, recordedAt: now.addingTimeInterval(-1 * 86400)),
        ]
        let data = sparklineData(logs: logs)
        XCTAssertEqual(data, [8, 5, 3])
    }

    // MARK: - evaluateTransition

    func testEvaluateTransition_AcuteToRehab() {
        let now = Date()
        let logs = (0..<3).map { i in
            PainLog(injuryId: "i1", painLevel: 4, recordedAt: now.addingTimeInterval(-Double(i) * 86400))
        }
        let result = evaluateTransition(injuryId: "i1", currentPhase: .acute, painLogs: logs)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.suggestedPhase, .rehab)
    }

    func testEvaluateTransition_TooHighPain_NoTransition() {
        let now = Date()
        let logs = (0..<3).map { i in
            PainLog(injuryId: "i1", painLevel: 7, recordedAt: now.addingTimeInterval(-Double(i) * 86400))
        }
        let result = evaluateTransition(injuryId: "i1", currentPhase: .acute, painLogs: logs)
        XCTAssertNil(result)
    }

    func testEvaluateTransition_Resolved_NoFurtherTransition() {
        let now = Date()
        let logs = (0..<5).map { i in
            PainLog(injuryId: "i1", painLevel: 0, recordedAt: now.addingTimeInterval(-Double(i) * 86400))
        }
        let result = evaluateTransition(injuryId: "i1", currentPhase: .resolved, painLogs: logs)
        XCTAssertNil(result)
    }
}
