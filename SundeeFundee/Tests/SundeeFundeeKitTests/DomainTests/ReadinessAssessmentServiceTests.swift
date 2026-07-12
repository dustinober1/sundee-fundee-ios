import XCTest
@testable import SundeeFundeeKit

final class ReadinessAssessmentServiceTests: XCTestCase {
    func testAllMissingInputsReturnNil() { XCTAssertNil(ReadinessAssessmentService.assess(makeContext())) }
    func testCyclePhaseDoesNotChangeScore() throws {
        let base = makeContext(subjective: SubjectiveReadinessSnapshot(energy: 8, fatigue: 2, soreness: 2))
        let follicular = makeContext(subjective: base.subjective, cyclePhase: .follicular)
        let luteal = makeContext(subjective: base.subjective, cyclePhase: .luteal)
        XCTAssertEqual(try XCTUnwrap(ReadinessAssessmentService.assess(follicular)).totalScore, try XCTUnwrap(ReadinessAssessmentService.assess(luteal)).totalScore)
    }
    func testHighPainCapsReadyScoreAtRecover() throws {
        let context = makeContext(subjective: SubjectiveReadinessSnapshot(energy: 10, fatigue: 0, soreness: 0, stress: 0, perceivedReadiness: 10), pain: PainReadinessSnapshot(intensity: 8, painType: .sharp, locationIDs: ["knee"], observedAt: Date()))
        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertEqual(result.state, .recover); XCTAssertTrue(result.cautionReasons.contains(.highPain))
    }
    private func makeContext(subjective: SubjectiveReadinessSnapshot = .empty, pain: PainReadinessSnapshot? = nil, cyclePhase: CyclePhase? = nil) -> DailyTrainingContext {
        DailyTrainingContext(assessmentDate: Date(timeIntervalSince1970: 1_700_000_000), timeZoneIdentifier: "America/New_York", physiological: .empty, subjective: subjective, training: .empty, pain: pain, cyclePhase: cyclePhase, cycleConfidence: cyclePhase == nil ? nil : 0.8)
    }
}
