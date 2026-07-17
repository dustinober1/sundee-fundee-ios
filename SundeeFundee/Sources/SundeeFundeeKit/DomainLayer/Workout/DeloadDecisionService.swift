import Foundation

/// Conservative, deterministic policy for today's training dose.
public enum DeloadDecisionService {
    public static func evaluate(
        readiness: ReadinessAssessment,
        trainingLoad: RecentTrainingLoadEvidence,
        pain: Int,
        history: DeloadHistory
    ) -> DeloadDecision {
        let clampedPain = min(10, max(0, pain))
        var reasons: [DeloadReasonCode] = []
        if readiness.state.rank <= ReadinessState.recover.rank { reasons.append(.lowReadiness) }
        if trainingLoad != .balanced { reasons.append(.highTrainingLoad) }
        if clampedPain >= 7 { reasons.append(.highPain) }
        if history == .recent { reasons.append(.recentDeload) }

        let mode: DeloadMode
        if clampedPain >= 7 || readiness.state == .rest {
            mode = .activeRecovery
        } else if readiness.confidence == .low || readiness.state == .recover || trainingLoad != .balanced || history == .recent {
            mode = .reduced
        } else {
            mode = .normal
        }

        let multipliers: (Double, Double) = switch mode {
        case .normal: (1.0, 1.0)
        case .reduced: (0.7, 0.8)
        case .activeRecovery: (0.4, 0.6)
        }
        // The initializer enforces the bounded invariant; this policy only uses constants in range.
        guard let decision = try? DeloadDecision(
            mode: mode,
            volumeMultiplier: multipliers.0,
            intensityMultiplier: multipliers.1,
            reasonCodes: reasons,
            confidence: readiness.confidence
        ) else {
            preconditionFailure("Deload policy produced invalid multipliers")
        }
        return decision
    }

    /// Compatibility spelling used by earlier callers.
    public static func evaluate(assessment: ReadinessAssessment, trainingLoad: RecentTrainingLoadEvidence, painSeverity: Int, history: DeloadHistory) -> DeloadDecision {
        evaluate(readiness: assessment, trainingLoad: trainingLoad, pain: painSeverity, history: history)
    }
}
