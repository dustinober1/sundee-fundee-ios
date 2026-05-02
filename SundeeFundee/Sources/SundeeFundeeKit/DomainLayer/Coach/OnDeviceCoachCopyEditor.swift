import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

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

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, *)
public final class OnDeviceCoachCopyEditor: CoachCopyEditing, @unchecked Sendable {
    public init() {}

    public func rewriteWorkoutSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate {
        let output = try await generate(prompt: CoachPromptPack.workoutSummaryPrompt(packet: packet))
        return parse(output, promptVersion: packet.promptVersion)
    }

    public func rewriteInsightsSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate {
        let output = try await generate(prompt: CoachPromptPack.insightsSummaryPrompt(packet: packet))
        return parse(output, promptVersion: packet.promptVersion)
    }

    public func rewritePlanExplanation(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate {
        let output = try await generate(prompt: CoachPromptPack.planExplanationPrompt(packet: packet))
        return parse(output, promptVersion: packet.promptVersion)
    }

    private func generate(prompt: String) async throws -> String {
        let session = LanguageModelSession(instructions: CoachPromptPack.copyEditorInstructions)
        let response = try await session.respond(to: prompt)
        return String(response.content)
    }

    private func parse(_ output: String, promptVersion: String) -> CoachCopyCandidate {
        let lines = output.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return CoachCopyCandidate(summary: lines.first ?? output, tips: Array(lines.dropFirst().prefix(3)), promptVersion: promptVersion, rawOutput: output)
    }
}

// Typed Foundation Models responses are intentionally not compiled here yet:
// the active SDK exposes the macros behind iOS/macOS 26 availability, and
// plain string generation keeps this wrapper source-compatible while still
// requiring strict validation at the call site.
#else
public final class OnDeviceCoachCopyEditor: CoachCopyEditing, @unchecked Sendable {
    public init() {}
    public func rewriteWorkoutSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { throw CoachCopyEditingError.unavailable }
    public func rewriteInsightsSummary(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { throw CoachCopyEditingError.unavailable }
    public func rewritePlanExplanation(packet: CoachDecisionPacket) async throws -> CoachCopyCandidate { throw CoachCopyEditingError.unavailable }
}
#endif
