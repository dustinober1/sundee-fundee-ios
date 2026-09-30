import Foundation

// MARK: - GoalMilestone

public enum GoalMilestone: String, Sendable, Equatable {
    case started
    case halfway
    case almostThere
    case goalCrushed

    public var badgeTitle: String {
        switch self {
        case .started: return "In Motion"
        case .halfway: return "Halfway Mark"
        case .almostThere: return "Final Stretch"
        case .goalCrushed: return "Goal Crushed!"
        }
    }

    public var badgeEmoji: String {
        switch self {
        case .started: return "🌱"
        case .halfway: return "⚡️"
        case .almostThere: return "🔥"
        case .goalCrushed: return "🏆"
        }
    }
}

// MARK: - PodGoalProgress

public struct PodGoalProgress: Sendable, Equatable {
    public let totalCompleted: Int
    public let target: Int
    public let fractionComplete: Double
    public let remainingNeeded: Int
    public let isCompleted: Bool
    public let milestone: GoalMilestone

    public var headline: String {
        if isCompleted {
            return "Weekly goal crushed! (\(totalCompleted)/\(target))"
        } else {
            return "\(remainingNeeded) more workout\(remainingNeeded == 1 ? "" : "s") to hit our goal"
        }
    }

    public init(
        totalCompleted: Int,
        target: Int,
        fractionComplete: Double,
        remainingNeeded: Int,
        isCompleted: Bool,
        milestone: GoalMilestone
    ) {
        self.totalCompleted = totalCompleted
        self.target = target
        self.fractionComplete = fractionComplete
        self.remainingNeeded = remainingNeeded
        self.isCompleted = isCompleted
        self.milestone = milestone
    }
}

// MARK: - GroupGoalEvaluator

public enum GroupGoalEvaluator {
    public static func evaluate(pod: AccountabilityPod) -> PodGoalProgress {
        let total = pod.totalWorkoutsCompleted
        let target = max(1, pod.weeklyGoal.targetWorkouts)
        let fraction = min(1.0, Double(total) / Double(target))
        let remaining = max(0, target - total)
        let isDone = total >= target

        let milestone: GoalMilestone
        if isDone {
            milestone = .goalCrushed
        } else if fraction >= 0.8 {
            milestone = .almostThere
        } else if fraction >= 0.5 {
            milestone = .halfway
        } else {
            milestone = .started
        }

        return PodGoalProgress(
            totalCompleted: total,
            target: target,
            fractionComplete: fraction,
            remainingNeeded: remaining,
            isCompleted: isDone,
            milestone: milestone
        )
    }
}
