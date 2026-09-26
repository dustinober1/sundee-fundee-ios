import AppIntents
import Foundation
#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

// MARK: - Notification Names

extension Notification.Name {
    public static let completeSetFromIntent = Notification.Name("completeSetFromIntent")
    public static let addRestFromIntent = Notification.Name("addRestFromIntent")
}

// MARK: - CompleteSetAppIntent

#if os(iOS)
public typealias SFWorkoutLiveIntent = LiveActivityIntent
#else
public typealias SFWorkoutLiveIntent = AppIntent
#endif

@available(iOS 18.0, watchOS 11.0, macOS 15.0, *)
public struct CompleteSetAppIntent: SFWorkoutLiveIntent {
    public static let title: LocalizedStringResource = "Complete Set"
    public static let description = IntentDescription("Completes the current set and begins the rest timer.")
    public static let isDiscoverable: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        // 1. Post notification for active in-app view model if running
        NotificationCenter.default.post(name: .completeSetFromIntent, object: nil)

        // 2. Read snapshot from SharedSnapshotStore for out-of-process lock screen execution
        if var state = SharedSnapshotStore.readActiveWorkoutState(),
           state.status != .completed {
            state.progress.completedSets += 1
            state.progress.remainingSets = max(0, state.progress.remainingSets - 1)

            if let current = state.current, current.restSecondsAfterSet > 0 {
                state.status = .resting
                state.rest = ActiveWorkoutState.Rest(
                    sourceExerciseName: current.exerciseName,
                    sourceSetIndex: current.setIndex,
                    targetDurationSeconds: current.restSecondsAfterSet,
                    startedAt: Date()
                )
            } else if state.progress.remainingSets == 0 {
                state.status = .completed
                state.rest = nil
            }

            SharedSnapshotStore.writeActiveWorkoutState(state)

            #if canImport(ActivityKit) && os(iOS)
            for activity in Activity<LiveWorkoutActivityAttributes>.activities {
                let contentState = LiveWorkoutActivityAttributes.contentState(from: state)
                await activity.update(ActivityContent(state: contentState, staleDate: nil))
            }
            #endif
        }

        return .result()
    }
}

// MARK: - AddRestAppIntent

@available(iOS 18.0, watchOS 11.0, macOS 15.0, *)
public struct AddRestAppIntent: SFWorkoutLiveIntent {
    public static let title: LocalizedStringResource = "Add 30s Rest"
    public static let description = IntentDescription("Adds 30 seconds to the active rest countdown.")
    public static let isDiscoverable: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .addRestFromIntent, object: nil)

        if var state = SharedSnapshotStore.readActiveWorkoutState() {
            if var rest = state.rest {
                rest.targetDurationSeconds += 30
                state.rest = rest
            } else if let current = state.current {
                state.status = .resting
                state.rest = ActiveWorkoutState.Rest(
                    sourceExerciseName: current.exerciseName,
                    sourceSetIndex: current.setIndex,
                    targetDurationSeconds: 30,
                    startedAt: Date()
                )
            }

            SharedSnapshotStore.writeActiveWorkoutState(state)

            #if canImport(ActivityKit) && os(iOS)
            for activity in Activity<LiveWorkoutActivityAttributes>.activities {
                let contentState = LiveWorkoutActivityAttributes.contentState(from: state)
                await activity.update(ActivityContent(state: contentState, staleDate: nil))
            }
            #endif
        }

        return .result()
    }
}
