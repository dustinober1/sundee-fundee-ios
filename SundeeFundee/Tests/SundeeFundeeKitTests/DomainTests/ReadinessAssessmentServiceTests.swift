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

    func testWeightedGroupsRenormalizeWhenGroupsAreMissing() throws {
        let context = makeContext(
            physiological: PhysiologicalReadinessSnapshot(
                sleepHours: ReadinessMetricSnapshot(currentValue: 8, baselineValues: [], observedAt: assessmentDate)
            ),
            subjective: SubjectiveReadinessSnapshot(energy: 10)
        )
        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertEqual(result.subScores[.physiological], 90)
        XCTAssertEqual(result.subScores[.subjective], 100)
        XCTAssertEqual(result.totalScore, 95)
    }

    func testLearningBaselinesDoNotCountAsPhysiologicalCoverage() throws {
        let context = makeContext(
            physiological: PhysiologicalReadinessSnapshot(
                hrvMilliseconds: metric(currentValue: 60, baselineCount: 2),
                restingHeartRateBPM: metric(currentValue: 60, baselineCount: 2)
            ),
            subjective: SubjectiveReadinessSnapshot(energy: 8),
            training: TrainingReadinessSnapshot(weeklyLoadRatio: 1, averageSessionRPE: 5, rightForTodayRate: 1)
        )
        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertEqual(result.confidence, .low)
        XCTAssertFalse(result.subScores.keys.contains(.physiological))
        XCTAssertTrue(result.cautionReasons.contains(.stillLearning))
    }

    func testStaleSignalsIncludePainAndPhysiologicalMetrics() throws {
        let staleDate = assessmentDate.addingTimeInterval(-(48 * 60 * 60 + 1))
        let context = makeContext(
            physiological: PhysiologicalReadinessSnapshot(
                sleepHours: ReadinessMetricSnapshot(currentValue: 8, baselineValues: [], observedAt: staleDate)
            ),
            subjective: SubjectiveReadinessSnapshot(energy: 8),
            pain: PainReadinessSnapshot(intensity: 2, painType: .dull, locationIDs: ["knee"], observedAt: staleDate)
        )
        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertEqual(result.staleSignals, [.pain, .sleep].sorted { $0.rawValue < $1.rawValue })
    }

    func testRepresentativePositiveAndCautionReasonCodes() throws {
        let context = makeContext(
            physiological: PhysiologicalReadinessSnapshot(
                sleepHours: metric(currentValue: 8, baselineCount: 14, baselineValue: 8),
                hrvMilliseconds: metric(currentValue: 60, baselineCount: 14, baselineValue: 80)
            ),
            subjective: SubjectiveReadinessSnapshot(energy: 9, fatigue: 8),
            training: TrainingReadinessSnapshot(weeklyLoadRatio: 1),
            pain: PainReadinessSnapshot(intensity: 8, painType: .sharp, locationIDs: ["knee"], observedAt: assessmentDate)
        )
        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertTrue(result.positiveReasons.contains(.goodSleep))
        XCTAssertTrue(result.positiveReasons.contains(.highEnergy))
        XCTAssertTrue(result.positiveReasons.contains(.balancedTrainingLoad))
        XCTAssertTrue(result.cautionReasons.contains(.highFatigue))
        XCTAssertTrue(result.cautionReasons.contains(.highPain))
        XCTAssertTrue(result.cautionReasons.contains(.hrvBelowBaseline))
    }

    private let assessmentDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func metric(currentValue: Double, baselineCount: Int, baselineValue: Double = 60) -> ReadinessMetricSnapshot {
        ReadinessMetricSnapshot(currentValue: currentValue, baselineValues: Array(repeating: baselineValue, count: baselineCount), observedAt: assessmentDate)
    }
    private func makeContext(physiological: PhysiologicalReadinessSnapshot = .empty, subjective: SubjectiveReadinessSnapshot = .empty, training: TrainingReadinessSnapshot = .empty, pain: PainReadinessSnapshot? = nil, cyclePhase: CyclePhase? = nil) -> DailyTrainingContext {
        DailyTrainingContext(assessmentDate: assessmentDate, timeZoneIdentifier: "America/New_York", physiological: physiological, subjective: subjective, training: training, pain: pain, cyclePhase: cyclePhase, cycleConfidence: cyclePhase == nil ? nil : 0.8)
    }
}
