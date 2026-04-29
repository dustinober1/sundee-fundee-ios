import XCTest
@testable import SundeeFundeeKit

final class CycleAwareAdjustmentServiceTests: XCTestCase {
    func testMenstrualLowEnergyReducesVolumeAndAddsRationale() {
        let adjustment = CycleAwareAdjustmentService.adjustment(
            phase: .menstrual,
            energyLevel: .low,
            goal: "Strength",
            equipment: .fullGym
        )

        XCTAssertLessThan(adjustment.volumeMultiplier, 1.0)
        XCTAssertGreaterThan(adjustment.restMultiplier, 1.0)
        XCTAssertGreaterThanOrEqual(adjustment.rationale.reasons.count, 2)
    }

    func testApplyChangesGeneratedWorkoutSetsAndRest() {
        let workout = GeneratedWorkout(
            id: "g1",
            createdAt: Date(),
            isFavorite: false,
            coachingSummary: "Summary",
            exercises: [
                GeneratedExercise(id: "e1", name: "Squat", sets: 4, reps: "8", restMinutes: 1.0)
            ],
            questionnaire: QuestionnaireAnswers(timeMinutes: 30, focus: .fullBody, energyLevel: .low, equipment: .fullGym)
        )
        let adjustment = CycleAwareAdjustment(
            volumeMultiplier: 0.5,
            restMultiplier: 2.0,
            rationale: WorkoutRationale(headline: "Test", reasons: ["A", "B"])
        )

        let adjusted = CycleAwareAdjustmentService.apply(adjustment, to: workout)

        XCTAssertEqual(adjusted.exercises.first?.sets, 2)
        XCTAssertEqual(adjusted.exercises.first?.restMinutes, 2.0)
    }
}
