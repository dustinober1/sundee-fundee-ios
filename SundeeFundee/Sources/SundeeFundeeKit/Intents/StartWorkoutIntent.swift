import AppIntents
import Foundation

// MARK: - StartWorkoutIntent
//
// Opens the app and switches to the Workouts tab so the user can start
// training. Posts `.startWorkoutFromIntent`; MainTabView listens and
// flips `selectedTab`.

@available(iOS 18.0, *)
public struct StartWorkoutIntent: AppIntent {
    public static var title: LocalizedStringResource = "Start my workout"
    public static var description = IntentDescription("Opens Sundee Fundee on the Workouts tab.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .startWorkoutFromIntent, object: nil)
        return .result()
    }
}

public extension Notification.Name {
    static let startWorkoutFromIntent = Notification.Name("startWorkoutFromIntent")
}
