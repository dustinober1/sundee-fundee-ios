import Foundation

public enum DeloadMode: String, Codable, Sendable, Equatable {
    case normal, reduced, activeRecovery

    /// Design terminology aliases retained alongside the original wire values.
    public static var maintain: Self { .normal }
    public static var reduce: Self { .reduced }
}
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

    private enum CodingKeys: String, CodingKey { case mode, volumeMultiplier, intensityMultiplier, reasonCodes, confidence }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            mode: values.decode(DeloadMode.self, forKey: .mode),
            volumeMultiplier: values.decode(Double.self, forKey: .volumeMultiplier),
            intensityMultiplier: values.decode(Double.self, forKey: .intensityMultiplier),
            reasonCodes: values.decode([DeloadReasonCode].self, forKey: .reasonCodes),
            confidence: values.decode(ReadinessConfidence.self, forKey: .confidence)
        )
    }
}
