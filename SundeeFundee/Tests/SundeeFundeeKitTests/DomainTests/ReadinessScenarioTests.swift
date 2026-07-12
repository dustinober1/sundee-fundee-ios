import XCTest
@testable import SundeeFundeeKit

final class ReadinessScenarioTests: XCTestCase {
    func testMissingHRVDoesNotReduceTheSameKnownInputs() throws {
        let known = makeContext(hrv: nil)
        let scoreWithoutHRV = try XCTUnwrap(ReadinessAssessmentService.assess(known)).totalScore
        let ineligibleHRV = makeContext(hrv: metric(55, history: Array(repeating: 50, count: 13)))
        let scoreWithIneligibleHRV = try XCTUnwrap(ReadinessAssessmentService.assess(ineligibleHRV)).totalScore
        XCTAssertEqual(scoreWithoutHRV, scoreWithIneligibleHRV)
    }

    func testCyclePhaseOnlyCannotCreateAnAssessment() {
        let context = DailyTrainingContext(
            assessmentDate: Date(), timeZoneIdentifier: "UTC", physiological: .empty,
            subjective: .empty, training: .empty, pain: nil,
            cyclePhase: .menstrual, cycleConfidence: 1
        )
        XCTAssertNil(ReadinessAssessmentService.assess(context))
    }

    func testLowConfidenceCapsAnOtherwiseReadyAssessmentAtMaintain() throws {
        let context = DailyTrainingContext(
            assessmentDate: Date(), timeZoneIdentifier: "UTC", physiological: .empty,
            subjective: SubjectiveReadinessSnapshot(energy: 10, fatigue: 0),
            training: .empty, pain: nil, cyclePhase: nil, cycleConfidence: nil
        )
        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertEqual(result.confidence, .low)
        XCTAssertEqual(result.state, .maintain)
    }

    func testLowConfidenceCannotCreateScoreOnlyRest() throws {
        let context = DailyTrainingContext(
            assessmentDate: Date(), timeZoneIdentifier: "UTC", physiological: .empty,
            subjective: SubjectiveReadinessSnapshot(energy: 0, fatigue: 10),
            training: .empty, pain: nil, cyclePhase: nil, cycleConfidence: nil
        )
        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertEqual(result.confidence, .low)
        XCTAssertEqual(result.state, .maintain)
    }

    func testScoreAndReasonsAreDeterministic() {
        let first = ReadinessAssessmentService.assess(makeContext(hrv: metric(55, history: Array(repeating: 50, count: 14))))
        let second = ReadinessAssessmentService.assess(makeContext(hrv: metric(55, history: Array(repeating: 50, count: 14))))
        XCTAssertEqual(first, second)
    }

    func testHighSleepAndEnergyProducePositiveReasonsWhileHighPainAddsCaution() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let context = DailyTrainingContext(
            assessmentDate: now,
            timeZoneIdentifier: "America/New_York",
            physiological: PhysiologicalReadinessSnapshot(
                sleepHours: ReadinessMetricSnapshot(currentValue: 8, baselineValues: Array(repeating: 8, count: 14), observedAt: now)
            ),
            subjective: SubjectiveReadinessSnapshot(energy: 9),
            training: .empty,
            pain: PainReadinessSnapshot(intensity: 8, painType: .sharp, locationIDs: ["knee"], observedAt: now),
            cyclePhase: nil,
            cycleConfidence: nil
        )

        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertTrue(result.positiveReasons.contains(.goodSleep))
        XCTAssertTrue(result.positiveReasons.contains(.highEnergy))
        XCTAssertTrue(result.cautionReasons.contains(.highPain))
        XCTAssertEqual(result.state, .recover)
    }

    private func makeContext(hrv: ReadinessMetricSnapshot?) -> DailyTrainingContext {
        DailyTrainingContext(
            assessmentDate: Date(timeIntervalSince1970: 1_700_000_000), timeZoneIdentifier: "UTC",
            physiological: PhysiologicalReadinessSnapshot(
                sleepHours: metric(8, history: Array(repeating: 7.5, count: 14)),
                hrvMilliseconds: hrv,
                restingHeartRateBPM: metric(58, history: Array(repeating: 60, count: 14))
            ),
            subjective: SubjectiveReadinessSnapshot(energy: 8, fatigue: 2, soreness: 2, stress: 2, perceivedReadiness: 8),
            training: TrainingReadinessSnapshot(weeklyLoadRatio: 1, averageSessionRPE: 7, rightForTodayRate: 0.9, completedWorkoutsInLast28Days: 8),
            pain: nil, cyclePhase: .luteal, cycleConfidence: 0.8
        )
    }

    private func metric(_ current: Double, history: [Double]) -> ReadinessMetricSnapshot {
        ReadinessMetricSnapshot(currentValue: current, baselineValues: history, observedAt: Date(timeIntervalSince1970: 1_700_000_000))
    }
}
