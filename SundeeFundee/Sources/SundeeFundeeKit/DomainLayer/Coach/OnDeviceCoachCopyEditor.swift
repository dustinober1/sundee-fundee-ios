import Foundation

public protocol CoachCopyEditing: Sendable {
    func rewriteWorkoutSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate
    func rewriteInsightsSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate
    func rewritePlanExplanation(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate
}

public struct CoachCopyCandidate: Sendable, Equatable {
    public let summary: String
    public let tips: [String]
    public let promptVersion: String
    public let rawOutput: String?

    public init(summary: String, tips: [String] = [], promptVersion: String, rawOutput: String? = nil) {
        self.summary = summary
        self.tips = tips
        self.promptVersion = promptVersion
        self.rawOutput = rawOutput
    }
}

public enum CoachCopyEditingError: Error, Sendable, Equatable {
    case unavailable
}

public final class OnDeviceCoachCopyEditor: CoachCopyEditing, @unchecked Sendable {
    public init() {}
    public func rewriteWorkoutSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { throw CoachCopyEditingError.unavailable }
    public func rewriteInsightsSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { throw CoachCopyEditingError.unavailable }
    public func rewritePlanExplanation(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { throw CoachCopyEditingError.unavailable }
}
