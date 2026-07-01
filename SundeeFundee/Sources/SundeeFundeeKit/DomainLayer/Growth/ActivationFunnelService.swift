import Foundation

public struct ActivationFunnelSnapshot: Sendable, Equatable {
    public let onboardingStarted: Bool
    public let onboardingCompleted: Bool
    public let firstWorkoutStarted: Bool
    public let firstWorkoutCompleted: Bool
    public let secondSessionWithinSevenDays: Bool

    public init(
        onboardingStarted: Bool,
        onboardingCompleted: Bool,
        firstWorkoutStarted: Bool,
        firstWorkoutCompleted: Bool,
        secondSessionWithinSevenDays: Bool
    ) {
        self.onboardingStarted = onboardingStarted
        self.onboardingCompleted = onboardingCompleted
        self.firstWorkoutStarted = firstWorkoutStarted
        self.firstWorkoutCompleted = firstWorkoutCompleted
        self.secondSessionWithinSevenDays = secondSessionWithinSevenDays
    }
}

public enum ActivationFunnelService {
    public static func snapshot(from events: [GrowthEvent], now: Date = Date()) -> ActivationFunnelSnapshot {
        let names = Set(events.map(\.name))
        let completedWorkouts = events
            .filter {
                $0.name == GrowthEventName.firstWorkoutCompleted ||
                    $0.name == "workout_completed"
            }
            .sorted { $0.dateCreated < $1.dateCreated }

        let secondWithinSevenDays: Bool
        if completedWorkouts.count >= 2 {
            let first = completedWorkouts[0].dateCreated
            let second = completedWorkouts[1].dateCreated
            secondWithinSevenDays = second.timeIntervalSince(first) <= 7 * 24 * 60 * 60
        } else {
            secondWithinSevenDays = false
        }

        return ActivationFunnelSnapshot(
            onboardingStarted: names.contains(GrowthEventName.onboardingStarted),
            onboardingCompleted: names.contains(GrowthEventName.onboardingCompleted),
            firstWorkoutStarted: names.contains(GrowthEventName.firstWorkoutStarted),
            firstWorkoutCompleted: names.contains(GrowthEventName.firstWorkoutCompleted),
            secondSessionWithinSevenDays: secondWithinSevenDays
        )
    }
}
