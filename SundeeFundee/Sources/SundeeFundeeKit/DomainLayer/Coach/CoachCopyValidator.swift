import Foundation

public enum CoachCopyValidationIssue: Equatable, Sendable {
    case empty
    case tooLong(max: Int)
    case tooManySentences(max: Int)
    case mentionsDisallowedExercise(String)
    case mentionsWeightsRepsOrPercentages
    case containsMedicalAdviceLanguage(String)
    case containsRawInjuryLanguage
    case containsUnsupportedRecommendation
}

public enum CoachCopyValidator {
    public static func validateWorkoutSummary(
        _ candidate: CoachCopyCandidate,
        packet: CoachDecisionPacket
    ) -> [CoachCopyValidationIssue] {
        validate(candidate.summary, packet: packet, maxCharacters: 220, maxSentences: 2, allowExerciseMentions: true)
    }

    public static func validateInsightsSummary(
        _ candidate: CoachCopyCandidate,
        packet: CoachDecisionPacket
    ) -> [CoachCopyValidationIssue] {
        validate(candidate.summary, packet: packet, maxCharacters: 420, maxSentences: 3, allowExerciseMentions: true)
    }

    public static func validatePlanExplanation(
        _ candidate: CoachCopyCandidate,
        packet: CoachDecisionPacket
    ) -> [CoachCopyValidationIssue] {
        validate(candidate.summary, packet: packet, maxCharacters: 320, maxSentences: 2, allowExerciseMentions: false)
    }

    private static func validate(
        _ text: String,
        packet: CoachDecisionPacket,
        maxCharacters: Int,
        maxSentences: Int,
        allowExerciseMentions: Bool
    ) -> [CoachCopyValidationIssue] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var issues: [CoachCopyValidationIssue] = []
        if trimmed.isEmpty { issues.append(.empty) }
        if trimmed.count > maxCharacters { issues.append(.tooLong(max: maxCharacters)) }
        if sentenceCount(trimmed) > maxSentences { issues.append(.tooManySentences(max: maxSentences)) }
        if mentionsWeightsRepsOrPercentages(trimmed) { issues.append(.mentionsWeightsRepsOrPercentages) }
        if containsRawInjuryLanguage(trimmed) { issues.append(.containsRawInjuryLanguage) }
        if let term = medicalLanguage(in: trimmed) { issues.append(.containsMedicalAdviceLanguage(term)) }
        if containsUnsupportedRecommendation(trimmed) { issues.append(.containsUnsupportedRecommendation) }

        let allowed = Set(packet.allowedExerciseNames.map(normalized))
        for name in knownWorkoutExerciseNames().sorted() where !allowed.contains(normalized(name)) {
            if containsExerciseName(name, in: trimmed) {
                issues.append(.mentionsDisallowedExercise(name))
                break
            }
        }
        return issues
    }

    private static func sentenceCount(_ text: String) -> Int {
        let count = text.filter { ".!?".contains($0) }.count
        return max(text.isEmpty ? 0 : 1, count)
    }

    private static func mentionsWeightsRepsOrPercentages(_ text: String) -> Bool {
        let lower = text.lowercased()
        let banned = [" lbs", " lb", " kg", "%", " rep", " reps", " set", " sets"]
        if banned.contains(where: { lower.contains($0) }) { return true }
        return lower.range(of: #"\b\d+\s*(x|×)\s*\d+\b"#, options: .regularExpression) != nil
    }

    private static func medicalLanguage(in text: String) -> String? {
        let lower = text.lowercased()
        let banned = ["diagnose", "treat", "doctor", "medical", "safe for injury", "ignore pain", "push through pain"]
        if let term = banned.first(where: { lower.contains($0) }) { return term }
        if lower.range(of: #"safe\s+for\s+(your\s+)?injur"#, options: .regularExpression) != nil {
            return "safe for injury"
        }
        return nil
    }

    private static func containsRawInjuryLanguage(_ text: String) -> Bool {
        let lower = text.lowercased()
        return ["injury count", "active injury", "active injuries", "injured", "pain area"].contains { lower.contains($0) }
    }

    private static func containsUnsupportedRecommendation(_ text: String) -> Bool {
        let lower = text.lowercased()
        return ["you should add", "swap in", "replace with", "do extra", "skip your plan"].contains { lower.contains($0) }
    }

    private static func containsExerciseName(_ exercise: String, in text: String) -> Bool {
        let pattern = #"(?i)(^|[^A-Za-z0-9])"# + NSRegularExpression.escapedPattern(for: exercise) + #"([^A-Za-z0-9]|$)"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
