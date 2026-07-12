import Foundation

public enum DeloadMode: String, Codable, Sendable, Equatable { case normal, reduced, activeRecovery }
public enum DeloadReasonCode: String, Codable, Sendable, Equatable, Hashable { case lowReadiness, highTrainingLoad, highPain, recentDeload }
public enum RecentTrainingLoadEvidence: String, Codable, Sendable, Equatable { case balanced, elevated, excessive }
public enum DeloadHistory: String, Codable, Sendable, Equatable { case none, recent }
public enum DeloadDecisionError: Error, Sendable, Equatable { case invalidMultiplier }

public struct DeloadDecision: Codable, Sendable, Equatable {
    public let mode: DeloadMode
    public let volumeMultiplier: Double
    public let intensityMultiplier: Double
    public let reasonCodes: [DeloadReasonCode]
    public let confidence: ReadinessConfidence

    public init(mode: DeloadMode, volumeMultiplier: Double, intensityMultiplier: Double, reasonCodes: [DeloadReasonCode], confidence: ReadinessConfidence) throws {
        guard volumeMultiplier.isFinite, intensityMultiplier.isFinite,
              (0...1).contains(volumeMultiplier), (0...1).contains(intensityMultiplier) else { throw DeloadDecisionError.invalidMultiplier }
        self.mode = mode; self.volumeMultiplier = volumeMultiplier; self.intensityMultiplier = intensityMultiplier
        self.reasonCodes = reasonCodes; self.confidence = confidence
    }
}

/// Deterministic contract for turning today's readiness evidence into programming mode.
public enum DeloadDecisionService {
    public static func evaluate(assessment: ReadinessAssessment, trainingLoad: RecentTrainingLoadEvidence, painSeverity: Int, history: DeloadHistory) -> DeloadDecision {
        let pain = max(0, painSeverity)
        var reasons: [DeloadReasonCode] = []
        if assessment.state.rank <= ReadinessState.recover.rank { reasons.append(.lowReadiness) }
        if trainingLoad != .balanced { reasons.append(.highTrainingLoad) }
        if pain >= 7 { reasons.append(.highPain) }
        if history == .recent { reasons.append(.recentDeload) }

        let mode: DeloadMode
        if pain >= 7 || assessment.state == .rest { mode = .activeRecovery }
        else if trainingLoad != .balanced || assessment.state == .recover || history == .recent { mode = .reduced }
        else { mode = .normal }
        let multipliers: (Double, Double) = {
            switch mode { case .normal: (1, 1); case .reduced: (0.7, 0.8); case .activeRecovery: (0.4, 0.6) }
        }()
        let confidence: ReadinessConfidence = assessment.confidence
        return try! DeloadDecision(mode: mode, volumeMultiplier: multipliers.0, intensityMultiplier: multipliers.1, reasonCodes: reasons, confidence: confidence)
    }
}
