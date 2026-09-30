import Foundation
import Testing
@testable import SundeeFundeeKit

#if canImport(UserNotifications)
import UserNotifications

@Suite("Reminder Service")
struct ReminderServiceTests {
    @Test("Legacy settings keep the daily plan reminder off")
    func oldSettingsDefaultDailyPlanReminderOff() throws {
        let oldJSON = """
        {
          "id":"workout_reminder_settings",
          "isEnabled":false,
          "preferredWeekdays":[2,4,6],
          "hour":9,
          "minute":0,
          "dateUpdated":"2026-07-26T12:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let settings = try decoder.decode(WorkoutReminderSettings.self, from: Data(oldJSON.utf8))

        #expect(settings.dailyPlanEnabled == false)
        #expect(settings.dailyPlanHour == 8)
        #expect(settings.dailyPlanMinute == 0)
    }

    @Test("Daily plan reminder time stays within calendar bounds")
    func dailyPlanTimeIsValidated() {
        let settings = WorkoutReminderSettings(
            dailyPlanEnabled: true,
            dailyPlanHour: 24,
            dailyPlanMinute: -1
        )

        #expect(settings.dailyPlanHour == 23)
        #expect(settings.dailyPlanMinute == 0)
    }

    @Test("CloudKit integer flags decode for reminder settings")
    func cloudKitIntegerFlagsDecode() throws {
        let cloudKitJSON = """
        {
          "id":"workout_reminder_settings",
          "isEnabled":9223372036854775807,
          "preferredWeekdays":[2,4,6],
          "hour":9,
          "minute":0,
          "dailyPlanEnabled":1,
          "dailyPlanHour":7,
          "dailyPlanMinute":30,
          "dateUpdated":"2026-07-26T12:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let settings = try decoder.decode(WorkoutReminderSettings.self, from: Data(cloudKitJSON.utf8))

        #expect(settings.isEnabled)
        #expect(settings.dailyPlanEnabled)
    }

    @Test("Reminder settings encode only approved preference fields")
    func reminderSettingsEncodedFieldsArePrivacySafe() throws {
        let settings = WorkoutReminderSettings(
            isEnabled: true,
            preferredWeekdays: [2, 4, 6],
            hour: 9,
            minute: 15,
            dailyPlanEnabled: true,
            dailyPlanHour: 7,
            dailyPlanMinute: 30,
            dateUpdated: Date(timeIntervalSince1970: 1_753_528_400)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let object = try #require(
            JSONSerialization.jsonObject(with: encoder.encode(settings)) as? [String: Any]
        )

        let approved: Set<String> = [
            "id", "isEnabled", "preferredWeekdays", "hour", "minute",
            "dailyPlanEnabled", "dailyPlanHour", "dailyPlanMinute", "dateUpdated",
        ]
        #expect(Set(object.keys) == approved)
        #expect(object["dateUpdated"] is String)
        #expect(object.keys.allSatisfy { key in
            !["cycle", "pain", "health", "hrv", "readiness", "checkin"].contains { term in
                key.localizedCaseInsensitiveContains(term)
            }
        })
    }

    @Test("Missing required reminder flag throws a Bool type mismatch")
    func missingRequiredReminderFlagThrows() {
        expectBoolTypeMismatch(
            """
            {
              "id":"workout_reminder_settings",
              "preferredWeekdays":[2,4,6],
              "hour":9,
              "minute":0,
              "dateUpdated":"2026-07-26T12:00:00Z"
            }
            """
        )
    }

    @Test("Malformed required reminder flag throws a Bool type mismatch")
    func malformedRequiredReminderFlagThrows() {
        expectBoolTypeMismatch(
            """
            {
              "id":"workout_reminder_settings",
              "isEnabled":"yes",
              "preferredWeekdays":[2,4,6],
              "hour":9,
              "minute":0,
              "dateUpdated":"2026-07-26T12:00:00Z"
            }
            """
        )
    }

    @Test("Malformed optional daily plan flag throws a Bool type mismatch")
    func malformedOptionalDailyPlanFlagThrows() {
        expectBoolTypeMismatch(
            """
            {
              "id":"workout_reminder_settings",
              "isEnabled":false,
              "preferredWeekdays":[2,4,6],
              "hour":9,
              "minute":0,
              "dailyPlanEnabled":"yes",
              "dateUpdated":"2026-07-26T12:00:00Z"
            }
            """
        )
    }

    @Test("Null optional daily plan flag defaults off")
    func nullOptionalDailyPlanFlagDefaultsOff() throws {
        let json = """
        {
          "id":"workout_reminder_settings",
          "isEnabled":false,
          "preferredWeekdays":[2,4,6],
          "hour":9,
          "minute":0,
          "dailyPlanEnabled":null,
          "dateUpdated":"2026-07-26T12:00:00Z"
        }
        """

        let settings = try reminderSettingsDecoder.decode(
            WorkoutReminderSettings.self,
            from: Data(json.utf8)
        )

        #expect(settings.dailyPlanEnabled == false)
    }

    @Test("Daily plan copy contains no sensitive terms")
    func dailyPlanCopyContainsNoSensitiveTerms() {
        let copy = ReminderService.dailyPlanNotificationCopy
        let forbidden = ["cycle", "period", "pain", "HRV", "readiness score", "HealthKit"]

        #expect(forbidden.allSatisfy {
            !copy.title.localizedCaseInsensitiveContains($0)
                && !copy.body.localizedCaseInsensitiveContains($0)
        })
    }

    @Test("Daily plan request is stable, repeating, and privacy safe")
    func dailyPlanRequestContract() throws {
        let settings = WorkoutReminderSettings(
            dailyPlanEnabled: true,
            dailyPlanHour: 7,
            dailyPlanMinute: 30
        )

        let request = ReminderService.dailyPlanRequest(settings: settings)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)

        #expect(request.identifier == "com.sundeefundee.daily-plan")
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.hour == 7)
        #expect(trigger.dateComponents.minute == 30)
        #expect(request.content.title == "Your day is ready")
        #expect(request.content.body == "Open Sundee Fundee for today’s plan or a quick check-in.")
        #expect(request.content.userInfo.count == 1)
        #expect(request.content.userInfo["route"] as? String == "today")
    }

    @Test("Daily plan notification routes to Today")
    func dailyPlanRouteTargetsToday() {
        let route = WorkoutReminderNotificationDelegate.appRoute(from: ["route": "today"])

        #expect(route == .today)
    }

    @Test(
        "Authorization is confirmed for every enabled reminder revision",
        arguments: [
            (
                WorkoutReminderSettings(),
                WorkoutReminderSettings(dailyPlanEnabled: true),
                true
            ),
            (
                WorkoutReminderSettings(isEnabled: true),
                WorkoutReminderSettings(isEnabled: true, hour: 10),
                true
            ),
            (
                WorkoutReminderSettings(dailyPlanEnabled: true),
                WorkoutReminderSettings(dailyPlanEnabled: true, dailyPlanHour: 9),
                true
            ),
            (
                WorkoutReminderSettings(isEnabled: true, dailyPlanEnabled: true),
                WorkoutReminderSettings(),
                false
            ),
        ]
    )
    func authorizationTransition(
        previous: WorkoutReminderSettings,
        updated: WorkoutReminderSettings,
        expected: Bool
    ) {
        #expect(ReminderService.requiresAuthorization(from: previous, to: updated) == expected)
    }

    @Test("A reconcile failure restores prior persisted settings and schedule")
    func reconcileFailureRestoresPriorState() async {
        let previous = WorkoutReminderSettings(
            isEnabled: true,
            hour: 9,
            dateUpdated: Date(timeIntervalSince1970: 1)
        )
        let updated = WorkoutReminderSettings(
            dailyPlanEnabled: true,
            dailyPlanHour: 8,
            dateUpdated: Date(timeIntervalSince1970: 2)
        )
        let boundary = InMemoryReminderSettingsBoundary(
            persisted: previous,
            scheduled: previous,
            failingReconcileAttempts: [1]
        )
        let coordinator = ReminderSettingsUpdateCoordinator(boundary: boundary)

        let result = await coordinator.apply(updated: updated, previous: previous)
        let snapshot = await boundary.snapshot()
        var expected = previous
        expected.dateUpdated = result.settings.dateUpdated

        #expect(result.state == .restored)
        #expect(result.settings == expected)
        #expect(result.settings.dateUpdated > updated.dateUpdated)
        #expect(snapshot.persisted == result.settings)
        #expect(snapshot.scheduled == result.settings)
    }

    @Test("Rollback is versioned after the applied CloudKit revision")
    func rollbackWinsCloudKitConflictResolution() async {
        let previous = WorkoutReminderSettings(
            isEnabled: false,
            hour: 9,
            dateUpdated: Date(timeIntervalSince1970: 1)
        )
        let updated = WorkoutReminderSettings(
            isEnabled: false,
            hour: 10,
            dateUpdated: Date(timeIntervalSince1970: 2)
        )
        let boundary = ConflictResolvingReminderSettingsBoundary(initial: previous)
        let coordinator = ReminderSettingsUpdateCoordinator(boundary: boundary)

        let result = await coordinator.apply(updated: updated, previous: previous)
        let snapshot = await boundary.snapshot()

        #expect(result.state == .restored)
        #expect(result.settings.hour == previous.hour)
        #expect(result.settings.dateUpdated > updated.dateUpdated)
        #expect(snapshot.persisted == result.settings)
        #expect(snapshot.scheduled == result.settings)
    }

    @Test("Reconcile failure never rolls back a concurrent server winner")
    func reconcileFailurePreservesConcurrentServerWinner() async {
        let previous = WorkoutReminderSettings(
            isEnabled: false,
            hour: 9,
            dateUpdated: Date(timeIntervalSince1970: 1)
        )
        let updated = WorkoutReminderSettings(
            isEnabled: false,
            hour: 10,
            dateUpdated: Date(timeIntervalSince1970: 2)
        )
        let serverWinner = WorkoutReminderSettings(
            isEnabled: true,
            hour: 11,
            dateUpdated: Date(timeIntervalSince1970: 10)
        )
        let boundary = ConcurrentServerWinnerReminderBoundary(
            previous: previous,
            serverWinner: serverWinner
        )
        let coordinator = ReminderSettingsUpdateCoordinator(boundary: boundary)

        let result = await coordinator.apply(updated: updated, previous: previous)
        let snapshot = await boundary.snapshot()

        #expect(result.state == .rollbackFailed)
        #expect(result.settings == serverWinner)
        #expect(snapshot.persisted == serverWinner)
        #expect(snapshot.saveCallCount == 1)
    }

    @Test("A failed rollback reloads authoritative persisted settings")
    func rollbackFailureReloadsAuthoritativeState() async {
        let previous = WorkoutReminderSettings(
            isEnabled: true,
            hour: 9,
            dateUpdated: Date(timeIntervalSince1970: 1)
        )
        let updated = WorkoutReminderSettings(
            dailyPlanEnabled: true,
            dailyPlanHour: 8,
            dateUpdated: Date(timeIntervalSince1970: 2)
        )
        let boundary = InMemoryReminderSettingsBoundary(
            persisted: previous,
            scheduled: previous,
            failingSaveAttempts: [2],
            failingReconcileAttempts: [1]
        )
        let coordinator = ReminderSettingsUpdateCoordinator(boundary: boundary)

        let result = await coordinator.apply(updated: updated, previous: previous)

        #expect(result.state == .rollbackFailed)
        #expect(result.settings == updated)
        #expect(result.errorMessage?.localizedCaseInsensitiveContains("out of sync") == true)
        #expect(result.errorMessage?.localizedCaseInsensitiveContains("try again") == true)
    }

    @Test("The first queued update uses persisted settings as its rollback base")
    func firstUpdateLoadsAuthoritativePreviousSettings() async {
        let staleViewState = WorkoutReminderSettings(
            isEnabled: false,
            hour: 8,
            dateUpdated: Date(timeIntervalSince1970: 1)
        )
        let persisted = WorkoutReminderSettings(
            isEnabled: false,
            hour: 9,
            dateUpdated: Date(timeIntervalSince1970: 2)
        )
        let updated = WorkoutReminderSettings(
            isEnabled: false,
            hour: 10,
            dateUpdated: Date(timeIntervalSince1970: 3)
        )
        let boundary = InMemoryReminderSettingsBoundary(
            persisted: persisted,
            scheduled: persisted,
            failingSaveAttempts: [1]
        )
        let coordinator = ReminderSettingsUpdateCoordinator(boundary: boundary)

        let result = await coordinator.apply(updated: updated, previous: staleViewState)

        #expect(result.state == .saveFailed)
        #expect(result.settings == persisted)
    }

    @Test("Overlapping updates do not interleave persistence transactions")
    func overlappingUpdatesAreSerialized() async {
        let original = WorkoutReminderSettings(
            isEnabled: true,
            hour: 9,
            dateUpdated: Date(timeIntervalSince1970: 1)
        )
        let firstUpdate = WorkoutReminderSettings(
            isEnabled: true,
            hour: 10,
            dateUpdated: Date(timeIntervalSince1970: 2)
        )
        let secondUpdate = WorkoutReminderSettings(
            isEnabled: true,
            hour: 11,
            dateUpdated: Date(timeIntervalSince1970: 3)
        )
        let boundary = SlowReminderSettingsBoundary(initial: original)
        let coordinator = ReminderSettingsUpdateCoordinator(boundary: boundary)

        async let firstResult = coordinator.apply(updated: firstUpdate, previous: original)
        while !(await boundary.hasStartedSave()) {
            await Task.yield()
        }
        async let secondResult = coordinator.apply(updated: secondUpdate, previous: firstUpdate)
        _ = await (firstResult, secondResult)

        let snapshot = await boundary.snapshot()

        #expect(snapshot.maximumConcurrentSaves == 1)
        #expect(snapshot.persisted == secondUpdate)
        #expect(snapshot.scheduled == secondUpdate)
    }

    @Test("A failed older update cannot roll back a queued newer update")
    func failedOlderUpdateDoesNotOverwriteQueuedNewerUpdate() async {
        let original = WorkoutReminderSettings(
            isEnabled: true,
            hour: 9,
            dateUpdated: Date(timeIntervalSince1970: 1)
        )
        let firstUpdate = WorkoutReminderSettings(
            isEnabled: true,
            hour: 10,
            dateUpdated: Date(timeIntervalSince1970: 2)
        )
        let secondUpdate = WorkoutReminderSettings(
            isEnabled: true,
            hour: 11,
            dateUpdated: Date(timeIntervalSince1970: 3)
        )
        let boundary = SlowReminderSettingsBoundary(
            initial: original,
            failingFirstReconcile: true
        )
        let coordinator = ReminderSettingsUpdateCoordinator(boundary: boundary)

        async let firstResult = coordinator.apply(updated: firstUpdate, previous: original)
        while !(await boundary.hasStartedSave()) {
            await Task.yield()
        }
        async let secondResult = coordinator.apply(updated: secondUpdate, previous: firstUpdate)
        let results = await (firstResult, secondResult)
        let snapshot = await boundary.snapshot()
        var expected = secondUpdate
        expected.dateUpdated = results.1.settings.dateUpdated

        #expect(results.0.state == .restored)
        #expect(results.1.state == .applied)
        #expect(results.1.settings == expected)
        #expect(results.1.settings.dateUpdated > results.0.settings.dateUpdated)
        #expect(snapshot.persisted == results.1.settings)
        #expect(snapshot.scheduled == results.1.settings)
    }

    @Test("Queued enabled revisions cannot bypass denied authorization")
    func queuedEnabledRevisionsRequireAuthorization() async {
        let original = WorkoutReminderSettings(
            isEnabled: false,
            hour: 9,
            dateUpdated: Date(timeIntervalSince1970: 1)
        )
        let enabled = WorkoutReminderSettings(
            isEnabled: true,
            hour: 9,
            dateUpdated: Date(timeIntervalSince1970: 2)
        )
        let adjustedWhileAuthorizationIsPending = WorkoutReminderSettings(
            isEnabled: true,
            hour: 10,
            dateUpdated: Date(timeIntervalSince1970: 3)
        )
        let boundary = SuspendedAuthorizationBoundary(initial: original)
        let coordinator = ReminderSettingsUpdateCoordinator(boundary: boundary)

        async let firstResult = coordinator.apply(updated: enabled, previous: original)
        while !(await boundary.hasStartedAuthorization()) {
            await Task.yield()
        }
        async let secondResult = coordinator.apply(
            updated: adjustedWhileAuthorizationIsPending,
            previous: enabled
        )
        await boundary.denyFirstAuthorization()

        let results = await (firstResult, secondResult)
        let snapshot = await boundary.snapshot()

        #expect(results.0.state == .authorizationDenied)
        #expect(results.1.state == .authorizationDenied)
        #expect(results.1.settings == original)
        #expect(snapshot.authorizationCalls == 2)
        #expect(snapshot.saveCalls == 0)
        #expect(snapshot.persisted == original)
        #expect(snapshot.scheduled == original)
    }

    @Test("Equal-second revisions are made causally monotonic")
    func equalSecondRevisionsAdvanceMonotonically() async {
        let timestamp = Date(timeIntervalSince1970: 100)
        let original = WorkoutReminderSettings(
            isEnabled: false,
            hour: 9,
            dateUpdated: timestamp
        )
        let firstUpdate = WorkoutReminderSettings(
            isEnabled: false,
            hour: 10,
            dateUpdated: timestamp
        )
        let secondUpdate = WorkoutReminderSettings(
            isEnabled: false,
            hour: 11,
            dateUpdated: timestamp
        )
        let boundary = InMemoryReminderSettingsBoundary(
            persisted: original,
            scheduled: original
        )
        let coordinator = ReminderSettingsUpdateCoordinator(boundary: boundary)

        let firstResult = await coordinator.apply(
            updated: firstUpdate,
            previous: original
        )
        let secondResult = await coordinator.apply(
            updated: secondUpdate,
            previous: firstResult.settings
        )

        #expect(firstResult.settings.dateUpdated >= timestamp.addingTimeInterval(1))
        #expect(
            secondResult.settings.dateUpdated
                >= firstResult.settings.dateUpdated.addingTimeInterval(1)
        )
    }

    @Test("A server-winning tie schedules and publishes authoritative settings")
    func serverWinningTieUsesAuthoritativeSettings() async {
        let timestamp = Date(timeIntervalSince1970: 100)
        let server = WorkoutReminderSettings(
            isEnabled: true,
            hour: 9,
            dateUpdated: timestamp
        )
        let rejectedClient = WorkoutReminderSettings(
            isEnabled: true,
            hour: 10,
            dateUpdated: timestamp
        )
        let boundary = ServerWinningReminderSettingsBoundary(server: server)
        let coordinator = ReminderSettingsUpdateCoordinator(boundary: boundary)

        let result = await coordinator.apply(
            updated: rejectedClient,
            previous: server
        )
        let scheduled = await boundary.scheduledSettings()

        #expect(result.state == .applied)
        #expect(result.settings == server)
        #expect(scheduled == server)
    }

    private var reminderSettingsDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func expectBoolTypeMismatch(_ json: String) {
        do {
            _ = try reminderSettingsDecoder.decode(
                WorkoutReminderSettings.self,
                from: Data(json.utf8)
            )
            Issue.record("Expected decoding to reject the Bool field")
        } catch DecodingError.typeMismatch(let type, _) {
            #expect(String(reflecting: type) == "Swift.Bool")
        } catch {
            Issue.record("Expected DecodingError.typeMismatch, got \(error)")
        }
    }
}

private actor InMemoryReminderSettingsBoundary: ReminderSettingsUpdateBoundary {
    struct Snapshot: Sendable {
        let persisted: WorkoutReminderSettings
        let scheduled: WorkoutReminderSettings
    }

    private var persisted: WorkoutReminderSettings
    private var scheduled: WorkoutReminderSettings
    private let failingSaveAttempts: Set<Int>
    private let failingReconcileAttempts: Set<Int>
    private var saveAttempt = 0
    private var reconcileAttempt = 0

    init(
        persisted: WorkoutReminderSettings,
        scheduled: WorkoutReminderSettings,
        failingSaveAttempts: Set<Int> = [],
        failingReconcileAttempts: Set<Int> = []
    ) {
        self.persisted = persisted
        self.scheduled = scheduled
        self.failingSaveAttempts = failingSaveAttempts
        self.failingReconcileAttempts = failingReconcileAttempts
    }

    func saveSettings(_ settings: WorkoutReminderSettings) async throws {
        saveAttempt += 1
        guard !failingSaveAttempts.contains(saveAttempt) else {
            throw ReminderSettingsBoundaryTestError.injectedFailure
        }
        persisted = settings
    }

    func loadPersistedSettings() async throws -> WorkoutReminderSettings {
        persisted
    }

    func reconcileSchedule(settings: WorkoutReminderSettings) async throws {
        reconcileAttempt += 1
        guard !failingReconcileAttempts.contains(reconcileAttempt) else {
            throw ReminderSettingsBoundaryTestError.injectedFailure
        }
        scheduled = settings
    }

    func snapshot() -> Snapshot {
        Snapshot(persisted: persisted, scheduled: scheduled)
    }
}

private enum ReminderSettingsBoundaryTestError: Error {
    case injectedFailure
}

private actor ConflictResolvingReminderSettingsBoundary: ReminderSettingsUpdateBoundary {
    struct Snapshot: Sendable {
        let persisted: WorkoutReminderSettings
        let scheduled: WorkoutReminderSettings
    }

    private var persisted: WorkoutReminderSettings
    private var scheduled: WorkoutReminderSettings
    private var reconcileCount = 0

    init(initial: WorkoutReminderSettings) {
        persisted = initial
        scheduled = initial
    }

    func saveSettings(_ settings: WorkoutReminderSettings) async throws {
        persisted = CloudKitClient.resolveWorkoutReminderSettingsConflict(
            clientRecord: settings,
            serverRecord: persisted
        )
    }

    func loadPersistedSettings() async throws -> WorkoutReminderSettings {
        persisted
    }

    func reconcileSchedule(settings: WorkoutReminderSettings) async throws {
        reconcileCount += 1
        if reconcileCount == 1 {
            throw ReminderSettingsBoundaryTestError.injectedFailure
        }
        scheduled = settings
    }

    func snapshot() -> Snapshot {
        Snapshot(persisted: persisted, scheduled: scheduled)
    }
}

private actor ConcurrentServerWinnerReminderBoundary: ReminderSettingsUpdateBoundary {
    struct Snapshot: Sendable {
        let persisted: WorkoutReminderSettings
        let saveCallCount: Int
    }

    private var persisted: WorkoutReminderSettings
    private let serverWinner: WorkoutReminderSettings
    private var saveCallCount = 0
    private var reconcileCallCount = 0

    init(
        previous: WorkoutReminderSettings,
        serverWinner: WorkoutReminderSettings
    ) {
        persisted = previous
        self.serverWinner = serverWinner
    }

    func saveSettings(_ settings: WorkoutReminderSettings) async throws {
        saveCallCount += 1
        if saveCallCount == 1 {
            persisted = serverWinner
        } else {
            persisted = CloudKitClient.resolveWorkoutReminderSettingsConflict(
                clientRecord: settings,
                serverRecord: persisted
            )
        }
    }

    func loadPersistedSettings() async throws -> WorkoutReminderSettings {
        persisted
    }

    func reconcileSchedule(settings: WorkoutReminderSettings) async throws {
        _ = settings
        reconcileCallCount += 1
        guard reconcileCallCount > 1 else {
            throw ReminderSettingsBoundaryTestError.injectedFailure
        }
    }

    func snapshot() -> Snapshot {
        Snapshot(
            persisted: persisted,
            saveCallCount: saveCallCount
        )
    }
}

private actor ServerWinningReminderSettingsBoundary: ReminderSettingsUpdateBoundary {
    private let server: WorkoutReminderSettings
    private var scheduled: WorkoutReminderSettings

    init(server: WorkoutReminderSettings) {
        self.server = server
        scheduled = server
    }

    func requestAuthorization() async throws -> Bool { true }

    func saveSettings(_ settings: WorkoutReminderSettings) async throws {
        _ = settings
    }

    func loadPersistedSettings() async throws -> WorkoutReminderSettings {
        server
    }

    func reconcileSchedule(settings: WorkoutReminderSettings) async throws {
        scheduled = settings
    }

    func scheduledSettings() -> WorkoutReminderSettings {
        scheduled
    }
}

private actor SlowReminderSettingsBoundary: ReminderSettingsUpdateBoundary {
    struct Snapshot: Sendable {
        let persisted: WorkoutReminderSettings
        let scheduled: WorkoutReminderSettings
        let maximumConcurrentSaves: Int
    }

    private var persisted: WorkoutReminderSettings
    private var scheduled: WorkoutReminderSettings
    private var saveCount = 0
    private var activeSaves = 0
    private var maximumConcurrentSaves = 0
    private let failingFirstReconcile: Bool
    private var reconcileCount = 0

    init(initial: WorkoutReminderSettings, failingFirstReconcile: Bool = false) {
        persisted = initial
        scheduled = initial
        self.failingFirstReconcile = failingFirstReconcile
    }

    func saveSettings(_ settings: WorkoutReminderSettings) async throws {
        saveCount += 1
        activeSaves += 1
        maximumConcurrentSaves = max(maximumConcurrentSaves, activeSaves)

        if saveCount == 1 {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        persisted = settings
        activeSaves -= 1
    }

    func loadPersistedSettings() async throws -> WorkoutReminderSettings {
        persisted
    }

    func reconcileSchedule(settings: WorkoutReminderSettings) async throws {
        reconcileCount += 1
        guard !(failingFirstReconcile && reconcileCount == 1) else {
            throw ReminderSettingsBoundaryTestError.injectedFailure
        }
        scheduled = settings
    }

    func snapshot() -> Snapshot {
        Snapshot(
            persisted: persisted,
            scheduled: scheduled,
            maximumConcurrentSaves: maximumConcurrentSaves
        )
    }

    func hasStartedSave() -> Bool {
        saveCount > 0
    }
}

private actor SuspendedAuthorizationBoundary: ReminderSettingsUpdateBoundary {
    struct Snapshot: Sendable {
        let authorizationCalls: Int
        let saveCalls: Int
        let persisted: WorkoutReminderSettings
        let scheduled: WorkoutReminderSettings
    }

    private var persisted: WorkoutReminderSettings
    private var scheduled: WorkoutReminderSettings
    private var authorizationCalls = 0
    private var saveCalls = 0
    private var firstAuthorizationContinuation: CheckedContinuation<Bool, Never>?

    init(initial: WorkoutReminderSettings) {
        persisted = initial
        scheduled = initial
    }

    func requestAuthorization() async throws -> Bool {
        authorizationCalls += 1
        guard authorizationCalls == 1 else { return false }
        return await withCheckedContinuation { continuation in
            firstAuthorizationContinuation = continuation
        }
    }

    func saveSettings(_ settings: WorkoutReminderSettings) async throws {
        saveCalls += 1
        persisted = settings
    }

    func loadPersistedSettings() async throws -> WorkoutReminderSettings {
        persisted
    }

    func reconcileSchedule(settings: WorkoutReminderSettings) async throws {
        scheduled = settings
    }

    func hasStartedAuthorization() -> Bool {
        authorizationCalls > 0
    }

    func denyFirstAuthorization() {
        firstAuthorizationContinuation?.resume(returning: false)
        firstAuthorizationContinuation = nil
    }

    func snapshot() -> Snapshot {
        Snapshot(
            authorizationCalls: authorizationCalls,
            saveCalls: saveCalls,
            persisted: persisted,
            scheduled: scheduled
        )
    }
}
#endif
