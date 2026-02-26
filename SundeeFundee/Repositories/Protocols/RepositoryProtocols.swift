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
    func saveOneRepMax(_ max: OneRepMax) throws
    func fetchOneRepMaxes() throws -> [OneRepMax]
    func fetchOneRepMax(exercise: String) throws -> OneRepMax?
    func savePersonalRecord(_ pr: PersonalRecord) throws
    func fetchPersonalRecords() throws -> [PersonalRecord]
    func fetchPersonalRecords(exercise: String) throws -> [PersonalRecord]
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

// MARK: - BenchmarkRepository

protocol BenchmarkRepository {
    func save(_ benchmark: Benchmark) throws
    func fetchBenchmarks() throws -> [Benchmark]
    func fetchBenchmarks(named name: String) throws -> [Benchmark]
    func delete(_ benchmark: Benchmark) throws
}

// MARK: - ProgramRepository

protocol ProgramRepository: Sendable {
    func fetchPrograms() async throws -> [Program]
    func fetchProgram(id: String) async throws -> Program?
}
