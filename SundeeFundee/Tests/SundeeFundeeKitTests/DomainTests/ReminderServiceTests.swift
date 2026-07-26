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
          "isEnabled":1,
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
}
#endif
