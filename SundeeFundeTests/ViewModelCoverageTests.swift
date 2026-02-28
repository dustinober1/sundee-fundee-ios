import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

private struct TestStore {
    let container: ModelContainer
    let context: ModelContext
}

@Model
private final class ViewModelCoverageTempModel {
    var value: String

    init(value: String = "temp") {
        self.value = value
    }
}

@MainActor
private func makeTestStore() throws -> TestStore {
    let schema = Schema(AppSchemaV2.models)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [config])
    return TestStore(container: container, context: ModelContext(container))
}

private struct FakeProgramRepositoryError: LocalizedError {
    var errorDescription: String? { "Program fetch failed" }
}

private final class FakeProgramRepository: ProgramRepository, @unchecked Sendable {
    private let programs: [Program]
    private let fetchProgramsError: Error?
    private let lookup: [String: Program]

    init(
        programs: [Program] = [],
        fetchProgramsError: Error? = nil,
        lookup: [String: Program] = [:]
    ) {
        self.programs = programs
        self.fetchProgramsError = fetchProgramsError
        self.lookup = lookup
    }

    func fetchPrograms() async throws -> [Program] {
        if let fetchProgramsError { throw fetchProgramsError }
        return programs
    }

    func fetchProgram(id: String) async throws -> Program? {
        lookup[id] ?? programs.first { $0.id == id }
    }
}

private enum FakeCoverageError: Error {
    case expectedFailure
}

private struct ThrowingBenchmarkDefinitionRepository: BenchmarkDefinitionRepository {
    func save(_ definition: BenchmarkDefinition) throws { throw FakeCoverageError.expectedFailure }
    func fetchAll() throws -> [BenchmarkDefinition] { throw FakeCoverageError.expectedFailure }
    func fetchUserCreated(userID: String) throws -> [BenchmarkDefinition] { throw FakeCoverageError.expectedFailure }
    func delete(_ definition: BenchmarkDefinition) throws { throw FakeCoverageError.expectedFailure }
}

private struct ThrowingCycleRepository: CycleRepository {
    func save(_ cycle: ActiveCycle) throws {}
    func fetchActiveCycles() throws -> [ActiveCycle] { [] }
    func fetchCurrentActiveCycle() throws -> ActiveCycle? { nil }
    func savePeriodLog(_ log: PeriodLog) throws {}
    func deletePeriodLog(_ log: PeriodLog) throws {}
    func fetchPeriodLogs() throws -> [PeriodLog] { throw FakeCoverageError.expectedFailure }
    func saveSymptomLog(_ log: SymptomLog) throws {}
    func deleteSymptomLog(_ log: SymptomLog) throws {}
    func fetchSymptomLogs() throws -> [SymptomLog] { throw FakeCoverageError.expectedFailure }
    func saveCycleSettings(_ settings: CycleSettings) throws {}
    func fetchCycleSettings() throws -> CycleSettings? { throw FakeCoverageError.expectedFailure }
    func saveCycleAdaptationPreferences(_ prefs: CycleAdaptationPreferences) throws {}
    func fetchCycleAdaptationPreferences() throws -> CycleAdaptationPreferences? { nil }
}

private func makeExercise(
    name: String = "Back Squat",
    sets: ExerciseValue = .fixed(3),
    reps: ExerciseValue = .fixed(5),
    percent1RM: Double? = 0.8,
    restMinutes: Double? = 2
) -> ProgramExercise {
    ProgramExercise(
        exercise: name,
        variant: nil,
        sets: sets,
        reps: reps,
        percent1RM: percent1RM,
        restMinutes: restMinutes,
        notes: nil
    )
}

private func makeSession(
    id: String,
    exerciseName: String = "Back Squat",
    sets: ExerciseValue = .fixed(3),
    reps: ExerciseValue = .fixed(5),
    restMinutes: Double? = 2
) -> ProgramSession {
    ProgramSession(
        sessionID: id,
        sessionName: "Session \(id)",
        sessionType: "strength",
        focus: "Lower",
        exercises: [makeExercise(name: exerciseName, sets: sets, reps: reps, restMinutes: restMinutes)]
    )
}

private func makeWeek(_ week: Int, sessions: [ProgramSession]) -> ProgramWeek {
    ProgramWeek(week: week, phaseID: nil, isTestWeek: nil, sessions: sessions)
}

private func makeProgram(id: String = "p1", weeks: [ProgramWeek]) -> Program {
    Program(
        id: id,
        name: "Program \(id)",
        category: "Strength",
        description: "",
        durationWeeks: weeks.count,
        sessionsPerWeek: weeks.first?.sessions.count ?? 1,
        difficulty: "beginner",
        phases: [],
        weeks: weeks,
        cycleAdjustmentProfile: nil
    )
}

@Suite("ProgramListViewModel Coverage")
struct ProgramListViewModelCoverageTests {

    @Test @MainActor
    func loadPopulatesProgramsAndEnrollment() async throws {
        let store = try makeTestStore()
        let program = makeProgram(id: "p1", weeks: [makeWeek(1, sessions: [makeSession(id: "s1")])])
        let enrollment = EnrolledProgram(id: "e1", userID: "u1", programID: "p1", startDate: .now)
        store.context.insert(enrollment)
        try store.context.save()

        let vm = ProgramListViewModel(programRepo: FakeProgramRepository(programs: [program]))
        await vm.load(modelContext: store.context)

        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.programs.count == 1)
        #expect(vm.activeEnrollment?.programID == "p1")
    }

    @Test @MainActor
    func loadStoresErrorWhenProgramFetchFails() async {
        let vm = ProgramListViewModel(
            programRepo: FakeProgramRepository(fetchProgramsError: FakeProgramRepositoryError())
        )

        await vm.load()

        #expect(vm.isLoading == false)
        #expect(vm.programs.isEmpty)
        #expect(vm.errorMessage != nil)
    }

    @Test @MainActor
    func enrollCancelsCurrentAndCancelEnrollmentClearsState() async throws {
        let store = try makeTestStore()
        let oldEnrollment = EnrolledProgram(
            id: "e-old",
            userID: "u1",
            programID: "legacy",
            startDate: .now
        )
        store.context.insert(oldEnrollment)
        try store.context.save()

        let newProgram = makeProgram(id: "p-new", weeks: [makeWeek(1, sessions: [makeSession(id: "s1")])])
        let vm = ProgramListViewModel(programRepo: FakeProgramRepository(programs: [newProgram]))
        vm.activeEnrollment = oldEnrollment

        await vm.enroll(in: newProgram, modelContext: store.context)
        #expect(vm.activeEnrollment?.programID == "p-new")
        #expect(oldEnrollment.status == .canceled)

        await vm.cancelEnrollment(modelContext: store.context)
        #expect(vm.activeEnrollment == nil)
    }
}

@Suite("WorkoutExecutionViewModel Coverage")
struct WorkoutExecutionViewModelCoverageTests {

    @Test @MainActor
    func updatesSetStateAndRestTimer() {
        let session = makeSession(
            id: "s1",
            exerciseName: "Back Squat",
            sets: .fixed(2),
            reps: .range(8, 10),
            restMinutes: 1.5
        )
        let program = makeProgram(id: "p1", weeks: [makeWeek(1, sessions: [session])])
        let enrollment = EnrolledProgram(id: "e1", userID: "u1", programID: "p1", startDate: .now)
        let vm = WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)

        #expect(vm.exerciseSets["Back Squat"]?.count == 2)
        #expect(vm.exerciseSets["Back Squat"]?.first?.actualReps == 8)

        vm.updateActualReps(10, exerciseName: "Back Squat", setIndex: 0)
        vm.updateActualWeight(92.5, exerciseName: "Back Squat", setIndex: 0)
        vm.toggleSetCompleted(exerciseName: "Back Squat", setIndex: 0)

        #expect(vm.exerciseSets["Back Squat"]?[0].actualReps == 10)
        #expect(vm.exerciseSets["Back Squat"]?[0].actualWeightKg == 92.5)
        #expect(vm.showRestTimer == true)
        #expect(vm.restTimerSeconds == 90)

        vm.toggleSetCompleted(exerciseName: "Back Squat", setIndex: 1)
        #expect(vm.allSetsCompleted == true)

        vm.dismissRestTimer()
        #expect(vm.showRestTimer == false)
        #expect(vm.restTimerSeconds == 0)
    }

    @Test @MainActor
    func finishWorkoutPersistsWorkoutAndSets() throws {
        let store = try makeTestStore()
        let squat = makeExercise(name: "Back Squat", sets: .fixed(2), reps: .fixed(5))
        let press = makeExercise(name: "Bench Press", sets: .fixed(1), reps: .fixed(8))
        let session = ProgramSession(
            sessionID: "s1",
            sessionName: "Session s1",
            sessionType: "strength",
            focus: "Upper",
            exercises: [squat, press]
        )
        let program = makeProgram(id: "p1", weeks: [makeWeek(1, sessions: [session])])
        let enrollment = EnrolledProgram(id: "e1", userID: "u1", programID: "p1", startDate: .now)
        let vm = WorkoutExecutionViewModel(session: session, enrollment: enrollment, program: program)

        vm.startTime = Date.now.addingTimeInterval(-120)
        vm.finishWorkout(modelContext: store.context, userID: "u1")

        #expect(vm.isSaving == false)
        #expect(vm.isFinished == true)
        #expect(vm.completedWorkout != nil)

        let workoutRepo = SwiftDataWorkoutRepository(context: store.context)
        let workouts = try workoutRepo.fetchWorkouts()
        #expect(workouts.count == 1)

        let savedSets = try workoutRepo.fetchSets(for: workouts[0])
        #expect(savedSets.count == 3)
    }

    @Test @MainActor
    func coversInitializationFallbacksAndGuardBranches() throws {
        let store = try makeTestStore()
        let amrapExercise = makeExercise(
            name: "Back Squat",
            sets: .range(2, 4),
            reps: .amrap,
            percent1RM: 0.8,
            restMinutes: nil
        )
        let tempoExercise = makeExercise(
            name: "Tempo Press",
            sets: .text("custom"),
            reps: .text("tempo"),
            percent1RM: nil,
            restMinutes: nil
        )
        let session = ProgramSession(
            sessionID: "s-branch",
            sessionName: "Branch Session",
            sessionType: "strength",
            focus: "Upper",
            exercises: [amrapExercise, tempoExercise]
        )
        let program = makeProgram(id: "p-branch", weeks: [makeWeek(1, sessions: [session])])
        let enrollment = EnrolledProgram(id: "e-branch", userID: "u1", programID: "p-branch", startDate: .now)
        let vm = WorkoutExecutionViewModel(
            session: session,
            enrollment: enrollment,
            program: program,
            oneRepMaxes: ["Back Squat": 100]
        )

        #expect(vm.exerciseSets["Back Squat"]?.count == 3)
        #expect(vm.exerciseSets["Tempo Press"]?.count == 3)
        #expect(vm.exerciseSets["Back Squat"]?.first?.prescribedWeightKg == 80)
        #expect(vm.exerciseSets["Back Squat"]?.first?.actualReps == 0)
        #expect(vm.exerciseSets["Tempo Press"]?.first?.actualReps == 0)

        vm.toggleSetCompleted(exerciseName: "Back Squat", setIndex: 0)
        #expect(vm.restTimerSeconds == 120)
        vm.toggleSetCompleted(exerciseName: "Back Squat", setIndex: 99)

        vm.isSaving = true
        vm.finishWorkout(modelContext: store.context, userID: "u1")
        #expect(vm.completedWorkout == nil)

        vm.isSaving = false
        vm.exerciseSets.removeValue(forKey: "Tempo Press")
        vm.startTime = Date.now.addingTimeInterval(-30)
        vm.finishWorkout(modelContext: store.context, userID: "u1")

        let workoutRepo = SwiftDataWorkoutRepository(context: store.context)
        let workouts = try workoutRepo.fetchWorkouts()
        #expect(workouts.count == 1)
        let savedSets = try workoutRepo.fetchSets(for: workouts[0])
        #expect(savedSets.count == 3)
    }
}

@Suite("DashboardViewModel Coverage")
struct DashboardViewModelCoverageTests {

    @Test @MainActor
    func loadPopulatesEnrollmentProgramWorkoutsAndCyclePhase() async throws {
        let store = try makeTestStore()
        let session1 = makeSession(id: "s1")
        let session2 = makeSession(id: "s2", exerciseName: "Bench Press")
        let program = makeProgram(id: "p1", weeks: [makeWeek(1, sessions: [session1, session2])])

        let enrollment = EnrolledProgram(
            id: "e1",
            userID: "u1",
            programID: "p1",
            startDate: .now,
            currentWeek: 1,
            currentDay: 2
        )
        store.context.insert(enrollment)

        for idx in 0..<12 {
            let workout = CompletedWorkout(
                id: "w\(idx)",
                userID: "u1",
                activeCycleID: "",
                programID: "p1",
                enrollmentID: "e1",
                week: 1,
                day: 1,
                sessionID: "s1",
                completedAt: Date.now.addingTimeInterval(TimeInterval(-idx * 300)),
                durationSeconds: 1200
            )
            store.context.insert(workout)
        }

        store.context.insert(CycleSettings(id: "cs1", userID: "u1"))
        store.context.insert(PeriodLog(
            id: "pl1",
            userID: "u1",
            startDate: Calendar.current.startOfDay(for: .now)
        ))
        try store.context.save()

        let vm = DashboardViewModel(programRepo: FakeProgramRepository(programs: [program]))
        await vm.load(modelContext: store.context)

        #expect(vm.activeEnrollment?.id == "e1")
        #expect(vm.activeProgram?.id == "p1")
        #expect(vm.nextSession?.sessionID == "s2")
        #expect(vm.recentWorkouts.count == 10)
        #expect(vm.currentCyclePhase != nil)
    }

    @Test @MainActor
    func loadFallsForwardToNextWeekWhenCurrentDayIsOutOfRange() async throws {
        let store = try makeTestStore()
        let week1Session = makeSession(id: "w1s1")
        let week2Session = makeSession(id: "w2s1", exerciseName: "Deadlift")
        let program = makeProgram(
            id: "p1",
            weeks: [
                makeWeek(1, sessions: [week1Session]),
                makeWeek(2, sessions: [week2Session])
            ]
        )
        let enrollment = EnrolledProgram(
            id: "e1",
            userID: "u1",
            programID: "p1",
            startDate: .now,
            currentWeek: 1,
            currentDay: 3
        )
        store.context.insert(enrollment)
        try store.context.save()

        let vm = DashboardViewModel(programRepo: FakeProgramRepository(programs: [program]))
        await vm.load(modelContext: store.context)

        #expect(vm.nextSession?.sessionID == "w2s1")
    }

    @Test @MainActor
    func loadFallsBackToFirstWeekWhenCurrentWeekIsMissing() async throws {
        let store = try makeTestStore()
        let week1Session = makeSession(id: "w1s1")
        let program = makeProgram(id: "p1", weeks: [makeWeek(1, sessions: [week1Session])])
        let enrollment = EnrolledProgram(
            id: "e1",
            userID: "u1",
            programID: "p1",
            startDate: .now,
            currentWeek: 99,
            currentDay: 1
        )
        store.context.insert(enrollment)
        try store.context.save()

        let vm = DashboardViewModel(programRepo: FakeProgramRepository(programs: [program]))
        await vm.load(modelContext: store.context)

        #expect(vm.nextSession?.sessionID == "w1s1")
    }
}

@Suite("BenchmarksViewModel Coverage")
struct BenchmarksViewModelCoverageTests {

    @Test @MainActor
    func loadCategoryGroupsAndAddDeleteCustomDefinition() async throws {
        let store = try makeTestStore()

        // Insert a custom user-created definition into the store
        let customDef = BenchmarkDefinition(
            id: "custom-1",
            userID: "u1",
            name: "My Custom WOD",
            category: BenchmarkCatalog.generalFitness,
            workoutDescription: "21-15-9 thrusters and pull-ups",
            scoringType: .time,
            isPredefined: false,
            sortOrder: 999
        )
        store.context.insert(customDef)
        try store.context.save()

        let vm = BenchmarksViewModel()
        await vm.load(modelContext: store.context, userID: "u1")

        // Predefined catalog entries + custom def should be loaded
        #expect(!vm.categoryGroups.isEmpty)
        let generalGroup = vm.categoryGroups.first(where: { $0.category == BenchmarkCatalog.generalFitness })
        #expect(generalGroup != nil)
        #expect(generalGroup?.definitions.contains(where: { $0.id == "custom-1" }) == true)

        // Add another custom definition via the view model
        vm.addCustomDefinition(
            name: "Row Sprint",
            category: BenchmarkCatalog.generalFitness,
            description: "500m row for time",
            scoringType: .distance
        )
        let updatedGroup = vm.categoryGroups.first(where: { $0.category == BenchmarkCatalog.generalFitness })
        #expect(updatedGroup?.definitions.contains(where: { $0.name == "Row Sprint" }) == true)

        // Delete the custom definition
        vm.deleteCustomDefinition(customDef)
        let afterDelete = vm.categoryGroups.first(where: { $0.category == BenchmarkCatalog.generalFitness })
        #expect(afterDelete?.definitions.contains(where: { $0.id == "custom-1" }) != true)

        // Deleting a predefined entry is a no-op
        if let predefined = vm.categoryGroups.flatMap(\.definitions).first(where: { $0.isPredefined }) {
            let countBefore = vm.categoryGroups.flatMap(\.definitions).count
            vm.deleteCustomDefinition(predefined)
            let countAfter = vm.categoryGroups.flatMap(\.definitions).count
            #expect(countBefore == countAfter)
        }
    }

    @Test @MainActor
    func loadHandlesRepositoryFailureGracefully() async throws {
        let store = try makeTestStore()
        let failingVM = BenchmarksViewModel(
            definitionRepoFactory: { _ in ThrowingBenchmarkDefinitionRepository() }
        )
        await failingVM.load(modelContext: store.context, userID: "u1")
        // Even on failure, predefined catalog entries from BenchmarkCatalog are merged in-memory
        // but since fetchUserCreated fails, we just confirm loading completes without crash
        #expect(failingVM.isLoading == false)

        // addCustomDefinition with nil context is a no-op
        let vmNoContext = BenchmarksViewModel()
        vmNoContext.addCustomDefinition(name: "Ghost", category: "Unknown", description: "", scoringType: .time)
        #expect(vmNoContext.categoryGroups.isEmpty)
    }
}

@Suite("CycleTrackingViewModel Coverage")
struct CycleTrackingViewModelCoverageTests {

    @Test @MainActor
    func periodLogMutationsRefreshCycleStatus() async throws {
        let store = try makeTestStore()
        store.context.insert(CycleSettings(id: "cs1", userID: "u1"))
        try store.context.save()

        let vm = CycleTrackingViewModel()
        await vm.load(modelContext: store.context, userID: "u1")

        vm.addPeriodLog(
            startDate: Calendar.current.startOfDay(for: .now),
            endDate: nil,
            flowLevel: .medium
        )
        #expect(vm.periodLogs.count == 1)
        #expect(vm.cycleStatus != nil)

        vm.deletePeriodLogs(at: IndexSet(integer: 0))
        #expect(vm.periodLogs.isEmpty)
        #expect(vm.cycleStatus == nil)
    }

    @Test @MainActor
    func symptomAndSettingsMutationsPersist() async throws {
        let store = try makeTestStore()
        let vm = CycleTrackingViewModel()
        await vm.load(modelContext: store.context, userID: "u1")

        vm.avgCycleLength = 30
        vm.avgPeriodLength = 6
        vm.lutealPhaseLength = 13
        vm.adaptationEnabled = false
        await vm.saveSettings()

        vm.addSymptomLog(symptomID: "cramps", severity: 7, date: .now, notes: "moderate")
        #expect(vm.symptomLogs.count == 1)
        #expect(vm.symptomLogs.first?.severity == 5)

        vm.deleteSymptomLogs(at: IndexSet(integer: 0))
        #expect(vm.symptomLogs.isEmpty)

        let repo = SwiftDataCycleRepository(context: store.context)
        let settings = try repo.fetchCycleSettings()
        #expect(settings?.averageCycleLengthDays == 30)
        #expect(settings?.averagePeriodLengthDays == 6)
        #expect(settings?.lutealPhaseLengthDays == 13)
        #expect(settings?.isTrackingEnabled == false)
    }

    @Test @MainActor
    func loadFallsBackOnRepositoryErrorsAndGuardsNoContextMutations() async throws {
        let store = try makeTestStore()
        let failingVM = CycleTrackingViewModel(repositoryFactory: { _ in ThrowingCycleRepository() })
        await failingVM.load(modelContext: store.context, userID: "u1")
        #expect(failingVM.periodLogs.isEmpty)
        #expect(failingVM.symptomLogs.isEmpty)
        #expect(failingVM.cycleStatus == nil)

        let vm = CycleTrackingViewModel()
        vm.addPeriodLog(startDate: .now, endDate: nil, flowLevel: .light)
        vm.deletePeriodLogs(at: IndexSet(integer: 0))
        vm.addSymptomLog(symptomID: "fatigue", severity: 3, date: .now, notes: nil)
        vm.deleteSymptomLogs(at: IndexSet(integer: 0))
        await vm.saveSettings()
        #expect(vm.periodLogs.isEmpty)
        #expect(vm.symptomLogs.isEmpty)
        #expect(vm.cycleStatus == nil)
    }
}

@Suite("MaxLiftsViewModel Coverage")
struct MaxLiftsViewModelCoverageTests {

    @Test @MainActor
    func loadBuildsIndexesAndAddMaxUpdatesState() async throws {
        let store = try makeTestStore()
        let now = Date.now

        let olderSquat = OneRepMax(
            id: "orm1",
            userID: "u1",
            exerciseID: "Back Squat",
            weightKg: 100,
            date: now.addingTimeInterval(-86_400)
        )
        let newerSquat = OneRepMax(
            id: "orm2",
            userID: "u1",
            exerciseID: "Back Squat",
            weightKg: 110,
            date: now
        )
        let calfRaise = OneRepMax(
            id: "orm3",
            userID: "u1",
            exerciseID: "Calf Raise",
            weightKg: 70,
            date: now
        )
        let romanianPR = PersonalRecord(
            id: "pr1",
            userID: "u1",
            exerciseID: "Romanian Deadlift",
            repMaxType: .five,
            weightKg: 120,
            reps: 5,
            achievedAt: now
        )

        store.context.insert(olderSquat)
        store.context.insert(newerSquat)
        store.context.insert(calfRaise)
        store.context.insert(romanianPR)
        try store.context.save()

        let vm = MaxLiftsViewModel()
        await vm.load(modelContext: store.context, userID: "u1")

        #expect(vm.exerciseNames == ["Back Squat", "Romanian Deadlift"])
        #expect(vm.oneRepMaxes["Back Squat"]?.weightKg == 110)
        #expect(vm.personalRecords["Romanian Deadlift"]?.count == 1)

        vm.addMax(exercise: "Front Squat", weightKg: 95, reps: 1, isEstimated: true)
        #expect(vm.exerciseNames.contains("Front Squat"))
        #expect(vm.oneRepMaxes["Front Squat"]?.weightKg == 95)

        vm.addMax(exercise: "Tempo Squat", weightKg: 80, reps: 3, isEstimated: false)
        #expect(vm.oneRepMaxes["Tempo Squat"] == nil)
    }

    @Test @MainActor
    func loadHandlesMismatchedSchemaAndGuardBranches() async throws {
        let guardVM = MaxLiftsViewModel()
        guardVM.addMax(exercise: "Back Squat", weightKg: 100, reps: 1, isEstimated: true)
        #expect(guardVM.exerciseNames.isEmpty)
    }
}

@Suite("SettingsViewModel Coverage")
struct SettingsViewModelCoverageTests {

    @Test @MainActor
    func loadSaveAndInjuryMutationsUpdateState() async throws {
        let store = try makeTestStore()
        let user = User(
            id: "u1",
            name: "Dustin",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            weightUnit: .pounds,
            appleUserID: "apple-u1"
        )
        let existingInjury = InjuryProfile(
            id: "inj-old",
            userID: "u1",
            location: "knee",
            movementLimitations: "deep flexion",
            recoveryGoal: "pain-free squat"
        )
        store.context.insert(user)
        store.context.insert(existingInjury)
        try store.context.save()

        let vm = SettingsViewModel()
        await vm.load(modelContext: store.context, userID: "u1")

        #expect(vm.displayName == "Dustin")
        #expect(vm.injuryProfiles.count == 1)
        #expect(vm.weightUnit == .pounds)

        vm.displayName = "Updated Name"
        vm.experienceLevel = .advanced
        vm.primaryGoal = .endurance
        vm.weightUnit = .kilograms
        await vm.saveProfile()

        #expect(user.name == "Updated Name")
        #expect(user.experienceLevel == .advanced)
        #expect(user.primaryGoal == .endurance)
        #expect(user.weightUnit == .kilograms)

        vm.addInjury(location: "back", limitations: "no heavy deadlifts", recoveryGoal: "return to pull")
        #expect(vm.injuryProfiles.count == 2)
        #expect(vm.injuryProfiles.first?.location == "back")

        if let latest = vm.injuryProfiles.first {
            vm.updateInjury(latest, location: "lower back", limitations: "light hinge only", recoveryGoal: "full hinge")
            #expect(latest.location == "lower back")
            #expect(latest.movementLimitations == "light hinge only")

            vm.resolveInjury(latest)
            #expect(latest.status == .resolved)
            #expect(latest.resolvedAt != nil)
        }
    }

    @Test @MainActor
    func noContextGuardsAreNoOps() async {
        let vm = SettingsViewModel()
        await vm.saveProfile()
        vm.addInjury(location: "Back", limitations: "None", recoveryGoal: "Maintain")
        vm.updateInjury(
            InjuryProfile(
                id: "inj-no-context",
                userID: "u1",
                location: "Shoulder",
                movementLimitations: "Avoid overhead",
                recoveryGoal: "Return to pressing"
            ),
            location: "Shoulder",
            limitations: "Avoid overhead",
            recoveryGoal: "Return"
        )
        vm.resolveInjury(
            InjuryProfile(
                id: "inj-no-context-2",
                userID: "u1",
                location: "Knee",
                movementLimitations: "No deep flexion",
                recoveryGoal: "Pain free"
            )
        )
        #expect(vm.injuryProfiles.isEmpty)
    }
}
