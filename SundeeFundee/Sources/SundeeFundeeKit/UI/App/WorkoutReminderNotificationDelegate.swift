#if canImport(UserNotifications)
import Foundation
import UserNotifications

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public final class WorkoutReminderNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = WorkoutReminderNotificationDelegate()

    private override init() {}

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let route = ReminderService.route(from: response.notification.request.content.userInfo)
        NotificationCenter.default.post(name: .workoutReminderOpened, object: route.rawValue)
        await GrowthAnalyticsService().track(
            GrowthEventName.reminderOpened,
            source: "notification",
            properties: ["route": route.rawValue]
        )
    }
}
#endif
