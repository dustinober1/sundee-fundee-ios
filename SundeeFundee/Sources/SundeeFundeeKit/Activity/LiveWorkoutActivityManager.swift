import ActivityKit

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public final class LiveWorkoutActivityManager {

    private var activity: Activity<LiveWorkoutActivityAttributes>?

    public init() {}

    /// Start a Live Activity for the given workout.
    /// Non-critical — silently does nothing if Live Activities are disabled or unavailable.
    public func start(workoutID: String, workoutName: String, snapshot: ActiveWorkoutState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = LiveWorkoutActivityAttributes.attributes(from: snapshot)
        let contentState = LiveWorkoutActivityAttributes.contentState(from: snapshot)
        let content = ActivityContent(state: contentState, staleDate: nil)

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            // Live Activity failed to start — non-critical, continue without it
        }
    }

    /// Update the Live Activity with new state.
    public func update(_ snapshot: ActiveWorkoutState) {
        guard let activity else { return }
        let contentState = LiveWorkoutActivityAttributes.contentState(from: snapshot)
        let content = ActivityContent(state: contentState, staleDate: nil)
        Task {
            await activity.update(content)
        }
    }

    /// End the Live Activity with a final snapshot. Dismisses after 10 seconds.
    public func end(finalSnapshot: ActiveWorkoutState) {
        guard let activity else { return }
        let contentState = LiveWorkoutActivityAttributes.contentState(from: finalSnapshot)
        let content = ActivityContent(state: contentState, staleDate: nil)
        Task {
            await activity.end(content, dismissalPolicy: .after(.now + 10))
            self.activity = nil
        }
    }
}
