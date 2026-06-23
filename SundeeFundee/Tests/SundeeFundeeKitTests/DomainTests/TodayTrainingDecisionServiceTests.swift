import XCTest
@testable import SundeeFundeeKit

final class TodayTrainingDecisionServiceTests: XCTestCase {
    func testClearSignalsReturnTrain() {
        let decision = TodayTrainingDecisionService.decision(
            cyclePhase: .follicular,
            cycleConfidence: 0.8,
            painIntensity: 2,
            energyLevel: .high,
            weeklyPlanProgress: WeeklyPlanProgress(completed: 1, target: 3, nextWorkoutWeekday: 4),
            deloadRecommended: false
        )

        XCTAssertEqual(decision.kind, .train)
    }

    func testModeratePainReturnsModify() {
        let decision = TodayTrainingDecisionService.decision(
            cyclePhase: .luteal,
            cycleConfidence: 0.6,
            painIntensity: 4,
            energyLevel: .medium,
            weeklyPlanProgress: nil,
            deloadRecommended: false
        )

        XCTAssertEqual(decision.kind, .modify)
    }

    func testDeloadOrHighPainReturnsRecover() {
        let deloadDecision = TodayTrainingDecisionService.decision(
            cyclePhase: .menstrual,
            cycleConfidence: 0.9,
            painIntensity: 3,
            energyLevel: .medium,
            weeklyPlanProgress: nil,
            deloadRecommended: true
        )
        XCTAssertEqual(deloadDecision.kind, .recover)

        let highPainDecision = TodayTrainingDecisionService.decision(
            cyclePhase: .follicular,
            cycleConfidence: 0.9,
            painIntensity: 8,
            energyLevel: .medium,
            weeklyPlanProgress: nil,
            deloadRecommended: false
        )
        XCTAssertEqual(highPainDecision.kind, .recover)
    }

    func testLowEnergyReturnsModify() {
        let decision = TodayTrainingDecisionService.decision(
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
}
