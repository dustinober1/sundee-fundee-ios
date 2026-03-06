import Foundation

// MARK: - UserRepository

protocol UserRepository {
    func save(_ user: User) throws
    func fetchCurrentUser() throws -> User?
    func delete(_ user: User) throws
}

// MARK: - WorkoutRepository

protocol WorkoutRepository {
    func save(_ workout: CompletedWorkout) throws
    func fetchWorkouts() throws -> [CompletedWorkout]
    func fetchWorkout(id: UUID) throws -> CompletedWorkout?
    func delete(_ workout: CompletedWorkout) throws
    func deleteWorkoutWithSets(_ workout: CompletedWorkout) throws
    func save(_ set: CompletedSet) throws
    func fetchSets(for workout: CompletedWorkout) throws -> [CompletedSet]
}

// MARK: - CycleRepository

protocol CycleRepository {
    func save(_ cycle: ActiveCycle) throws
    func fetchActiveCycles() throws -> [ActiveCycle]
    func fetchCurrentActiveCycle() throws -> ActiveCycle?
    func savePeriodLog(_ log: PeriodLog) throws
    func deletePeriodLog(_ log: PeriodLog) throws
    func fetchPeriodLogs() throws -> [PeriodLog]
    func saveSymptomLog(_ log: SymptomLog) throws
    func deleteSymptomLog(_ log: SymptomLog) throws
    func fetchSymptomLogs() throws -> [SymptomLog]
    func saveCycleSettings(_ settings: CycleSettings) throws
    func fetchCycleSettings() throws -> CycleSettings?
    func saveCycleAdaptationPreferences(_ prefs: CycleAdaptationPreferences) throws
    func fetchCycleAdaptationPreferences() throws -> CycleAdaptationPreferences?
}

// MARK: - LiftRepository

protocol LiftRepository {
    func saveLiftMax(_ max: LiftMax) throws
    func fetchLiftMaxes() throws -> [LiftMax]
    func fetchLiftMax(exercise: String) throws -> LiftMax?
    func fetchLiftMaxes(exercise: String) throws -> [LiftMax]
    func saveOneRepMax(_ max: OneRepMax) throws
    func fetchOneRepMaxes() throws -> [OneRepMax]
    func fetchOneRepMax(exercise: String) throws -> OneRepMax?
    func savePersonalRecord(_ pr: PersonalRecord) throws
    func fetchPersonalRecords() throws -> [PersonalRecord]
    func fetchPersonalRecords(exercise: String) throws -> [PersonalRecord]
    func saveConditioningPR(_ pr: ConditioningPR) throws
    func fetchConditioningPR(exercise: String) throws -> ConditioningPR?
    func fetchAllConditioningPRs() throws -> [ConditioningPR]
}

// MARK: - EnrolledProgramRepository

protocol EnrolledProgramRepository {
    func save(_ enrollment: EnrolledProgram) throws
    func fetchAllEnrollments() throws -> [EnrolledProgram]
    func fetchActiveEnrollment() throws -> EnrolledProgram?
    func fetchLatestCanceledEnrollment(programId: String) throws -> EnrolledProgram?
    func updateProgress(enrollment: EnrolledProgram, week: Int, day: Int) throws
    func complete(_ enrollment: EnrolledProgram) throws
    func cancel(_ enrollment: EnrolledProgram) throws
    func delete(_ enrollment: EnrolledProgram) throws
}

// MARK: - BenchmarkDefinitionRepository

protocol BenchmarkDefinitionRepository {
    func save(_ definition: BenchmarkDefinition) throws
    func fetchAll() throws -> [BenchmarkDefinition]
    func fetchUserCreated(userID: String) throws -> [BenchmarkDefinition]
    func delete(_ definition: BenchmarkDefinition) throws
}

// MARK: - BenchmarkResultRepository

protocol BenchmarkResultRepository {
    func save(_ result: BenchmarkResult) throws
    func fetchResults(forDefinitionID definitionID: String) throws -> [BenchmarkResult]
    func delete(_ result: BenchmarkResult) throws
}

// MARK: - InjuryRepository

protocol InjuryRepository {
    func fetchActiveInjuries(userID: String) throws -> [InjuryProfile]
    func fetchAll(userID: String) throws -> [InjuryProfile]
    func save(_ injury: InjuryProfile) throws
    func resolve(_ injury: InjuryProfile) throws
}

// MARK: - PainLogRepository

protocol PainLogRepository {
    func save(_ log: PainLog) throws
    func fetchLogs(injuryProfileID: String) throws -> [PainLog]
    func fetchAllLogs() throws -> [PainLog]
}

// MARK: - ReadinessRepository

struct ReadinessMetrics {
    let sleepHours: Double?
    let hrvRMSSD: Double?
    let restingHeartRate: Double?

    /// Computes a 1-10 readiness score from available metrics.
    var readinessScore: Double? {
        var components: [Double] = []

        if let sleep = sleepHours {
            // 7-9 hours is optimal; scale 0-10
            components.append(min(10, max(0, (sleep / 9.0) * 10)))
        }
        if let hrv = hrvRMSSD {
            // Higher HRV is better; typical range 20-100ms
            components.append(min(10, max(0, (hrv / 80.0) * 10)))
        }
        if let rhr = restingHeartRate {
            // Lower RHR is better; typical range 50-80
            components.append(min(10, max(0, ((90 - rhr) / 40.0) * 10)))
        }

        guard !components.isEmpty else { return nil }
        return components.reduce(0, +) / Double(components.count)
    }
}

protocol ReadinessRepository: Sendable {
    func fetchLatestMetrics() async throws -> ReadinessMetrics
}

// MARK: - ProgramRepository

protocol ProgramRepository: Sendable {
    func fetchPrograms() async throws -> [Program]
    func fetchProgram(id: String) async throws -> Program?
}

// MARK: - WODRepository

protocol WODRepository: Sendable {
    func fetchWODs() async throws -> [WOD]
}

// MARK: - AIWorkoutServiceProtocol

protocol AIWorkoutServiceProtocol: Sendable {
    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout
    func fetchHistory(userID: String) async throws -> [GeneratedWorkout]
    func toggleFavorite(workoutID: String, isFavorite: Bool) async throws
    func fetchFavorites(userID: String) async throws -> [GeneratedWorkout]
}
