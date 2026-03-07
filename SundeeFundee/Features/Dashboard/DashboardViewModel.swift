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
    var weightUnit: WeightUnit = .pounds
    var oneRepMaxes: [String: Double] = [:]
    var activeInjuriesNeedingCheckIn: [InjuryProfile] = []
    var rehabSession: ProgramSession?
    var readinessScore: Double?
    var todayWOD: WOD?

    private let programRepo: any ProgramRepository
    private let readinessRepo: (any ReadinessRepository)?
    private let wodRepo: any WODRepository

    init(
        programRepo: any ProgramRepository = BundledProgramRepository(),
        readinessRepo: (any ReadinessRepository)? = nil,
        wodRepo: any WODRepository = BundledWODRepository()
    ) {
        self.programRepo = programRepo
        self.readinessRepo = readinessRepo
        self.wodRepo = wodRepo
    }

    func load(modelContext: ModelContext) async {
        let currentUser = loadUserConfiguration(modelContext: modelContext)
        loadOneRepMaxes(modelContext: modelContext)
        loadEnrollment(modelContext: modelContext)

        let cycleData = loadCycleData(modelContext: modelContext)
        let activeInjuries = loadInjuries(modelContext: modelContext, currentUser: currentUser)
        await loadReadinessMetrics()

        await loadActiveProgram(
            modelContext: modelContext,
            periodLogs: cycleData.periodLogs,
            cycleSettings: cycleData.cycleSettings,
            effectiveCyclePrefs: cycleData.effectiveCyclePrefs,
            activeInjuries: activeInjuries
        )

        await loadWODAndRecentWorkouts(modelContext: modelContext)
    }

    private func loadUserConfiguration(modelContext: ModelContext) -> User? {
        let userRepo = SwiftDataUserRepository(context: modelContext)
        let currentUser = try? userRepo.fetchCurrentUser()
        barbellWeightKg = Self.barbellWeight(for: currentUser?.gender)
        weightUnit = currentUser?.weightUnit ?? .pounds
        return currentUser
    }

    private func loadOneRepMaxes(modelContext: ModelContext) {
        let liftRepo = SwiftDataLiftRepository(context: modelContext)
        let allMaxes = (try? liftRepo.fetchOneRepMaxes()) ?? []
        var maxDict: [String: Double] = [:]
        for orm in allMaxes where maxDict[orm.exerciseID] == nil {
            maxDict[orm.exerciseID] = orm.weightKg
        }
        oneRepMaxes = maxDict
    }

    private func loadEnrollment(modelContext: ModelContext) {
        let enrollmentRepo = SwiftDataEnrolledProgramRepository(context: modelContext)
        activeEnrollment = try? enrollmentRepo.fetchActiveEnrollment()
    }

    private func loadCycleData(modelContext: ModelContext) -> (periodLogs: [PeriodLog], cycleSettings: CycleSettings?, effectiveCyclePrefs: CycleAdaptationPreferences) {
        let cycleRepo = SwiftDataCycleRepository(context: modelContext)
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

        let effectiveCyclePrefs = cyclePrefs ?? CycleAdaptationPreferences(
            id: "default",
            userID: "",
            adaptationEnabled: true
        )

        return (periodLogs, cycleSettings, effectiveCyclePrefs)
    }

    private func loadInjuries(modelContext: ModelContext, currentUser: User?) -> [InjuryProfile] {
        let injuryRepo = SwiftDataInjuryRepository(context: modelContext)
        let activeInjuries = (try? injuryRepo.fetchActiveInjuries(userID: currentUser?.id ?? "")) ?? []

        let painLogRepo = SwiftDataPainLogRepository(context: modelContext)
        activeInjuriesNeedingCheckIn = activeInjuries.filter { injury in
            let logs = (try? painLogRepo.fetchLogs(injuryProfileID: injury.id)) ?? []
            return !PainTrendAnalyzer.hasRecentLog(logs: logs)
        }

        rehabSession = RehabSessionGenerator.generateSession(injuries: activeInjuries)
        return activeInjuries
    }

    private func loadReadinessMetrics() async {
        if let readinessRepo {
            let metrics = try? await readinessRepo.fetchLatestMetrics()
            readinessScore = metrics?.readinessScore
        }
    }

    private func loadActiveProgram(
        modelContext: ModelContext,
        periodLogs: [PeriodLog],
        cycleSettings: CycleSettings?,
        effectiveCyclePrefs: CycleAdaptationPreferences,
        activeInjuries: [InjuryProfile]
    ) async {
        guard let enrollment = activeEnrollment else { return }

        var program = try? await programRepo.fetchProgram(id: enrollment.programID)

        if program == nil {
            // Program no longer exists — cancel orphaned enrollment
            let enrollmentRepo = SwiftDataEnrolledProgramRepository(context: modelContext)
            try? enrollmentRepo.cancel(enrollment)
            activeEnrollment = nil
            return
        }

        if let raw = program {
            var adapted = CycleProgramGenerator.adaptProgram(
                raw,
                phase: currentCyclePhase,
                settings: cycleSettings,
                preferences: effectiveCyclePrefs,
                periodLogs: periodLogs,
                readinessScore: readinessScore
            )
            if !activeInjuries.isEmpty {
                adapted = InjuryAdaptationEngine.adaptProgram(adapted, activeInjuries: activeInjuries)
            }
            program = adapted
        }
        activeProgram = program
        if let adapted = activeProgram {
            nextSession = findNextSession(in: adapted, enrollment: enrollment)
        }
    }

    private func loadWODAndRecentWorkouts(modelContext: ModelContext) async {
        let allWODs = (try? await wodRepo.fetchWODs()) ?? []
        todayWOD = Self.findTodayWOD(from: allWODs)

        let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)
        let allWorkouts = (try? workoutRepo.fetchWorkouts()) ?? []
        recentWorkouts = Array(allWorkouts.prefix(10))
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    static func findTodayWOD(from wods: [WOD], now: Date = .now) -> WOD? {
        let todayString = dateFormatter.string(from: now)
        return wods.first { $0.date == todayString }
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

    var isAtLastSession: Bool {
        guard let enrollment = activeEnrollment, let program = activeProgram else { return false }
        let next = Self.nextPosition(currentWeek: enrollment.currentWeek, currentDay: enrollment.currentDay, program: program)
        return next.week == enrollment.currentWeek && next.day == enrollment.currentDay
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
