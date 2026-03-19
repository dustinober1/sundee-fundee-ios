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
    var plateCalcExerciseName: String = ""
    var barbellPresets: [BarbellPresetDTO] = []
    var selectedPresetID: String?

    private var barbellRepo: BarbellRepository?
    private var userID: String = ""
    private var gender: Gender?

    // One-rep max reference values (keyed by exercise name)
    var oneRepMaxes: [String: Double] = [:]

    init(
        session: ProgramSession,
        enrollment: EnrolledProgram,
        program: Program,
        oneRepMaxes: [String: Double] = [:],
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        weightUnit: WeightUnit = .pounds,
        barbellRepo: BarbellRepository? = nil,
        userID: String = "",
        gender: Gender? = nil
    ) {
        self.session = session
        self.enrollment = enrollment
        self.program = program
        self.generatedWorkout = nil
        self.oneRepMaxes = oneRepMaxes
        self.barbellWeightKg = barbellWeightKg
        self.weightUnit = weightUnit
        self.barbellRepo = barbellRepo
        self.userID = userID
        self.gender = gender
        initializeSets()
    }

    init(
        generatedWorkout: GeneratedWorkout,
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        weightUnit: WeightUnit = .pounds,
        barbellRepo: BarbellRepository? = nil,
        userID: String = "",
        gender: Gender? = nil
    ) {
        self.generatedWorkout = generatedWorkout
        self.session = Self.mapToSession(generatedWorkout)
        self.enrollment = nil
        self.program = nil
        self.barbellWeightKg = barbellWeightKg
        self.weightUnit = weightUnit
        self.barbellRepo = barbellRepo
        self.userID = userID
        self.gender = gender
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
            // Convert weight to kg for execution state (internal tracking is always in kg)
            let weightKg: Double?
            if let w = exercise.weight, w > 0 {
                if exercise.weightUnit.lowercased().contains("kg") {
                    weightKg = w
                } else {
                    weightKg = w / WeightUnitConversion.poundsPerKilogram
                }
            } else {
                weightKg = nil
            }
            let sets = (0..<exercise.sets).map { _ in
                SetExecutionState(
                    prescribedReps: exercise.reps,
                    prescribedWeightKg: weightKg,
                    actualReps: Int(exercise.reps) ?? 0,
                    actualWeightKg: weightKg
                )
            }
            exerciseSets[exercise.name] = sets
        }
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

    func loadBarbellPresets() {
        guard let repo = barbellRepo else { return }
        barbellPresets = (try? repo.fetchPresets(userID: userID)) ?? []
    }

    func openPlateCalcForActual(exerciseName: String, weightKg: Double) {
        plateCalcExerciseName = exerciseName
        plateCalcWeightKg = weightKg

        if let repo = barbellRepo {
            if let mapping = try? repo.fetchMapping(exerciseName: exerciseName, userID: userID) {
                selectedPresetID = mapping.barbellPresetID
            } else {
                let suggestedName = BarbellDefaults.suggestedPresetName(for: exerciseName, gender: gender)
                if let preset = barbellPresets.first(where: { $0.name == suggestedName }) {
                    selectedPresetID = preset.id
                    let mapping = ExerciseBarMappingDTO(
                        id: UUID().uuidString,
                        userID: userID,
                        exerciseName: exerciseName,
                        barbellPresetID: preset.id
                    )
                    try? repo.saveMapping(mapping)
                } else {
                    selectedPresetID = barbellPresets.first?.id
                }
            }
        }

        showPlateCalc = true
    }

    func updateBarSelection(presetID: String) {
        selectedPresetID = presetID
        guard let repo = barbellRepo, !plateCalcExerciseName.isEmpty else { return }
        let mapping = ExerciseBarMappingDTO(
            id: UUID().uuidString,
            userID: userID,
            exerciseName: plateCalcExerciseName,
            barbellPresetID: presetID
        )
        try? repo.saveMapping(mapping)
    }

    var selectedBarbellWeightKg: Double {
        if let id = selectedPresetID, let preset = barbellPresets.first(where: { $0.id == id }) {
            return preset.weightKg
        }
        return barbellWeightKg
    }

    // MARK: - Completion

    var allSetsCompleted: Bool {
        exerciseSets.values.allSatisfy { $0.allSatisfy(\.isCompleted) }
    }

    func finishWorkout(modelContext: ModelContext, userID: String) {
        guard !isSaving else { return }
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
                    actualWeightKg: set.actualWeightKg,
                    generatedWorkoutID: generatedWorkout?.id
                )
                try? workoutRepo.save(completedSet)
            }
            setIndex += sets.count
        }

        // Mark AI workout record as completed
        if let generatedWorkout {
            let workoutRecords = (try? modelContext.fetch(FetchDescriptor<GeneratedWorkoutRecord>())) ?? []
            if let record = workoutRecords.first(where: { $0.id == generatedWorkout.id }) {
                record.isCompleted = true
                try? modelContext.save()
            }
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

    // MARK: - AI Workout Contribution

    /// Called after AI workout completion to consider contributing to shared database.
    func considerContributing(modelContext: ModelContext, userID: String) {
        guard let generatedWorkout, !(generatedWorkout.questionnaire.desiredSkills?.isEmpty ?? true) else { return }

        // Mark as eligible for contribution (actual contribution happens in UI after user approval)
        let workoutRecords = (try? modelContext.fetch(FetchDescriptor<GeneratedWorkoutRecord>())) ?? []
        if workoutRecords.first(where: { $0.id == generatedWorkout.id }) != nil {
            // Will be set to true after user confirms sharing in UI
            // record.contributedToDatabase = true
        }
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
