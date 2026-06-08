import XCTest
@testable import SundeeFundeeKit

final class TodayTrainingDecisionServiceTests: XCTestCase {
    func testHighRecoveryReturnsTrain() {
        let decision = TodayTrainingDecisionService.decision(
            recoveryScore: makeScore(total: 78),
            cyclePhase: .follicular,
            cycleConfidence: 0.8,
            painIntensity: 2,
            energyLevel: .high,
            weeklyPlanProgress: WeeklyPlanProgress(completed: 1, target: 3, nextWorkoutWeekday: 4),
            deloadRecommended: false
        )

        XCTAssertEqual(decision.kind, .train)
    }

    func testModerateRecoveryReturnsModify() {
        let decision = TodayTrainingDecisionService.decision(
            recoveryScore: makeScore(total: 55),
            cyclePhase: .luteal,
            cycleConfidence: 0.6,
            painIntensity: 3,
            energyLevel: .medium,
            weeklyPlanProgress: nil,
            deloadRecommended: false
        )

        XCTAssertEqual(decision.kind, .modify)
    }

    func testLowRecoveryOrHighPainReturnsRecover() {
        let lowScoreDecision = TodayTrainingDecisionService.decision(
            recoveryScore: makeScore(total: 32),
            cyclePhase: .menstrual,
            cycleConfidence: 0.9,
            painIntensity: 3,
            energyLevel: .low,
            weeklyPlanProgress: nil,
            deloadRecommended: false
        )
        XCTAssertEqual(lowScoreDecision.kind, .recover)

        let highPainDecision = TodayTrainingDecisionService.decision(
            recoveryScore: makeScore(total: 82),
            cyclePhase: .follicular,
            cycleConfidence: 0.9,
            painIntensity: 8,
            energyLevel: .medium,
            weeklyPlanProgress: nil,
            deloadRecommended: false
        )
        XCTAssertEqual(highPainDecision.kind, .recover)
    }

    func testMissingScoreWithLowEnergyReturnsModify() {
        let decision = TodayTrainingDecisionService.decision(
            recoveryScore: nil,
            cyclePhase: nil,
            cycleConfidence: nil,
            painIntensity: nil,
            energyLevel: .low,
            weeklyPlanProgress: nil,
            deloadRecommended: false
        )

        XCTAssertEqual(decision.kind, .modify)
    }

    func testMissingCyclePhaseUsesNeutralModifyCopy() {
        let decision = TodayTrainingDecisionService.decision(
            recoveryScore: nil,
            cyclePhase: nil,
            cycleConfidence: nil,
            painIntensity: 4,
            energyLevel: .medium,
            weeklyPlanProgress: nil,
            deloadRecommended: false
        )

        XCTAssertEqual(decision.kind, .modify)
        XCTAssertEqual(decision.subtitle, "A lighter or shorter session is recommended today.")
        XCTAssertFalse(decision.subtitle.localizedCaseInsensitiveContains("unknown phase"))
    }

    private func makeScore(total: Int) -> RecoveryScore {
        RecoveryScore(
            total: total,
            recommendation: total >= 70 ? .pushDay : (total >= 40 ? .moderate : .restDay),
            subScores: [.sleep: total],
            presentInputCount: 1,
            totalInputCount: 5,
            explanations: [.sleep: "Sleep signal is \(total)/100."]
        )
    }
}
