import AppIntents
import Foundation

// MARK: - StartWorkoutIntent
//
// Opens the app and switches to the Workouts tab so the user can start
// training. Posts `.startWorkoutFromIntent`; MainTabView listens and
// flips `selectedTab`.

@available(iOS 18.0, *)
public struct StartWorkoutIntent: AppIntent {
    public static let title: LocalizedStringResource = "Start my workout"
    public static let description = IntentDescription("Opens Sundee Fundee on the Workouts tab.")
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .startWorkoutFromIntent, object: nil)
        return .result()
    }
}

extension Notification.Name {
    public static let startWorkoutFromIntent = Notification.Name("startWorkoutFromIntent")
}
