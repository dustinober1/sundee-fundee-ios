#if canImport(ActivityKit) && os(iOS)
@preconcurrency import ActivityKit
import Foundation

@available(iOS 18.0, watchOS 11.0, *)
@MainActor
public final class LiveWorkoutActivityManager: @unchecked Sendable {

    private var _activity: Activity<LiveWorkoutActivityAttributes>?

    public init() {}

    public func start(workoutID: String, workoutName: String, snapshot: ActiveWorkoutState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = LiveWorkoutActivityAttributes.attributes(from: snapshot)
        let contentState = LiveWorkoutActivityAttributes.contentState(from: snapshot)
        let content = ActivityContent(state: contentState, staleDate: nil)

        do {
            _activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
        }
    }

    public func update(_ snapshot: ActiveWorkoutState) {
        guard let currentActivity = _activity else { return }
        let contentState = LiveWorkoutActivityAttributes.contentState(from: snapshot)
        let content = ActivityContent(state: contentState, staleDate: nil)
        Task { @MainActor [currentActivity] in
            await currentActivity.update(content)
        }
    }

    public func end(finalSnapshot: ActiveWorkoutState) {
        guard let currentActivity = _activity else { return }
        let contentState = LiveWorkoutActivityAttributes.contentState(from: finalSnapshot)
        let content = ActivityContent(state: contentState, staleDate: nil)
        _activity = nil
        Task { @MainActor [currentActivity] in
            await currentActivity.end(content, dismissalPolicy: .after(Date.now.addingTimeInterval(10)))
        }
    }
}
#endif
