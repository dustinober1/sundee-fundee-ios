#if canImport(UserNotifications)
import Foundation
import UserNotifications

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor ReminderService {
    public enum ReminderRoute: String, Sendable {
        case dashboard
        case workouts
        case today
    }

    public enum ReminderType: String, Codable, Sendable, CaseIterable {
        case plannedWorkoutReminder
        case missedPlanNudge
        case weeklyPlanningReminder
        case resumeWorkoutReminder
        case dailyPlanReminder
    }

    public static let dailyPlanNotificationCopy = (
        title: "Your day is ready",
        body: "Open Sundee Fundee for today’s plan or a quick check-in."
    )

    private let center: UNUserNotificationCenter
    private let dataClient: DataClientProtocol
    private static let recordType = "WorkoutReminderSettings"
    private static let dailyPlanIdentifier = "com.sundeefundee.daily-plan"

    public init(
        center: UNUserNotificationCenter = .current(),
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.center = center
        self.dataClient = dataClient
    }

    @discardableResult
    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    public func saveSettings(_ settings: WorkoutReminderSettings) async throws {
        try await dataClient.save(settings, recordType: Self.recordType)
    }

    public func loadSettings() async -> WorkoutReminderSettings {
        let records: [WorkoutReminderSettings] = (try? await dataClient.fetchAll(recordType: Self.recordType)) ?? []
        return records.first ?? WorkoutReminderSettings()
    }

    public func reconcileSchedule(settings: WorkoutReminderSettings) async throws {
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)

        if settings.isEnabled {
            for weekday in settings.preferredWeekdays {
                var components = DateComponents()
                components.weekday = weekday
                components.hour = settings.hour
                components.minute = settings.minute

                let content = UNMutableNotificationContent()
                content.title = "Your next workout is ready"
                content.body = "Low energy today? Start a lighter Sundee Fundee session."
                content.sound = .default
                content.userInfo = ["route": ReminderRoute.workouts.rawValue]

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: identifier(for: .plannedWorkoutReminder, weekday: weekday),
                    content: content,
                    trigger: trigger
                )
                try await center.add(request)
            }
        }

        if settings.dailyPlanEnabled {
            try await center.add(Self.dailyPlanRequest(settings: settings))
        }

        if settings.isEnabled || settings.dailyPlanEnabled {
            await GrowthAnalyticsService(dataClient: dataClient).track(
                GrowthEventName.reminderScheduled,
                source: "workout_reminders"
            )
        }
    }

    public func pendingReminderRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
            .filter { reminderIdentifiers.contains($0.identifier) }
    }

    public func pendingReminderCount() async -> Int {
        await center.pendingNotificationRequests()
            .filter { reminderIdentifiers.contains($0.identifier) }
            .count
    }

    public static func route(from userInfo: [AnyHashable: Any]) -> ReminderRoute {
        if let value = userInfo["route"] as? String,
           let route = ReminderRoute(rawValue: value) {
            return route
        }
        return .dashboard
    }

    static func requiresAuthorization(
        from previous: WorkoutReminderSettings,
        to updated: WorkoutReminderSettings
    ) -> Bool {
        (!previous.isEnabled && updated.isEnabled)
            || (!previous.dailyPlanEnabled && updated.dailyPlanEnabled)
    }

    static func dailyPlanRequest(settings: WorkoutReminderSettings) -> UNNotificationRequest {
        var components = DateComponents()
        components.hour = settings.dailyPlanHour
        components.minute = settings.dailyPlanMinute

        let content = UNMutableNotificationContent()
        content.title = dailyPlanNotificationCopy.title
        content.body = dailyPlanNotificationCopy.body
        content.sound = .default
        content.userInfo = ["route": ReminderRoute.today.rawValue]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        return UNNotificationRequest(
            identifier: dailyPlanIdentifier,
            content: content,
            trigger: trigger
        )
    }

    private var reminderIdentifiers: [String] {
        ReminderType.allCases.flatMap { type in
            (1...7).map { identifier(for: type, weekday: $0) }
        } + [Self.dailyPlanIdentifier]
    }

    private func identifier(for type: ReminderType, weekday: Int) -> String {
        "sundee.reminder.\(type.rawValue).\(weekday)"
    }
}
#endif
