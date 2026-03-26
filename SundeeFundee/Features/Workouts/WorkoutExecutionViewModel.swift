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
    let enrollment: EnrolledProgram?
    let program: Program?
    let generatedWorkout: GeneratedWorkout?
    let barbellWeightKg: Double
    let weightUnit: WeightUnit

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
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        weightUnit: WeightUnit = .pounds
    ) {
        self.session = session
        self.enrollment = enrollment
        self.program = program
        self.generatedWorkout = nil
        self.oneRepMaxes = oneRepMaxes
        self.barbellWeightKg = barbellWeightKg
        self.weightUnit = weightUnit
        initializeSets()
    }

    init(
        generatedWorkout: GeneratedWorkout,
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        weightUnit: WeightUnit = .pounds
    ) {
        self.generatedWorkout = generatedWorkout
        self.session = Self.mapToSession(generatedWorkout)
        self.enrollment = nil
        self.program = nil
        self.barbellWeightKg = barbellWeightKg
        self.weightUnit = weightUnit
        initializeAISets(from: generatedWorkout)
    }

    private static func mapToSession(_ workout: GeneratedWorkout) -> ProgramSession {
        let exercises = workout.exercises.map { ex in
            ProgramExercise(
                exercise: ex.name,
                variant: nil,
                sets: .fixed(ex.sets),
                reps: parseReps(ex.reps),
                percent1RM: nil,
                restMinutes: ex.restMinutes,
                notes: ex.notes,
                bodyweightOnly: ex.bodyweightOnly
            )
        }
        return ProgramSession(
            sessionID: workout.id,
            sessionName: "AI Workout",
            sessionType: "strength",
            focus: workout.questionnaire.focus.rawValue,
            exercises: exercises
        )
    }

    private static func parseReps(_ reps: String) -> ExerciseValue {
        if reps.uppercased() == "AMRAP" { return .amrap }
        if let fixed = Int(reps) { return .fixed(fixed) }
        let parts = reps.split(separator: "-").compactMap { Int($0) }
        if parts.count == 2 { return .range(parts[0], parts[1]) }
        return .text(reps)
    }

    private func initializeAISets(from workout: GeneratedWorkout) {
        for exercise in workout.exercises {
            let parsedReps = Self.parseActualReps(exercise.reps)
            let sets = (0..<exercise.sets).map { _ in
                SetExecutionState(
                    prescribedReps: exercise.reps,
                    prescribedWeightKg: exercise.weightKg,
                    actualReps: parsedReps,
                    actualWeightKg: exercise.weightKg
                )
            }
            exerciseSets[exercise.name] = sets
        }
    }

    /// Parses a reps string into an Int. Handles "8", "8-10" (takes first), "AMRAP" → nil.
    static func parseActualReps(_ reps: String) -> Int? {
        if reps.uppercased() == "AMRAP" { return nil }
        if let exact = Int(reps) { return exact }
        // Fallback: take first number from a range like "8-10"
        if let first = reps.split(separator: "-").first, let n = Int(first) { return n }
        return nil
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
        guard !isSaving, completedWorkout == nil else { return }
        isSaving = true

        let programID = program?.id ?? "ai-generated"
        let enrollmentID = enrollment?.id
        let week = enrollment?.currentWeek ?? 0
        let day = enrollment?.currentDay ?? 0

        let workout = CompletedWorkout(
            id: UUID().uuidString,
            userID: userID,
            activeCycleID: "",
            programID: programID,
            enrollmentID: enrollmentID,
            week: week,
            day: day,
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

        // Advance the enrollment pointer to the next workout (program path only)
        if let enrollment, let program {
            let enrollmentRepo = SwiftDataEnrolledProgramRepository(context: modelContext)
            let next = Self.nextPosition(
                currentWeek: enrollment.currentWeek,
                currentDay: enrollment.currentDay,
                program: program
            )
            try? enrollmentRepo.updateProgress(enrollment: enrollment, week: next.week, day: next.day)
        }

        isSaving = false
        completedWorkout = workout
        isFinished = true
    }

    // MARK: - Position helper

    /// Returns the next (week, day) in the program, or the current position if at the end.
    static func nextPosition(currentWeek: Int, currentDay: Int, program: Program) -> (week: Int, day: Int) {
        guard let week = program.weeks.first(where: { $0.week == currentWeek }) else {
            return (currentWeek, currentDay)
        }
        if currentDay < week.sessions.count {
            return (currentWeek, currentDay + 1)
        }
        let nextWeek = currentWeek + 1
        if program.weeks.contains(where: { $0.week == nextWeek }) {
            return (nextWeek, 1)
        }
        return (currentWeek, currentDay) // Already at the end
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
