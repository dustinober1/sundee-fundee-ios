import Testing
import Foundation
import SwiftData
import CloudKit
@testable import SundeeFundee

@Suite("Repository Coverage")
struct RepositoryCoverageTests {
    private static let baseTime = Date(timeIntervalSince1970: 1_700_000_000)

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Self.baseTime.addingTimeInterval(seconds)
    }

    private func makeProgramRecord() -> CKRecord {
        let weeksJSON = """
        [{"week":1,"phaseId":"base","isTestWeek":false,"sessions":[{"sessionId":"s1","sessionName":"Day 1","sessionType":"strength","focus":"Lower","exercises":[{"exercise":"Back Squat","variant":null,"sets":3,"reps":5,"percent1RM":0.8,"restMinutes":3,"notes":null}]}]}]
        """
        let phasesJSON = """
        [{"id":"base","name":"Base","goal":"Build","weekRange":[1]}]
        """
        let profileJSON = """
        {"fallbackPhase":"luteal","lowConfidenceScale":0.6,"phaseSettings":{"ovulation":{"loadMultiplier":1.1,"setsMultiplier":1.0,"repsMultiplier":0.9}}}
        """

        let record = CKRecord(recordType: "Program")
        record["id"] = "program-1" as NSString
        record["name"] = "Squat Peak" as NSString
        record["category"] = "Strength" as NSString
        record["description"] = "Cycle-aware squats" as NSString
        record["durationWeeks"] = NSNumber(value: 12)
        record["sessionsPerWeek"] = NSNumber(value: 3)
        record["difficulty"] = "intermediate" as NSString
        record["weeksJSON"] = weeksJSON as NSString
        record["phasesJSON"] = phasesJSON as NSString
        record["cycleAdjustmentProfileJSON"] = profileJSON as NSString
        return record
    }

    @Test
    @MainActor
    func userRepositorySaveFetchDelete() throws {
        let container = try makeContainer()
        let repository = SwiftDataUserRepository(context: container.mainContext)

        let older = User(
            id: "user-older",
            name: "Older",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .female,
            appleUserID: "apple-older",
            createdAt: date(1)
        )
        let newer = User(
            id: "user-newer",
            name: "Newer",
            experienceLevel: .intermediate,
            primaryGoal: .hypertrophy,
            gender: .male,
            appleUserID: "apple-newer",
            createdAt: date(2)
        )

        try repository.save(older)
        try repository.save(newer)

        #expect(try repository.fetchCurrentUser()?.id == "user-newer")

        try repository.delete(newer)
        #expect(try repository.fetchCurrentUser()?.id == "user-older")
    }

    @Test
    @MainActor
    func workoutRepositoryFetchesByIdAndSortsSets() throws {
        let container = try makeContainer()
        let repository = SwiftDataWorkoutRepository(context: container.mainContext)

        let olderID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let newerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let olderWorkout = CompletedWorkout(
            id: olderID.uuidString,
            userID: "u1",
            activeCycleID: "ac1",
            programID: "p1",
            week: 1,
            day: 1,
            sessionID: "s1",
            completedAt: date(10)
        )
        let newerWorkout = CompletedWorkout(
            id: newerID.uuidString,
            userID: "u1",
            activeCycleID: "ac1",
            programID: "p1",
            week: 1,
            day: 2,
            sessionID: "s2",
            completedAt: date(20)
        )

        try repository.save(olderWorkout)
        try repository.save(newerWorkout)

        #expect(try repository.fetchWorkouts().map(\.id) == [newerID.uuidString, olderID.uuidString])
        #expect(try repository.fetchWorkout(id: newerID)?.id == newerID.uuidString)

        try repository.save(CompletedSet(
            id: "set-2",
            userID: "u1",
            workoutID: newerWorkout.id,
            exerciseName: "Back Squat",
            setIndex: 2,
            prescribedReps: "5"
        ))
        try repository.save(CompletedSet(
            id: "set-1",
            userID: "u1",
            workoutID: newerWorkout.id,
            exerciseName: "Back Squat",
            setIndex: 1,
            prescribedReps: "5"
        ))

        #expect(try repository.fetchSets(for: newerWorkout).map(\.setIndex) == [1, 2])

        try repository.delete(olderWorkout)
        #expect((try repository.fetchWorkouts()).count == 1)
    }

    @Test
    @MainActor
    func liftRepositoryReturnsLatestRecords() throws {
        let container = try makeContainer()
        let repository = SwiftDataLiftRepository(context: container.mainContext)

        let liftOld = LiftMax(id: "lift-old", userID: "u1", exerciseID: "Back Squat", weightKg: 100, date: date(10))
        let liftNew = LiftMax(id: "lift-new", userID: "u1", exerciseID: "Back Squat", weightKg: 110, date: date(20))
        let liftOther = LiftMax(id: "lift-other", userID: "u1", exerciseID: "Bench Press", weightKg: 80, date: date(30))
        try repository.saveLiftMax(liftOld)
        try repository.saveLiftMax(liftNew)
        try repository.saveLiftMax(liftOther)

        #expect(try repository.fetchLiftMaxes().map(\.id) == ["lift-other", "lift-new", "lift-old"])
        #expect(try repository.fetchLiftMax(exercise: "Back Squat")?.id == "lift-new")
        #expect(try repository.fetchLiftMaxes(exercise: "Back Squat").map(\.id) == ["lift-new", "lift-old"])
        #expect(try repository.fetchLiftMaxes(exercise: "Bench Press").count == 1)

        let ormOld = OneRepMax(id: "orm-old", userID: "u1", exerciseID: "Back Squat", weightKg: 115, date: date(40))
        let ormNew = OneRepMax(id: "orm-new", userID: "u1", exerciseID: "Back Squat", weightKg: 120, date: date(50))
        try repository.saveOneRepMax(ormOld)
        try repository.saveOneRepMax(ormNew)

        #expect(try repository.fetchOneRepMaxes().map(\.id) == ["orm-new", "orm-old"])
        #expect(try repository.fetchOneRepMax(exercise: "Back Squat")?.id == "orm-new")

        let prOld = PersonalRecord(id: "pr-old", userID: "u1", exerciseID: "Back Squat", repMaxType: .one, weightKg: 120, reps: 1, achievedAt: date(60))
        let prNew = PersonalRecord(id: "pr-new", userID: "u1", exerciseID: "Back Squat", repMaxType: .three, weightKg: 115, reps: 3, achievedAt: date(70))
        let prOther = PersonalRecord(id: "pr-other", userID: "u1", exerciseID: "Bench Press", repMaxType: .one, weightKg: 90, reps: 1, achievedAt: date(80))
        try repository.savePersonalRecord(prOld)
        try repository.savePersonalRecord(prNew)
        try repository.savePersonalRecord(prOther)

        #expect(try repository.fetchPersonalRecords().map(\.id) == ["pr-other", "pr-new", "pr-old"])
        #expect(try repository.fetchPersonalRecords(exercise: "Back Squat").map(\.id) == ["pr-new", "pr-old"])
    }

    @MainActor
    private func makeV7Container() throws -> ModelContainer {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test
    @MainActor
    func conditioningPRRepositorySaveFetchAll() throws {
        let container = try makeV7Container()
        let repository = SwiftDataLiftRepository(context: container.mainContext)

        let pr1 = ConditioningPR(id: "cpr-1", userID: "u1", exerciseID: "Wall Ball", scoringType: .reps, bestValue: 100, achievedAt: date(10))
        let pr2 = ConditioningPR(id: "cpr-2", userID: "u1", exerciseID: "400m Run", scoringType: .time, bestValue: 90, achievedAt: date(20))
        try repository.saveConditioningPR(pr1)
        try repository.saveConditioningPR(pr2)

        #expect(try repository.fetchAllConditioningPRs().map(\.id) == ["cpr-2", "cpr-1"])
        #expect(try repository.fetchConditioningPR(exercise: "Wall Ball")?.id == "cpr-1")
        #expect(try repository.fetchConditioningPR(exercise: "Unknown") == nil)
    }

    @Test
    @MainActor
    func conditioningPRModelAccessors() throws {
        let container = try makeV7Container()
        let pr = ConditioningPR(id: "1", userID: "u", exerciseID: "Wall Ball", scoringType: .reps, bestValue: 100)
        container.mainContext.insert(pr)
        #expect(pr.scoringType == .reps)
        #expect(pr.scoringTypeRaw == "reps")
        pr.scoringType = .time
        #expect(pr.scoringTypeRaw == "time")
    }

    @Test
    @MainActor
    func cycleRepositoryFetchesCurrentAndLatestLogs() throws {
        let container = try makeContainer()
        let repository = SwiftDataCycleRepository(context: container.mainContext)

        let completed = ActiveCycle(
            id: "cycle-completed",
            userID: "u1",
            programID: "p1",
            cycleName: "Completed",
            startDate: date(10),
            currentSessionID: "s1",
            status: .completed
        )
        let active = ActiveCycle(
            id: "cycle-active",
            userID: "u1",
            programID: "p1",
            cycleName: "Active",
            startDate: date(20),
            currentSessionID: "s2",
            status: .active
        )
        try repository.save(completed)
        try repository.save(active)

        #expect(try repository.fetchActiveCycles().map(\.id) == ["cycle-active", "cycle-completed"])
        #expect(try repository.fetchCurrentActiveCycle()?.id == "cycle-active")

        let periodOld = PeriodLog(id: "period-old", userID: "u1", startDate: date(30))
        let periodNew = PeriodLog(id: "period-new", userID: "u1", startDate: date(40))
        try repository.savePeriodLog(periodOld)
        try repository.savePeriodLog(periodNew)
        #expect(try repository.fetchPeriodLogs().map(\.id) == ["period-new", "period-old"])
        try repository.deletePeriodLog(periodOld)
        #expect(try repository.fetchPeriodLogs().map(\.id) == ["period-new"])

        let symptomOld = SymptomLog(id: "symptom-old", userID: "u1", date: date(50), symptomID: "fatigue", severity: 2)
        let symptomNew = SymptomLog(id: "symptom-new", userID: "u1", date: date(60), symptomID: "cramps", severity: 4)
        try repository.saveSymptomLog(symptomOld)
        try repository.saveSymptomLog(symptomNew)
        #expect(try repository.fetchSymptomLogs().map(\.id) == ["symptom-new", "symptom-old"])
        try repository.deleteSymptomLog(symptomOld)
        #expect(try repository.fetchSymptomLogs().map(\.id) == ["symptom-new"])

        let settingsOld = CycleSettings(id: "settings-old", userID: "u1", updatedAt: date(70))
        let settingsNew = CycleSettings(id: "settings-new", userID: "u1", updatedAt: date(80))
        try repository.saveCycleSettings(settingsOld)
        try repository.saveCycleSettings(settingsNew)
        #expect(try repository.fetchCycleSettings()?.id == "settings-new")

        let prefsOld = CycleAdaptationPreferences(id: "prefs-old", userID: "u1", updatedAt: date(90))
        let prefsNew = CycleAdaptationPreferences(id: "prefs-new", userID: "u1", updatedAt: date(100))
        try repository.saveCycleAdaptationPreferences(prefsOld)
        try repository.saveCycleAdaptationPreferences(prefsNew)
        #expect(try repository.fetchCycleAdaptationPreferences()?.id == "prefs-new")
    }

    @Test
    @MainActor
    func enrolledProgramRepositoryHandlesLifecycle() throws {
        let container = try makeContainer()
        let repository = SwiftDataEnrolledProgramRepository(context: container.mainContext)

        let canceledOld = EnrolledProgram(id: "enroll-canceled-old", userID: "u1", programID: "p1", startDate: date(10), status: .canceled)
        let canceledNew = EnrolledProgram(id: "enroll-canceled-new", userID: "u1", programID: "p1", startDate: date(30), status: .canceled)
        let active = EnrolledProgram(id: "enroll-active", userID: "u1", programID: "p2", startDate: date(40), status: .active)
        let otherProgram = EnrolledProgram(id: "enroll-other", userID: "u1", programID: "p3", startDate: date(20), status: .canceled)
        try repository.save(canceledOld)
        try repository.save(active)
        try repository.save(otherProgram)
        try repository.save(canceledNew)

        #expect(try repository.fetchAllEnrollments().map(\.id) == ["enroll-active", "enroll-canceled-new", "enroll-other", "enroll-canceled-old"])
        #expect(try repository.fetchActiveEnrollment()?.id == "enroll-active")
        #expect(try repository.fetchLatestCanceledEnrollment(programId: "p1")?.id == "enroll-canceled-new")

        try repository.updateProgress(enrollment: active, week: 4, day: 2)
        #expect(active.currentWeek == 4)
        #expect(active.currentDay == 2)

        try repository.complete(active)
        #expect(active.status == .completed)
        #expect(active.completedAt != nil)

        let cancelTarget = EnrolledProgram(id: "enroll-cancel-target", userID: "u1", programID: "p4", startDate: date(50), status: .active)
        try repository.save(cancelTarget)
        try repository.cancel(cancelTarget)
        #expect(cancelTarget.status == .canceled)
        #expect(cancelTarget.canceledAt != nil)

        try repository.delete(cancelTarget)
        #expect((try repository.fetchAllEnrollments()).contains { $0.id == cancelTarget.id } == false)
    }

    @Test
    @MainActor
    func benchmarkDefinitionRepositoryFetchesAndDeletes() throws {
        let container = try makeContainer()
        let repository = SwiftDataBenchmarkDefinitionRepository(context: container.mainContext)

        let def1 = BenchmarkDefinition(
            id: "def-1", userID: "u1", name: "Cindy",
            category: "General Fitness", workoutDescription: "20 min AMRAP",
            scoringType: .reps, isPredefined: false, sortOrder: 1
        )
        let def2 = BenchmarkDefinition(
            id: "def-2", userID: "u1", name: "Fran",
            category: "General Fitness", workoutDescription: "21-15-9",
            scoringType: .time, isPredefined: false, sortOrder: 2
        )
        let def3 = BenchmarkDefinition(
            id: "def-3", userID: "u2", name: "Grace",
            category: "Weightlifting", workoutDescription: "30 clean & jerks",
            scoringType: .time, isPredefined: false, sortOrder: 1
        )
        try repository.save(def1)
        try repository.save(def2)
        try repository.save(def3)

        let allDefs = try repository.fetchAll()
        #expect(allDefs.count == 3)
        #expect(allDefs.map(\.id).contains("def-1"))

        let u1Defs = try repository.fetchUserCreated(userID: "u1")
        #expect(u1Defs.count == 2)
        #expect(u1Defs.allSatisfy { $0.userID == "u1" })

        try repository.delete(def2)
        #expect((try repository.fetchAll()).count == 2)
    }

    @Test
    func programRecordDecodingSupportsOptionalMetadata() throws {
        let program = try Program(record: makeProgramRecord())
        #expect(program.id == "program-1")
        #expect(program.weeks.first?.phaseID == "base")
        #expect(program.phases.first?.id == "base")
        #expect(program.cycleAdjustmentProfile?.fallbackPhase == "luteal")
    }

    @Test
    func programRecordDecodingHandlesInvalidOptionalJSON() throws {
        let record = makeProgramRecord()
        record["phasesJSON"] = "not-json" as NSString
        record["cycleAdjustmentProfileJSON"] = "not-json" as NSString

        let program = try Program(record: record)
        #expect(program.phases.isEmpty)
        #expect(program.cycleAdjustmentProfile?.fallbackPhase == nil)
    }

    @Test
    func programRecordDecodingThrowsForMissingRequiredFields() throws {
        let record = CKRecord(recordType: "Program")
        record["id"] = "incomplete" as NSString

        do {
            _ = try Program(record: record)
            Issue.record("Expected missing fields error")
        } catch ProgramDecodingError.missingFields {
            // expected
        }
    }
}
