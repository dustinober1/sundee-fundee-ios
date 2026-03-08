import Foundation
import SwiftData

@MainActor
@Observable
final class WODExecutionViewModel {
    let wod: WOD
    let barbellWeightKg: Double
    let weightUnit: WeightUnit

    /// Keyed by exercise index (position in wod.exercises array) to support
    /// duplicate exercise names (e.g. multiple Deadlift entries at different percentages).
    var exerciseSets: [Int: [SetExecutionState]] = [:]
    var startTime: Date = .now
    var isSaving = false
    var isFinished = false
    var completedWorkout: CompletedWorkout?
    var showRestTimer = false
    var restTimerSeconds: Int = 0
    var showPlateCalc = false
    var plateCalcWeightKg: Double = 60

    var oneRepMaxes: [String: Double] = [:]

    var resolvedTemplateType: WODTemplateType {
        WODTemplateType.from(wod.templateType)
    }

    init(
        wod: WOD,
        oneRepMaxes: [String: Double] = [:],
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        weightUnit: WeightUnit = .pounds
    ) {
        self.wod = wod
        self.oneRepMaxes = oneRepMaxes
        self.barbellWeightKg = barbellWeightKg
        self.weightUnit = weightUnit
        initializeSets()
    }

    // MARK: - Setup

    private func initializeSets() {
        for (index, exercise) in wod.exercises.enumerated() {
            let count = exercise.sets.fixedCount ?? 3
            let prescribed = exercise.reps.description
            let weight = targetWeight(for: exercise)
            let sets = (0..<count).map { _ in
                SetExecutionState(
                    prescribedReps: prescribed,
                    prescribedWeightKg: weight,
                    actualReps: exercise.reps.defaultReps,
                    actualWeightKg: weight
                )
            }
            exerciseSets[index] = sets
        }
    }

    // MARK: - Set mutations

    func updateActualReps(_ reps: Int, exerciseIndex: Int, setIndex: Int) {
        exerciseSets[exerciseIndex]?[setIndex].actualReps = reps
    }

    func updateActualWeight(_ weight: Double, exerciseIndex: Int, setIndex: Int) {
        exerciseSets[exerciseIndex]?[setIndex].actualWeightKg = weight
    }

    func toggleSetCompleted(exerciseIndex: Int, setIndex: Int) {
        guard var sets = exerciseSets[exerciseIndex], setIndex < sets.count else { return }
        sets[setIndex].isCompleted.toggle()
        exerciseSets[exerciseIndex] = sets

        if sets[setIndex].isCompleted, exerciseIndex < wod.exercises.count {
            let exercise = wod.exercises[exerciseIndex]
            let restSecs = Int((exercise.restMinutes ?? 2.0) * 60)
            startRestTimer(seconds: restSecs)
        }
    }

    // MARK: - Rest timer

    func startRestTimer(seconds: Int) {
        restTimerSeconds = seconds
        showRestTimer = true
    }

    func dismissRestTimer() {
        showRestTimer = false
        restTimerSeconds = 0
    }

    // MARK: - Plate calculator

    func openPlateCalc(forWeight kg: Double) {
        plateCalcWeightKg = kg
        showPlateCalc = true
    }

    // MARK: - Completion

    var allSetsCompleted: Bool {
        exerciseSets.values.allSatisfy { $0.allSatisfy(\.isCompleted) }
    }

    func finishWorkout(modelContext: ModelContext, userID: String) {
        guard !isSaving else { return }
        isSaving = true

        let workout = CompletedWorkout(
            id: UUID().uuidString,
            userID: userID,
            activeCycleID: "",
            programID: "wod",
            enrollmentID: nil,
            week: 0,
            day: 0,
            sessionID: wod.id,
            completedAt: .now,
            durationSeconds: Int(Date.now.timeIntervalSince(startTime)),
            notes: nil
        )
        let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)
        try? workoutRepo.save(workout)

        var setIndex = 0
        for (exIdx, exercise) in wod.exercises.enumerated() {
            let sets = exerciseSets[exIdx] ?? []
            for (i, set) in sets.enumerated() {
                let completedSet = CompletedSet(
                    id: UUID().uuidString,
                    userID: userID,
                    workoutID: workout.id,
                    exerciseName: exercise.exercise,
                    setIndex: setIndex + i,
                    prescribedReps: set.prescribedReps,
                    actualReps: set.actualReps,
                    prescribedWeightKg: set.prescribedWeightKg,
                    actualWeightKg: set.actualWeightKg
                )
                try? workoutRepo.save(completedSet)
            }
            setIndex += sets.count
        }

        isSaving = false
        completedWorkout = workout
        isFinished = true
    }

    // MARK: - Helpers

    private func targetWeight(for exercise: ProgramExercise) -> Double? {
        guard let pct = exercise.percent1RM,
              let orm = oneRepMaxes[exercise.exercise] else { return nil }
        return WeightCalculations.calculateTargetWeight(oneRepMax: orm, percentage: pct)
    }
}

// MARK: - ExerciseValue helpers

private extension ExerciseValue {
    var fixedCount: Int? {
        if case .fixed(let n) = self { return n }
        return nil
    }

    var defaultReps: Int {
        switch self {
        case .fixed(let n): return n
        case .range(let lo, _): return lo
        case .amrap: return 0
        case .text: return 0
        }
    }
}
