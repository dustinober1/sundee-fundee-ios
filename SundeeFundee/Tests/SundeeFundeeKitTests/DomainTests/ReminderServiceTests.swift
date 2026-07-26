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
        "Authorization is needed only when a reminder is enabled",
        arguments: [
            (
                WorkoutReminderSettings(),
                WorkoutReminderSettings(dailyPlanEnabled: true),
                true
            ),
            (
                WorkoutReminderSettings(isEnabled: true),
                WorkoutReminderSettings(isEnabled: true, hour: 10),
                false
            ),
            (
                WorkoutReminderSettings(dailyPlanEnabled: true),
                WorkoutReminderSettings(dailyPlanEnabled: true, dailyPlanHour: 9),
                false
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

        #expect(result.state == .restored)
        #expect(result.settings == previous)
        #expect(snapshot.persisted == previous)
        #expect(snapshot.scheduled == previous)
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
#endif
