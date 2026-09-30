import Foundation

public struct AutoregulationAdjustment: Sendable, Equatable {
    public enum Action: String, Sendable, Equatable {
        case reduceWeight
        case increaseWeight
        case maintain
    }

    public let action: Action
    public let adjustedWeight: Double?
    public let reason: String

    public init(action: Action, adjustedWeight: Double?, reason: String) {
        self.action = action
        self.adjustedWeight = adjustedWeight
        self.reason = reason
    }
}

public enum AutoregulationService {
    /// Evaluates completed set performance and RPE to determine if subsequent sets should be adjusted.
    public static func evaluate(
        completedReps: Int,
        targetReps: Int,
        completedWeight: Double,
        rpe: Int?,
        unit: WeightUnit = .lbs
    ) -> AutoregulationAdjustment {
        guard completedWeight > 0 else {
            return AutoregulationAdjustment(action: .maintain, adjustedWeight: nil, reason: "Bodyweight movement maintained.")
        }

        let increment = unit == .kg ? 2.5 : 5.0
        let effectiveRPE = rpe ?? 8

        // Extreme strain or missed reps
        if effectiveRPE >= 10 || completedReps < targetReps - 1 {
            let reduced = max(increment, roundToNearest(completedWeight * 0.90, increment: increment))
            return AutoregulationAdjustment(
                action: .reduceWeight,
                adjustedWeight: reduced,
                reason: "High fatigue detected (RPE \(effectiveRPE)). Adjusting subsequent sets to \(Int(reduced)) \(unit.rawValue) to maintain form."
            )
        }

        // Submaximal / warm-up effort (RPE <= 6 and all reps completed)
        if effectiveRPE <= 6 && completedReps >= targetReps {
            let increased = completedWeight + increment
            return AutoregulationAdjustment(
                action: .increaseWeight,
                adjustedWeight: increased,
                reason: "Set moved easily (RPE \(effectiveRPE)). Adjusting subsequent sets to \(Int(increased)) \(unit.rawValue)."
            )
        }

        return AutoregulationAdjustment(
            action: .maintain,
            adjustedWeight: completedWeight,
            reason: "Target intensity achieved (RPE \(effectiveRPE)). Maintaining current weight."
        )
    }
}
