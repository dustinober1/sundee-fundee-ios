import XCTest
@testable import SundeeFundeeKit

final class CoachDecisionPacketBuilderTests: XCTestCase {
    func testWorkoutPacketUsesOnlySelectedExerciseNamesAsAllowed() async throws {
        let preferences = QuestionnaireAnswers(timeMinutes: 30, focus: .fullBody, energyLevel: .medium, equipment: .fullGym)
        let base = try await DeterministicCoachService().generateWorkout(context: CoachContext(), preferences: preferences)
        let packet = CoachDecisionPacketBuilder.workoutPacket(base: base, context: CoachContext(), preferences: preferences, promptVersion: "test")
        XCTAssertEqual(packet.selectedExerciseNames, base.workout.exercises.map(\.name))
        XCTAssertEqual(packet.allowedExerciseNames, packet.selectedExerciseNames)
    }

    func testReasonCodeRegressionMappings() async throws {
        let preferences = QuestionnaireAnswers(timeMinutes: 30, focus: .fullBody, energyLevel: .low, equipment: .homeDumbbells)
        let injury = Injury(id: "i", locationIds: "shoulder", name: "shoulder pain", recoveryPhase: .rehab, dateCreated: Date(), phaseUpdated: Date())
        let plateau = PlateauDetector.PlateauAlert(exerciseName: "Back Squat", currentWeight: 100, unit: .kg, bestWeight: 100, stallCount: 3, daysSinceBest: 21, recommendation: "Vary reps")
        let context = CoachContext(cyclePhase: .menstrual, cycleConfidence: 0.62, injuries: [injury], workoutsThisWeek: 5, plateaus: [plateau], equipment: .homeDumbbells)
        let base = try await DeterministicCoachService().generateWorkout(context: context, preferences: preferences)
        let packet = CoachDecisionPacketBuilder.workoutPacket(base: base, context: context, preferences: preferences, promptVersion: "test")
        XCTAssertTrue(packet.reasonCodes.contains(.lowEnergyReducedVolume))
        XCTAssertTrue(packet.reasonCodes.contains(.menstrualLowerVolumeLongerRest))
        XCTAssertTrue(packet.reasonCodes.contains(.equipmentLimitedExercisePool))
        XCTAssertTrue(packet.reasonCodes.contains(.activeInjuriesFilteredExercises))
        XCTAssertTrue(packet.reasonCodes.contains(.plateauNeedsRepVariation))
        XCTAssertTrue(packet.reasonCodes.contains(.highWeeklyTrainingRecoveryReminder))
        XCTAssertEqual(packet.cycleConfidence, 0.62)
        XCTAssertTrue(packet.sanitizedForPrompt().contains("Cycle confidence: 62%"))
        XCTAssertFalse(packet.sanitizedForPrompt().lowercased().contains("shoulder pain"))
    }

    func testFullGymDoesNotIncludeEquipmentLimitedCode() async throws {
        let preferences = QuestionnaireAnswers(timeMinutes: 30, focus: .fullBody, energyLevel: .medium, equipment: .fullGym)
        let context = CoachContext(equipment: .fullGym)
        let base = try await DeterministicCoachService().generateWorkout(context: context, preferences: preferences)
        let packet = CoachDecisionPacketBuilder.workoutPacket(base: base, context: context, preferences: preferences, promptVersion: "test")
        XCTAssertFalse(packet.reasonCodes.contains(.equipmentLimitedExercisePool))
    }
}
