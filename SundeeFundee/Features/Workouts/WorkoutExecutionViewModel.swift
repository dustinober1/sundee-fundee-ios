import Foundation
import SwiftData

// MARK: - SetExecutionState

struct SetExecutionState {
    var prescribedReps: String     // "5", "8-10", "AMRAP"
    var prescribedWeightKg: Double?
    var actualReps: Int?
    var actualWeightKg: Double?
    var isCompleted: Bool = false
    var rpe: Double?               // 1-10 RPE scale (optional)
}

// MARK: - WorkoutExecutionState

@MainActor
@Observable
final class WorkoutExecutionViewModel {
    let session: ProgramSession
    let enrollment: EnrolledProgram
    let program: Program
    let barbellWeightKg: Double

    var exerciseSets: [String: [SetExecutionState]] = [:]
    var startTime: Date = .now
    var isSaving = false
    var isFinished = false
    var completedWorkout: CompletedWorkout?
    var showRestTimer = false
    var restTimerSeconds: Int = 0
    var showPlateCalc = false
    var plateCalcWeightKg: Double = 60
    var errorMessage: String?

    // One-rep max reference values (keyed by exercise name)
    var oneRepMaxes: [String: Double] = [:]

    init(
        session: ProgramSession,
        enrollment: EnrolledProgram,
        program: Program,
        oneRepMaxes: [String: Double] = [:],
        barbellWeightKg: Double = PlateCalculation.standardBarKg
    ) {
        self.session = session
        self.enrollment = enrollment
        self.program = program
        self.oneRepMaxes = oneRepMaxes
        self.barbellWeightKg = barbellWeightKg
        initializeSets()
    }

    // MARK: - Setup

    private func initializeSets() {
        for exercise in session.exercises {
            let count = exercise.sets.fixedCount ?? 3
            let prescribed = prescribedRepsString(exercise.reps)
            let weight = targetWeight(for: exercise)
            let sets = (0..<count).map { _ in
                SetExecutionState(
                    prescribedReps: prescribed,
                    prescribedWeightKg: weight,
                    actualReps: exercise.reps.defaultReps,
                    actualWeightKg: weight
                )
            }
            exerciseSets[exercise.exercise] = sets
        }
    }

    // MARK: - Set mutations

    func updateActualReps(_ reps: Int, exerciseName: String, setIndex: Int) {
        exerciseSets[exerciseName]?[setIndex].actualReps = reps
    }

    func updateActualWeight(_ weight: Double, exerciseName: String, setIndex: Int) {
        exerciseSets[exerciseName]?[setIndex].actualWeightKg = weight
    }

    func toggleSetCompleted(exerciseName: String, setIndex: Int) {
        guard var sets = exerciseSets[exerciseName], setIndex < sets.count else { return }
        sets[setIndex].isCompleted.toggle()
        exerciseSets[exerciseName] = sets

        // Auto-start rest timer when a set is completed
        if sets[setIndex].isCompleted, let exercise = currentExercise(named: exerciseName) {
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
            programID: program.id,
            enrollmentID: enrollment.id,
            week: enrollment.currentWeek,
            day: enrollment.currentDay,
            sessionID: session.sessionID,
            completedAt: .now,
            durationSeconds: Int(Date.now.timeIntervalSince(startTime)),
            notes: nil
        )
        let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)
        try? workoutRepo.save(workout)

        var setIndex = 0
        for exercise in session.exercises {
            let sets = exerciseSets[exercise.exercise] ?? []
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

    private func currentExercise(named: String) -> ProgramExercise? {
        session.exercises.first { $0.exercise == named }
    }

    private func prescribedRepsString(_ value: ExerciseValue) -> String {
        value.description
    }

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
