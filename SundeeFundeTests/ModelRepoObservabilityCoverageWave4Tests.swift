import Testing
import Foundation
import CloudKit
import MetricKit
@testable import SundeeFundee

@Suite("Model/Repo/Observability Coverage Wave 4")
struct ModelRepoObservabilityCoverageWave4Tests {
    private func makeProgram(id: String, name: String) -> Program {
        Program(
            id: id,
            name: name,
            category: "Strength",
            description: "",
            durationWeeks: 1,
            sessionsPerWeek: 1,
            difficulty: "beginner",
            phases: [],
            cycleAdjustmentProfile: nil, weeks: []
        )
    }

    private func makeProgramRecord(
        id: String = "cloud-1",
        name: String = "Cloud Program",
        phasesJSON: String? = nil,
        cycleAdjustmentProfileJSON: String? = nil
    ) -> CKRecord {
        let weeksJSON = """
        [{"week":1,"phaseId":"base","isTestWeek":false,"sessions":[{"sessionId":"s1","sessionName":"Day 1","sessionType":"strength","focus":"Lower","exercises":[{"exercise":"Back Squat","variant":null,"sets":3,"reps":5,"percent1RM":0.8,"restMinutes":3,"notes":null}]}]}]
        """

        let record = CKRecord(recordType: "Program", recordID: CKRecord.ID(recordName: id))
        record["id"] = id as NSString
        record["name"] = name as NSString
        record["category"] = "Strength" as NSString
        record["description"] = "Cloud seeded" as NSString
        record["durationWeeks"] = NSNumber(value: 4)
        record["sessionsPerWeek"] = NSNumber(value: 3)
        record["difficulty"] = "beginner" as NSString
        record["weeksJSON"] = weeksJSON as NSString
        if let phasesJSON {
            record["phasesJSON"] = phasesJSON as NSString
        }
        if let cycleAdjustmentProfileJSON {
            record["cycleAdjustmentProfileJSON"] = cycleAdjustmentProfileJSON as NSString
        }
        return record
    }

    @Test
    func enrolledProgramComputedPropertiesHandleFallbacks() {
        let enrolled = EnrolledProgram(
            id: "enroll-1",
            userID: "user-1",
            programID: "program-1",
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            currentWeek: 3,
            currentDay: 2,
            status: .completed,
            completedAt: Date(timeIntervalSince1970: 1_700_000_100),
            canceledAt: nil,
            completedWeeks: [4, 2, 3],
            lastSyncedAt: Date(timeIntervalSince1970: 1_700_000_200)
        )

        #expect(enrolled.completedWeeksRaw == "2,3,4")
        #expect(enrolled.completedWeeks == [2, 3, 4])
        #expect(enrolled.isActive == false)

        enrolled.status = .active
        #expect(enrolled.statusRaw == "active")
        #expect(enrolled.isActive)

        enrolled.statusRaw = "unexpected"
        #expect(enrolled.status == .active)

        enrolled.completedWeeksRaw = "7,abc,1"
        #expect(enrolled.completedWeeks == [1, 7])
        enrolled.completedWeeks = [9, 4]
        #expect(enrolled.completedWeeksRaw == "4,9")
    }

    @Test
    func enrollmentEventTypeRoundTripsAndFallsBack() {
        let event = EnrollmentEvent(
            id: "event-1",
            enrollmentID: "enroll-1",
            eventType: .enrolled,
            occurredAt: Date(timeIntervalSince1970: 1_700_000_000),
            programID: "program-1"
        )

        #expect(event.eventType == .enrolled)
        event.eventType = .autoHealed
        #expect(event.eventTypeRaw == "auto_healed")
        #expect(event.eventType == .autoHealed)

        event.eventTypeRaw = "unknown"
        #expect(event.eventType == .enrolled)
    }

    @Test
    func injuryProfileComputedPropertiesHandleWhitespaceAndRawValues() {
        let profile = InjuryProfile(
            id: "injury-1",
            userID: "user-1",
            location: "  ",
            movementLimitations: "",
            recoveryGoal: "",
            status: .active,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100),
            resolvedAt: nil
        )

        #expect(profile.isActive)
        #expect(profile.isComplete == false)

        profile.location = "Knee"
        profile.movementLimitations = "No deep flexion"
        profile.recoveryGoal = "Return to squatting"
        #expect(profile.isComplete)

        profile.status = .resolved
        #expect(profile.statusRaw == "resolved")
        profile.recoveryPhase = .resolved
        #expect(profile.isActive == false)

        profile.statusRaw = "invalid"
        #expect(profile.status == .active)
    }

    @Test
    func injuryProfileAcknowledgedDisclaimerIdsRoundTrip() {
        let profile = InjuryProfile(id: "injury-2", userID: "user-1")

        profile.acknowledgedDisclaimerIDs = Set(["zeta", "alpha"])
        #expect(profile.acknowledgedDisclaimerIDsRaw == "alpha,zeta")
        #expect(profile.acknowledgedDisclaimerIDs == Set(["alpha", "zeta"]))

        profile.acknowledgedDisclaimerIDsRaw = "bracing,mobility,bracing"
        #expect(profile.acknowledgedDisclaimerIDs == Set(["bracing", "mobility"]))
    }

    @Test
    func activeCycleStatusRoundTripsAndFallsBack() {
        let cycle = ActiveCycle(
            id: "cycle-1",
            userID: "user-1",
            programID: "program-1",
            cycleName: "Main Cycle",
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            currentWeek: 2,
            currentSessionID: "session-2",
            currentPhase: "ovulation",
            status: .completed
        )

        #expect(cycle.status == .completed)
        cycle.status = .canceled
        #expect(cycle.statusRaw == "canceled")
        #expect(cycle.status == .canceled)

        cycle.statusRaw = "unknown"
        #expect(cycle.status == .active)
    }

    @Test
    func cycleModelFlowLevelAccessorsRoundTripAndFallback() {
        let period = PeriodLog(
            id: "period-1",
            userID: "user-1",
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            flowLevel: .light
        )

        #expect(period.flowLevel == .light)
        period.flowLevel = .heavy
        #expect(period.flowLevelRaw == "heavy")

        period.flowLevelRaw = "invalid"
        #expect(period.flowLevel == .medium)
    }

    @Test
    func userEnumAccessorsRoundTripAndFallback() {
        let user = User(
            id: "user-1",
            name: "Taylor",
            experienceLevel: .intermediate,
            primaryGoal: .hypertrophy,
            gender: .female,
            appleUserID: "apple-user-1",
            cycleTrackingEnabled: true,
            onboardingComplete: true,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            profileUpdatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )

        #expect(user.experienceLevel == .intermediate)
        #expect(user.primaryGoal == .hypertrophy)
        #expect(user.gender == .female)
        #expect(user.weightUnit == .pounds)
        #expect(user.hasRequiredOnboardingAnswers)

        user.experienceLevel = .advanced
        user.primaryGoal = .weightLoss
        user.gender = .preferNotToSay
        user.weightUnit = .kilograms
        #expect(user.experienceLevelRaw == "advanced")
        #expect(user.primaryGoalRaw == "weight_loss")
        #expect(user.genderRaw == "prefer_not_to_say")
        #expect(user.weightUnitRaw == "kg")

        user.experienceLevelRaw = "invalid"
        user.primaryGoalRaw = "invalid"
        user.genderRaw = "invalid"
        user.weightUnitRaw = "invalid"
        #expect(user.experienceLevel == .beginner)
        #expect(user.primaryGoal == .strength)
        #expect(user.gender == .preferNotToSay)
        #expect(user.weightUnit == .pounds)

        user.name = "   "
        #expect(user.hasRequiredOnboardingAnswers == false)
    }

    @Test
    func maxModelsRoundTripRepMaxTypeAndInitializers() {
        let oneRepMax = OneRepMax(
            id: "orm-1",
            userID: "user-1",
            exerciseID: "Back Squat",
            weightKg: 120,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            isEstimated: true
        )
        #expect(oneRepMax.weightKg == 120)
        #expect(oneRepMax.isEstimated)

        let personalRecord = PersonalRecord(
            id: "pr-1",
            userID: "user-1",
            exerciseID: "Back Squat",
            repMaxType: .five,
            weightKg: 100,
            reps: 5,
            achievedAt: Date(timeIntervalSince1970: 1_700_000_100),
            workoutID: "workout-1"
        )
        #expect(personalRecord.repMaxType == .five)

        personalRecord.repMaxType = .three
        #expect(personalRecord.repMaxTypeRaw == "3RM")
        #expect(personalRecord.repMaxType == .three)

        personalRecord.repMaxTypeRaw = "invalid"
        #expect(personalRecord.repMaxType == .one)

        let liftMax = LiftMax(
            id: "lift-1",
            userID: "user-1",
            exerciseID: "Deadlift",
            weightKg: 140,
            date: Date(timeIntervalSince1970: 1_700_000_200)
        )
        #expect(liftMax.exerciseID == "Deadlift")
        #expect(liftMax.weightKg == 140)
    }

    @Test
    func bundledProgramRepositoryHandlesMissingOrBundledPrograms() async throws {
        let repository = BundledProgramRepository()
        let first = try await repository.fetchPrograms()
        let second = try await repository.fetchPrograms()

        #expect(first == second)
        #expect(try await repository.fetchProgram(id: "__does_not_exist__") == nil)

        let missingRepository = BundledProgramRepository(resourceName: "__missing_programs__")
        #expect((try await missingRepository.fetchPrograms()).isEmpty)
        #expect(try await missingRepository.fetchProgram(id: "anything") == nil)
    }

    @Test
    func cloudKitProgramRepositoryFallsBackWhenCloudFetcherThrows() async throws {
        let fallback = StubProgramRepository(programs: [makeProgram(id: "fallback-1", name: "Fallback Program")])
        let repository = CloudKitProgramRepository(
            fallback: fallback,
            cloudFetcher: { throw StubProgramRepositoryError.fetchFailed }
        )

        #expect(try await repository.fetchPrograms().map(\.id) == ["fallback-1"])
        #expect(try await repository.fetchProgram(id: "fallback-1")?.id == "fallback-1")
    }

    @Test
    func cloudKitProgramRepositoryUsesCloudFetcherWhenSuccessful() async throws {
        let repository = CloudKitProgramRepository(
            fallback: StubProgramRepository(programs: [makeProgram(id: "fallback-1", name: "Fallback Program")]),
            cloudFetcher: { [program = makeProgram(id: "cloud-1", name: "Cloud Program")] in [program] }
        )

        #expect(try await repository.fetchPrograms().map(\.id) == ["cloud-1"])
        #expect(try await repository.fetchProgram(id: "cloud-1")?.id == "cloud-1")
    }

    @Test
    func cloudKitProgramRepositoryBuildsSortedQueryAndDecodesRecords() async throws {
        let sortProbe = SortProbe()
        let record = makeProgramRecord()
        let repository = CloudKitProgramRepository(
            fallback: StubProgramRepository(programs: []),
            cloudRecordFetcher: { query in
                await sortProbe.record(
                    key: query.sortDescriptors?.first?.key,
                    ascending: query.sortDescriptors?.first?.ascending
                )
                return [(record.recordID, .success(record))]
            }
        )

        #expect(try await repository.fetchPrograms().map(\.id) == ["cloud-1"])
        #expect(try await repository.fetchProgram(id: "cloud-1")?.id == "cloud-1")

        let sortDetails = await sortProbe.snapshot()
        #expect(sortDetails.key == "name")
        #expect(sortDetails.ascending == true)
    }

    @Test
    func cloudKitProgramRepositoryFallsBackWhenCloudRecordsFailToDecode() async throws {
        let fallback = StubProgramRepository(programs: [makeProgram(id: "fallback-1", name: "Fallback Program")])
        let repository = CloudKitProgramRepository(
            fallback: fallback,
            cloudRecordFetcher: { _ in
                [(CKRecord.ID(recordName: "bad-record"), .failure(StubProgramRepositoryError.fetchFailed))]
            }
        )

        #expect(try await repository.fetchPrograms().map(\.id) == ["fallback-1"])
        #expect(try await repository.fetchProgram(id: "fallback-1")?.id == "fallback-1")
    }

    @Test
    func cloudKitProgramRepositoryContainerInitializerUsesInjectedQueryExecutor() async throws {
        let sortProbe = SortProbe()
        let record = makeProgramRecord(id: "cloud-init-1", name: "Cloud Init Program")
        let repository = CloudKitProgramRepository(
            containerID: "iCloud.com.sundeefundee.app",
            fallback: StubProgramRepository(programs: [makeProgram(id: "fallback-2", name: "Fallback Program 2")]),
            cloudQueryExecutor: { query in
                await sortProbe.record(
                    key: query.sortDescriptors?.first?.key,
                    ascending: query.sortDescriptors?.first?.ascending
                )
                return [(record.recordID, .success(record))]
            }
        )

        #expect(try await repository.fetchProgram(id: "cloud-init-1")?.id == "cloud-init-1")

        let sortDetails = await sortProbe.snapshot()
        #expect(sortDetails.containerID == nil)
        #expect(sortDetails.key == "name")
        #expect(sortDetails.ascending == true)
    }

    @Test
    func cloudKitProgramRepositoryContainerInitializerWithoutExecutorFallsBack() async throws {
        let fallback = StubProgramRepository(programs: [makeProgram(id: "fallback-default", name: "Fallback Default")])
        // Inject a throwing executor to simulate CloudKit being unavailable without
        // calling CKContainer(identifier:), which traps in the test environment.
        let repository = CloudKitProgramRepository(
            containerID: "iCloud.invalid.sundeefundee.coverage",
            fallback: fallback,
            cloudQueryExecutor: { _ in throw CKError(.networkUnavailable) }
        )

        #expect(try await repository.fetchProgram(id: "fallback-default")?.id == "fallback-default")
    }

    @Test
    func programDecodingErrorAndOptionalJSONFallbacksAreHandled() throws {
        let missingFieldRecord = CKRecord(recordType: "Program", recordID: CKRecord.ID(recordName: "missing-fields"))
        missingFieldRecord["id"] = "missing-fields" as NSString

        do {
            _ = try Program(record: missingFieldRecord)
            Issue.record("Expected missing fields decoding error")
        } catch ProgramDecodingError.missingFields {
            // expected
        } catch {
            Issue.record("Unexpected decoding error: \(error)")
        }

        let recordWithInvalidOptionals = makeProgramRecord(
            id: "cloud-invalid-optionals",
            name: "Cloud Invalid Optional JSON",
            phasesJSON: "{bad-json",
            cycleAdjustmentProfileJSON: "{bad-json"
        )
        let program = try Program(record: recordWithInvalidOptionals)
        #expect(program.phases.isEmpty)
        #expect(program.cycleAdjustmentProfile == nil)
    }

    @Test
    func metricsServiceHandlesPayloadsWithAndWithoutDiagnostics() {
        MetricsService.shared.start()
        MetricsService.shared.didReceive([] as [MXMetricPayload])
        MetricsService.shared.didReceive([] as [MXDiagnosticPayload])
        MetricsService.shared.stop()

        let metricFull = MetricsService.shared.metricSummaryLines(
            begin: Date(timeIntervalSince1970: 1_700_000_000),
            end: Date(timeIntervalSince1970: 1_700_000_100),
            cpuTime: Measurement(value: 12.5, unit: .seconds),
            peakMemory: Measurement(value: 256, unit: .megabytes)
        )
        #expect(metricFull.count == 3)

        let metricMinimal = MetricsService.shared.metricSummaryLines(
            begin: Date(timeIntervalSince1970: 1_700_000_000),
            end: Date(timeIntervalSince1970: 1_700_000_100),
            cpuTime: nil,
            peakMemory: nil
        )
        #expect(metricMinimal.count == 1)

        let diagnosticFull = MetricsService.shared.diagnosticSummaryLines(crashCount: 2, hangCount: 1)
        #expect(diagnosticFull.count == 3)

        let diagnosticMinimal = MetricsService.shared.diagnosticSummaryLines(crashCount: nil, hangCount: nil)
        #expect(diagnosticMinimal.count == 1)

        var metricLogLines: [String] = []
        MetricsService.shared.logMetricPayloads([
            .init(
                begin: Date(timeIntervalSince1970: 1_700_000_000),
                end: Date(timeIntervalSince1970: 1_700_000_100),
                cpuTime: Measurement(value: 4, unit: .seconds),
                peakMemory: nil
            ),
            .init(
                begin: Date(timeIntervalSince1970: 1_700_000_200),
                end: Date(timeIntervalSince1970: 1_700_000_300),
                cpuTime: nil,
                peakMemory: Measurement(value: 128, unit: .megabytes)
            ),
        ]) { metricLogLines.append($0) }
        #expect(metricLogLines.count == 4)
        #expect(metricLogLines.contains { $0.contains("CPU time") })
        #expect(metricLogLines.contains { $0.contains("Peak memory") })

        var diagnosticLogLines: [String] = []
        MetricsService.shared.logDiagnosticPayloads([
            .init(crashCount: 2, hangCount: 1),
            .init(crashCount: nil, hangCount: nil),
        ]) { diagnosticLogLines.append($0) }
        #expect(diagnosticLogLines.count == 4)
        #expect(diagnosticLogLines.contains { $0.contains("Crashes: 2") })
        #expect(diagnosticLogLines.contains { $0.contains("Hangs: 1") })
    }

    @Test
    func metricsServiceHandlesNonEmptyPayloadArraysAndDefaultPrinters() {
        MetricsService.shared.didReceive([StubMetricPayload()])
        MetricsService.shared.didReceive([StubDiagnosticPayload()])
        MetricsService.shared.logMetricPayloads([])
        MetricsService.shared.logDiagnosticPayloads([])
    }
}

private enum StubProgramRepositoryError: Error {
    case fetchFailed
}

private actor SortProbe {
    private var containerID: String?
    private var key: String?
    private var ascending: Bool?

    func record(containerID: String? = nil, key: String?, ascending: Bool?) {
        self.containerID = containerID
        self.key = key
        self.ascending = ascending
    }

    func snapshot() -> (containerID: String?, key: String?, ascending: Bool?) {
        (containerID: containerID, key: key, ascending: ascending)
    }
}

private struct StubProgramRepository: ProgramRepository {
    let programs: [Program]

    func fetchPrograms() async throws -> [Program] {
        programs
    }

    func fetchProgram(id: String) async throws -> Program? {
        programs.first { $0.id == id }
    }
}

private final class StubMetricPayload: MXMetricPayload {
    override var timeStampBegin: Date { Date(timeIntervalSince1970: 1_700_000_000) }
    override var timeStampEnd: Date { Date(timeIntervalSince1970: 1_700_000_100) }
    override var cpuMetrics: MXCPUMetric? { nil }
    override var memoryMetrics: MXMemoryMetric? { nil }
}

private final class StubDiagnosticPayload: MXDiagnosticPayload {
    override var crashDiagnostics: [MXCrashDiagnostic]? { [] }
    override var hangDiagnostics: [MXHangDiagnostic]? { [] }
}
