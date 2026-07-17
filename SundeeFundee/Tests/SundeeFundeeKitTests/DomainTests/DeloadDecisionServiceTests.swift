import XCTest
@testable import SundeeFundeeKit

final class DeloadDecisionServiceTests: XCTestCase {
    private func assessment(_ state: ReadinessState, confidence: ReadinessConfidence = .high, score: Int? = nil, missing: [ReadinessSignalID] = []) -> ReadinessAssessment {
        ReadinessAssessment(assessmentDate: Date(timeIntervalSince1970: 1_700_000_000), state: state, totalScore: score ?? (state == .ready ? 90 : 50), confidence: confidence, subScores: [:], availableSignals: [], missingSignals: missing, staleSignals: [], positiveReasons: [], cautionReasons: [], modelVersion: "2.0")
    }

    func testStableReadinessAndBalancedLoadMaintainsNormalDose() {
        let result = DeloadDecisionService.evaluate(readiness: assessment(.ready), trainingLoad: .balanced, pain: 0, history: .none)
        XCTAssertEqual(result.mode, .normal)
        XCTAssertEqual(result.volumeMultiplier, 1)
        XCTAssertEqual(result.intensityMultiplier, 1)
        XCTAssertTrue(result.reasonCodes.isEmpty)
    }

    func testRepeatedHighLoadProducesReducedDoseAndReason() {
        let result = DeloadDecisionService.evaluate(readiness: assessment(.maintain), trainingLoad: .excessive, pain: 0, history: .recent)
        XCTAssertEqual(result.mode, .reduced)
        XCTAssertEqual(result.volumeMultiplier, 0.7)
        XCTAssertTrue(result.reasonCodes.contains(.highTrainingLoad))
        XCTAssertTrue(result.reasonCodes.contains(.recentDeload))
    }

    func testLowReadinessProducesReducedDose() {
        let result = DeloadDecisionService.evaluate(readiness: assessment(.recover), trainingLoad: .balanced, pain: 0, history: .none)
        XCTAssertEqual(result.mode, .reduced)
        XCTAssertTrue(result.reasonCodes.contains(.lowReadiness))
    }

    func testHighPainAlwaysUsesActiveRecoveryAndBoundedMultipliers() {
        let result = DeloadDecisionService.evaluate(readiness: assessment(.ready), trainingLoad: .balanced, pain: 7, history: .none)
        XCTAssertEqual(result.mode, .activeRecovery)
        XCTAssertLessThanOrEqual(result.volumeMultiplier, 0.5)
        XCTAssertLessThanOrEqual(result.intensityMultiplier, 0.6)
        XCTAssertTrue(result.reasonCodes.contains(.highPain))
    }

    func testIncompleteLowConfidenceHistoryNeverIncreasesDose() {
        let result = DeloadDecisionService.evaluate(readiness: assessment(.ready, confidence: .low, missing: [.sleep, .trainingLoad]), trainingLoad: .balanced, pain: 0, history: .none)
        XCTAssertEqual(result.mode, .reduced)
        XCTAssertLessThan(result.volumeMultiplier, 1)
        XCTAssertLessThan(result.intensityMultiplier, 1)
    }

    func testThresholdsAreDeterministicAndPainIsClamped() {
        let first = DeloadDecisionService.evaluate(readiness: assessment(.ready), trainingLoad: .balanced, pain: -10, history: .none)
        let second = DeloadDecisionService.evaluate(readiness: assessment(.ready), trainingLoad: .balanced, pain: -10, history: .none)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.mode, .normal)
        let severe = DeloadDecisionService.evaluate(readiness: assessment(.maintain), trainingLoad: .balanced, pain: 100, history: .none)
        XCTAssertEqual(severe.mode, .activeRecovery)
    }
}
