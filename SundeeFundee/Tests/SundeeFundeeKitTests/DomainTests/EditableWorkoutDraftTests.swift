import XCTest
@testable import SundeeFundeeKit

final class EditableWorkoutDraftTests: XCTestCase {
    func testRemoveExercisePreservesAtLeastOneExercise() {
        var draft = EditableWorkoutDraft(workout: makeWorkout(exerciseCount: 1, sets: 3))

        let removed = draft.removeExercise(id: draft.workout.exercises[0].id)

        XCTAssertFalse(removed)
        XCTAssertEqual(draft.workout.exercises.count, 1)
    }

    func testReduceVolumePreservesAtLeastOneSetPerExercise() {
        var draft = EditableWorkoutDraft(workout: makeWorkout(exerciseCount: 2, sets: 1))

        let changed = draft.reduceVolume()

        XCTAssertFalse(changed)
        XCTAssertEqual(draft.workout.exercises.map(\.sets), [1, 1])
    }

    func testShortenWorkoutReducesExerciseCountAndRecordsEdits() {
        var draft = EditableWorkoutDraft(workout: makeWorkout(exerciseCount: 6, sets: 3))

        let changed = draft.shorten(to: 20)

        XCTAssertTrue(changed)
        XCTAssertEqual(draft.workout.exercises.count, 3)
        XCTAssertEqual(draft.edits.count, 3)
        XCTAssertTrue(draft.edits.allSatisfy { $0.editType == .removedExercise })
    }

    func testRestoreOriginalRevertsEdits() {
        var draft = EditableWorkoutDraft(workout: makeWorkout(exerciseCount: 4, sets: 3))
        _ = draft.shorten(to: 20)

        draft.restoreOriginal()

        XCTAssertEqual(draft.workout.exercises.count, 4)
        XCTAssertTrue(draft.edits.isEmpty)
    }

    private func makeWorkout(exerciseCount: Int, sets: Int) -> GeneratedWorkout {
        GeneratedWorkout(
            id: "generated",
            createdAt: Date(),
            isFavorite: false,
            coachingSummary: "Test workout",
            exercises: (0..<exerciseCount).map { index in
                GeneratedExercise(
                    id: "exercise-\(index)",
                    name: "Exercise \(index)",
                    sets: sets,
                    reps: "8",
                    restMinutes: 1.5
                )
            },
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 45,
                focus: .fullBody,
                energyLevel: .medium,
                equipment: .fullGym
            )
        )
    }
}
