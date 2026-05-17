import Foundation

public struct EditableWorkoutDraft: Sendable {
    public private(set) var workout: GeneratedWorkout
    public private(set) var edits: [WorkoutEdit] = []

    private let original: GeneratedWorkout

    public init(workout: GeneratedWorkout) {
        self.workout = workout
        self.original = workout
    }

    @discardableResult
    public mutating func shorten(to minutes: Int) -> Bool {
        let targetCount: Int
        switch minutes {
        case ...20:
            targetCount = 3
        case 21...30:
            targetCount = 4
        case 31...45:
            targetCount = 5
        default:
            targetCount = workout.exercises.count
        }

        guard workout.exercises.count > max(1, targetCount) else { return false }

        let kept = Array(workout.exercises.prefix(max(1, targetCount)))
        let removed = workout.exercises.dropFirst(kept.count)
        for exercise in removed {
            edits.append(WorkoutEdit(editType: .removedExercise, exerciseName: exercise.name))
        }
        workout = copyWorkout(exercises: kept)
        return true
    }

    @discardableResult
    public mutating func reduceVolume() -> Bool {
        var changed = false
        let reduced = workout.exercises.map { exercise in
            guard exercise.sets > 1 else { return exercise }
            changed = true
            edits.append(WorkoutEdit(editType: .changedVolume, exerciseName: exercise.name))
            return copyExercise(exercise, sets: exercise.sets - 1)
        }

        guard changed else { return false }
        workout = copyWorkout(exercises: reduced)
        return true
    }

    @discardableResult
    public mutating func removeExercise(id: String) -> Bool {
        guard workout.exercises.count > 1,
              let removed = workout.exercises.first(where: { $0.id == id }) else { return false }
        edits.append(WorkoutEdit(editType: .removedExercise, exerciseName: removed.name))
        workout = copyWorkout(exercises: workout.exercises.filter { $0.id != id })
        return true
    }

    @discardableResult
    public mutating func swapExercise(id: String, replacement: GeneratedExercise) -> Bool {
        guard let index = workout.exercises.firstIndex(where: { $0.id == id }) else { return false }
        let originalExercise = workout.exercises[index]
        var updated = workout.exercises
        updated[index] = replacement
        edits.append(WorkoutEdit(
            editType: .swappedExercise,
            exerciseName: originalExercise.name,
            replacementExercise: replacement.name
        ))
        workout = copyWorkout(exercises: updated)
        return true
    }

    public mutating func restoreOriginal() {
        workout = original
        edits.removeAll()
    }

    public var skippedOrChangedExercises: [String] {
        Array(Set(edits.map(\.exerciseName))).sorted()
    }

    private func copyWorkout(exercises: [GeneratedExercise]) -> GeneratedWorkout {
        GeneratedWorkout(
            id: workout.id,
            createdAt: workout.createdAt,
            isFavorite: workout.isFavorite,
            coachingSummary: workout.coachingSummary,
            exercises: exercises,
            questionnaire: workout.questionnaire
        )
    }

    private func copyExercise(_ exercise: GeneratedExercise, sets: Int) -> GeneratedExercise {
        GeneratedExercise(
            id: exercise.id,
            name: exercise.name,
            sets: max(1, sets),
            reps: exercise.reps,
            weightKg: exercise.weightKg,
            restMinutes: exercise.restMinutes,
            notes: exercise.notes,
            reasoning: exercise.reasoning,
            bodyweightOnly: exercise.bodyweightOnly,
            percentageOfMax: exercise.percentageOfMax
        )
    }
}
