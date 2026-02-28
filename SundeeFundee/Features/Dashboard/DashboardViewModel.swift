import Foundation
import SwiftData

// MARK: - SkipRecordOption

enum SkipRecordOption {
    case noRecord
    case markAsSkipped
}

@MainActor
@Observable
final class DashboardViewModel {
    var activeEnrollment: EnrolledProgram?
    var activeProgram: Program?
    var nextSession: ProgramSession?
    var recentWorkouts: [CompletedWorkout] = []
    var currentCyclePhase: CyclePhase?
    var barbellWeightKg: Double = PlateCalculation.standardBarKg
    var weightUnit: WeightUnit = .kilograms
    var oneRepMaxes: [String: Double] = [:]

    private let programRepo: any ProgramRepository

    init(programRepo: any ProgramRepository = BundledProgramRepository()) {
        self.programRepo = programRepo
    }

    func load(modelContext: ModelContext) async {
        let enrollmentRepo = SwiftDataEnrolledProgramRepository(context: modelContext)
        let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)
        let cycleRepo = SwiftDataCycleRepository(context: modelContext)
        let userRepo = SwiftDataUserRepository(context: modelContext)

        // Load current user for gender-based bar weight
        let currentUser = try? userRepo.fetchCurrentUser()
        barbellWeightKg = Self.barbellWeight(for: currentUser?.gender)
        weightUnit = currentUser?.weightUnit ?? .pounds

        // Load 1RM data for weight prescriptions (sorted date desc, first per exercise wins)
        let liftRepo = SwiftDataLiftRepository(context: modelContext)
        let allMaxes = (try? liftRepo.fetchOneRepMaxes()) ?? []
        var maxDict: [String: Double] = [:]
        for orm in allMaxes where maxDict[orm.exerciseID] == nil {
            maxDict[orm.exerciseID] = orm.weightKg
        }
        oneRepMaxes = maxDict

        // Load active enrollment
        activeEnrollment = try? enrollmentRepo.fetchActiveEnrollment()

        // Cycle data
        let periodLogs = (try? cycleRepo.fetchPeriodLogs()) ?? []
        let cycleSettings = try? cycleRepo.fetchCycleSettings()
        let cyclePrefs = try? cycleRepo.fetchCycleAdaptationPreferences()

        if let settings = cycleSettings {
            let result = CycleCalculations.calculateCycleStatus(
                periodLogs: periodLogs,
                settings: settings
            )
            currentCyclePhase = result?.currentPhase
        }

        // Load the program for the active enrollment, adapted for cycle phase.
        // Use a default enabled preferences when none has been saved yet (e.g. guest users).
        let effectiveCyclePrefs = cyclePrefs ?? CycleAdaptationPreferences(
            id: "default",
            userID: "",
            adaptationEnabled: true
        )

        if let enrollment = activeEnrollment {
            var program = try? await programRepo.fetchProgram(id: enrollment.programID)
            if let raw = program {
                program = CycleProgramGenerator.adaptProgram(
                    raw,
                    phase: currentCyclePhase,
                    settings: cycleSettings,
                    preferences: effectiveCyclePrefs,
                    periodLogs: periodLogs
                )
            }
            activeProgram = program
            if let adapted = activeProgram {
                nextSession = findNextSession(in: adapted, enrollment: enrollment)
            }
        }

        // Recent workouts (last 10)
        let allWorkouts = (try? workoutRepo.fetchWorkouts()) ?? []
        recentWorkouts = Array(allWorkouts.prefix(10))
    }

    static func barbellWeight(for gender: Gender?) -> Double {
        gender == .female ? PlateCalculation.womenBarKg : PlateCalculation.standardBarKg
    }

    // MARK: - Helpers

    private func findNextSession(in program: Program, enrollment: EnrolledProgram) -> ProgramSession? {
        guard let week = program.weeks.first(where: { $0.week == enrollment.currentWeek }) ?? program.weeks.first else { return nil }
        let dayIndex = enrollment.currentDay - 1
        if dayIndex < week.sessions.count {
            return week.sessions[dayIndex]
        }
        // Advance to next week
        let nextWeekNum = enrollment.currentWeek + 1
        return program.weeks.first(where: { $0.week == nextWeekNum })?.sessions.first
    }

    // MARK: - Position helpers

    /// Returns the next (week, day) position in the program, or the current position if already at the end.
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

    /// Returns the previous (week, day) position in the program, or the current position if already at the start.
    static func previousPosition(currentWeek: Int, currentDay: Int, program: Program) -> (week: Int, day: Int) {
        if currentDay > 1 {
            return (currentWeek, currentDay - 1)
        }
        let prevWeek = currentWeek - 1
        if let prevWeekData = program.weeks.first(where: { $0.week == prevWeek }) {
            return (prevWeek, prevWeekData.sessions.count)
        }
        return (currentWeek, currentDay) // Already at the start
    }

    // MARK: - Skip workout

    func skipWorkout(modelContext: ModelContext, userID: String, recordAs: SkipRecordOption) {
        guard let enrollment = activeEnrollment, let program = activeProgram else { return }

        if recordAs == .markAsSkipped, let session = nextSession {
            let skipped = CompletedWorkout(
                id: UUID().uuidString,
                userID: userID,
                activeCycleID: "",
                programID: program.id,
                enrollmentID: enrollment.id,
                week: enrollment.currentWeek,
                day: enrollment.currentDay,
                sessionID: session.sessionID,
                completedAt: .now,
                durationSeconds: 0,
                notes: "skipped"
            )
            let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)
            try? workoutRepo.save(skipped)
        }

        let next = Self.nextPosition(
            currentWeek: enrollment.currentWeek,
            currentDay: enrollment.currentDay,
            program: program
        )
        let enrollmentRepo = SwiftDataEnrolledProgramRepository(context: modelContext)
        try? enrollmentRepo.updateProgress(enrollment: enrollment, week: next.week, day: next.day)

        Task { await load(modelContext: modelContext) }
    }

    // MARK: - Delete workout

    func deleteWorkout(_ workout: CompletedWorkout, modelContext: ModelContext) {
        let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)
        try? workoutRepo.deleteWorkoutWithSets(workout)

        // Roll back enrollment progress only when the deleted workout matches the active enrollment
        if let enrollment = activeEnrollment, let program = activeProgram,
           workout.enrollmentID == enrollment.id {
            let prev = Self.previousPosition(
                currentWeek: enrollment.currentWeek,
                currentDay: enrollment.currentDay,
                program: program
            )
            let enrollmentRepo = SwiftDataEnrolledProgramRepository(context: modelContext)
            try? enrollmentRepo.updateProgress(enrollment: enrollment, week: prev.week, day: prev.day)
        }

        Task { await load(modelContext: modelContext) }
    }
}
