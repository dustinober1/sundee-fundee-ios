#if canImport(UserNotifications)
import Foundation
import UserNotifications

protocol ReminderSettingsUpdateBoundary: Sendable {
    func requestAuthorization() async throws -> Bool
    func saveSettings(_ settings: WorkoutReminderSettings) async throws
    func loadPersistedSettings() async throws -> WorkoutReminderSettings
    func reconcileSchedule(settings: WorkoutReminderSettings) async throws
}

extension ReminderSettingsUpdateBoundary {
    func requestAuthorization() async throws -> Bool { true }
}

enum ReminderSettingsUpdateState: Sendable, Equatable {
    case applied
    case authorizationDenied
    case authorizationFailed
    case saveFailed
    case restored
    case rollbackFailed
    case reloadFailed
}

struct ReminderSettingsUpdateResult: Sendable, Equatable {
    let state: ReminderSettingsUpdateState
    let settings: WorkoutReminderSettings

    var errorMessage: String? {
        switch state {
        case .applied:
            return nil
        case .authorizationDenied:
            return "Notifications are off. Your previous reminder settings are unchanged. Enable notifications in Settings, then try again."
        case .authorizationFailed:
            return "Could not check notification access. Your previous reminder settings are unchanged. Please try again."
        case .saveFailed:
            return "Could not save reminders. Your previous settings and schedule are unchanged. Please try again."
        case .restored:
            return "Could not update reminders. Your previous settings and schedule were restored. Please try again."
        case .rollbackFailed:
            return "Reminder settings were reloaded, but notifications may be out of sync. Review your reminder settings and try again."
        case .reloadFailed:
            return "Reminder settings could not be verified and notifications may be out of sync. Reopen this screen and try again."
        }
    }
}

actor ReminderSettingsUpdateCoordinator {
    private let boundary: any ReminderSettingsUpdateBoundary
    private var queuedApply: (id: UUID, task: Task<ReminderSettingsUpdateResult, Never>)?

    init(boundary: any ReminderSettingsUpdateBoundary) {
        self.boundary = boundary
    }

    func apply(
        updated: WorkoutReminderSettings,
        previous: WorkoutReminderSettings
    ) async -> ReminderSettingsUpdateResult {
        let predecessor = queuedApply?.task
        let operationID = UUID()
        let boundary = self.boundary
        let operation = Task.detached { [boundary, predecessor] in
            let predecessorResult = await predecessor?.value
            let effectivePrevious: WorkoutReminderSettings
            if let predecessorResult {
                effectivePrevious = predecessorResult.settings
            } else {
                do {
                    effectivePrevious = try await boundary.loadPersistedSettings()
                } catch {
                    return ReminderSettingsUpdateResult(
                        state: .reloadFailed,
                        settings: previous
                    )
                }
            }
            return await Self.performApply(
                boundary: boundary,
                updated: updated,
                previous: effectivePrevious
            )
        }
        queuedApply = (operationID, operation)

        let result = await operation.value
        if queuedApply?.id == operationID {
            queuedApply = nil
        }
        return result
    }

    private nonisolated static func performApply(
        boundary: any ReminderSettingsUpdateBoundary,
        updated: WorkoutReminderSettings,
        previous: WorkoutReminderSettings
    ) async -> ReminderSettingsUpdateResult {
        if ReminderService.requiresAuthorization(from: previous, to: updated) {
            do {
                guard try await boundary.requestAuthorization() else {
                    return ReminderSettingsUpdateResult(
                        state: .authorizationDenied,
                        settings: previous
                    )
                }
            } catch {
                return ReminderSettingsUpdateResult(
                    state: .authorizationFailed,
                    settings: previous
                )
            }
        }

        do {
            try await boundary.saveSettings(updated)
        } catch {
            return ReminderSettingsUpdateResult(state: .saveFailed, settings: previous)
        }

        do {
            try await boundary.reconcileSchedule(settings: updated)
            return ReminderSettingsUpdateResult(state: .applied, settings: updated)
        } catch {
            do {
                try await boundary.saveSettings(previous)
                try await boundary.reconcileSchedule(settings: previous)
                return ReminderSettingsUpdateResult(state: .restored, settings: previous)
            } catch {
                do {
                    let authoritative = try await boundary.loadPersistedSettings()
                    return ReminderSettingsUpdateResult(
                        state: .rollbackFailed,
                        settings: authoritative
                    )
                } catch {
                    return ReminderSettingsUpdateResult(state: .reloadFailed, settings: updated)
                }
            }
        }
    }
}

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
        (try? await loadPersistedSettings()) ?? WorkoutReminderSettings()
    }

    public func loadPersistedSettings() async throws -> WorkoutReminderSettings {
        let records: [WorkoutReminderSettings] = try await dataClient.fetchAll(
            recordType: Self.recordType
        )
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
        _ = previous
        return updated.isEnabled || updated.dailyPlanEnabled
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

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
extension ReminderService: ReminderSettingsUpdateBoundary {}
#endif
