import XCTest
@testable import SundeeFundeeKit

final class DeloadDecisionTests: XCTestCase {
    func testDecisionEnforcesMultiplierInvariantsAndCodable() throws {
        let decision = try DeloadDecision(mode: .reduced, volumeMultiplier: 0.7, intensityMultiplier: 0.8, reasonCodes: [.highTrainingLoad], confidence: .high)
        XCTAssertEqual(decision.volumeMultiplier, 0.7)
        XCTAssertEqual(try JSONDecoder().decode(DeloadDecision.self, from: JSONEncoder().encode(decision)), decision)
        XCTAssertNil(try? DeloadDecision(mode: .normal, volumeMultiplier: 1.1, intensityMultiplier: 1, reasonCodes: [], confidence: .low))
    }

    func testDeterministicModes() {
        let assessment = ReadinessAssessment(assessmentDate: .now, state: .ready, totalScore: 90, confidence: .high, subScores: [:], availableSignals: [], missingSignals: [], staleSignals: [], positiveReasons: [], cautionReasons: [], modelVersion: "2.0")
        let normal = DeloadDecisionService.evaluate(assessment: assessment, trainingLoad: .balanced, painSeverity: 0, history: .none)
        XCTAssertEqual(normal.mode, .normal)
        let reduced = DeloadDecisionService.evaluate(assessment: assessment, trainingLoad: .elevated, painSeverity: 2, history: .none)
        XCTAssertEqual(reduced.mode, .reduced)
        let active = DeloadDecisionService.evaluate(assessment: assessment, trainingLoad: .elevated, painSeverity: 8, history: .none)
        XCTAssertEqual(active.mode, .activeRecovery)
    }
}
