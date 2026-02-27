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

    private let programRepo: any ProgramRepository

    init(programRepo: any ProgramRepository = CloudKitProgramRepository()) {
        self.programRepo = programRepo
    }

    func load(modelContext: ModelContext) async {
        let enrollmentRepo = SwiftDataEnrolledProgramRepository(context: modelContext)
        let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)
        let cycleRepo = SwiftDataCycleRepository(context: modelContext)

        // Load active enrollment
        activeEnrollment = try? enrollmentRepo.fetchActiveEnrollment()

        // Load the program for the active enrollment
        if let enrollment = activeEnrollment {
            activeProgram = try? await programRepo.fetchProgram(id: enrollment.programID)
            if let program = activeProgram {
                nextSession = findNextSession(in: program, enrollment: enrollment)
            }
        }

        // Recent workouts (last 10)
        let allWorkouts = try! workoutRepo.fetchWorkouts()
        recentWorkouts = Array(allWorkouts.prefix(10))

        // Cycle phase from period logs
        if let logs = try? cycleRepo.fetchPeriodLogs(),
           let settings = try? cycleRepo.fetchCycleSettings() {
            let result = CycleCalculations.calculateCycleStatus(
                periodLogs: logs,
                settings: settings
            )
            currentCyclePhase = result?.currentPhase
        }
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
