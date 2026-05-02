import XCTest
@testable import SundeeFundeeKit

final class CoachReasonCodeBuilderTests: XCTestCase {
    private func codes(context: CoachContext = CoachContext(), preferences: QuestionnaireAnswers) -> [CoachReasonCode] {
        CoachReasonCodeBuilder.codes(context: context, preferences: preferences)
    }

    func testEnergyMappings() {
        XCTAssertTrue(codes(preferences: .init(timeMinutes: 30, focus: .fullBody, energyLevel: .low, equipment: .fullGym)).contains(.lowEnergyReducedVolume))
        XCTAssertTrue(codes(preferences: .init(timeMinutes: 30, focus: .fullBody, energyLevel: .medium, equipment: .fullGym)).contains(.mediumEnergyStandardPlan))
        XCTAssertTrue(codes(preferences: .init(timeMinutes: 30, focus: .fullBody, energyLevel: .high, equipment: .fullGym)).contains(.highEnergySlightIntensityBump))
    }

    func testCycleAndEquipmentAndInjuryMappings() {
        let injury = Injury(id: "i", locationIds: "knee", name: "knee strain", recoveryPhase: .rehab, dateCreated: Date(), phaseUpdated: Date())
        let context = CoachContext(cyclePhase: .menstrual, injuries: [injury], equipment: .homeDumbbells)
        let result = codes(context: context, preferences: .init(timeMinutes: 30, focus: .fullBody, energyLevel: .low, equipment: .homeDumbbells))
        XCTAssertTrue(result.contains(.menstrualLowerVolumeLongerRest))
        XCTAssertTrue(result.contains(.activeInjuriesFilteredExercises))
        XCTAssertTrue(result.contains(.equipmentLimitedExercisePool))
        XCTAssertTrue(result.contains(.highSkillFilteredForLowEnergy))
    }

    func testTrainingWarningMappings() {
        let plateau = PlateauDetector.PlateauAlert(exerciseName: "Back Squat", currentWeight: 100, unit: .kg, bestWeight: 100, stallCount: 3, daysSinceBest: 21, recommendation: "Vary reps")
        let progress = PlateauDetector.RateOfProgressAlert(exerciseName: "Bench", currentRate: 0, historicalRate: 1, message: "Slowing")
        let context = CoachContext(workoutsThisWeek: 5, plateaus: [plateau], volumePlateaus: [plateau], progressWarnings: [progress])
        let result = codes(context: context, preferences: .init(timeMinutes: 30, focus: .fullBody, energyLevel: .medium, equipment: .fullGym))
        XCTAssertTrue(result.contains(.plateauNeedsRepVariation))
        XCTAssertTrue(result.contains(.volumePlateauNeedsVariation))
        XCTAssertTrue(result.contains(.progressSlowdownWarning))
        XCTAssertTrue(result.contains(.highWeeklyTrainingRecoveryReminder))
    }
}
