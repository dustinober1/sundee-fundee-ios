import Foundation

public enum CoachPromptVersion: String, Codable, Sendable {
    case workoutSummaryV17 = "workout_summary_v1_7"
    case insightsSummaryV17 = "insights_summary_v1_7"
    case planExplanationV17 = "plan_explanation_v1_7"
}

public enum CoachPromptPack {
    public static let copyEditorInstructions = """
    You are a concise fitness copy editor for Sundee Fundee.
    You only rewrite deterministic coaching facts into friendly copy.
    Never add exercises, weights, reps, percentages, medical advice, or new recommendations.
    Return exactly the requested structure.
    """

    public static func workoutSummaryPrompt(packet: CoachDecisionPacket) -> String {
        """
        Version: \(packet.promptVersion)
        Task: Rewrite deterministic workout facts into exactly 2 short sentences.
        Hard rules:
        - Do not create exercises.
        - Do not mention weights, reps, percentages, sets, or medical advice.
        - Do not mention injuries directly; say "movement constraints" if needed.
        - Use only supplied facts.
        - Max 220 characters.
        Facts:
        \(packet.sanitizedForPrompt())
        """
    }

    public static func insightsSummaryPrompt(packet: CoachDecisionPacket) -> String {
        """
        Version: \(packet.promptVersion)
        Task: Rewrite deterministic insight facts into no more than 3 short sentences.
        Hard rules:
        - Do not create exercises or new recommendations.
        - Do not mention medical advice.
        - Use only supplied facts.
        Facts:
        \(packet.sanitizedForPrompt())
        """
    }

    public static func planExplanationPrompt(packet: CoachDecisionPacket) -> String {
        """
        Version: \(packet.promptVersion)
        Task: Rewrite deterministic weekly-plan facts into no more than 2 short sentences.
        Hard rules:
        - Do not add plan changes.
        - Do not mention medical advice.
        - Use only supplied facts.
        Facts:
        \(packet.sanitizedForPrompt())
        """
    }
}
