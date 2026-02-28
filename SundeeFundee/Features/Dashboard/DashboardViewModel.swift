import Foundation
import SwiftData

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
        weightUnit = currentUser?.weightUnit ?? .kilograms

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

        // Load the program for the active enrollment, adapted for cycle phase
        if let enrollment = activeEnrollment {
            var program = try? await programRepo.fetchProgram(id: enrollment.programID)
            if let raw = program {
                program = CycleProgramGenerator.adaptProgram(
                    raw,
                    phase: currentCyclePhase,
                    settings: cycleSettings,
                    preferences: cyclePrefs,
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
}
