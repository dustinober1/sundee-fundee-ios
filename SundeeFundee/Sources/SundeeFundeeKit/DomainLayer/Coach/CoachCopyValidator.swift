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
    case containsVisibleAILanguage
    case containsDiscouragedTone(String)
    case overstatesCycleCertainty(String)
    case missingLowConfidenceQualifier
    case containsUnsafeExtraLines
    case containsModelSuppliedTips
}

public enum CoachCopyValidator {
    public static func validateWorkoutSummary(
        _ candidate: CoachCopyCandidate,
        packet: CoachDecisionPacket
    ) -> [CoachCopyValidationIssue] {
        validate(candidate, packet: packet, maxCharacters: 220, maxSentences: 2, allowExerciseMentions: true)
    }

    public static func validateInsightsSummary(
        _ candidate: CoachCopyCandidate,
        packet: CoachDecisionPacket
    ) -> [CoachCopyValidationIssue] {
        validate(candidate, packet: packet, maxCharacters: 420, maxSentences: 3, allowExerciseMentions: true)
    }

    public static func validatePlanExplanation(
        _ candidate: CoachCopyCandidate,
        packet: CoachDecisionPacket
    ) -> [CoachCopyValidationIssue] {
        validate(candidate, packet: packet, maxCharacters: 320, maxSentences: 2, allowExerciseMentions: false)
    }

    private static func validate(
        _ candidate: CoachCopyCandidate,
        packet: CoachDecisionPacket,
        maxCharacters: Int,
        maxSentences: Int,
        allowExerciseMentions: Bool
    ) -> [CoachCopyValidationIssue] {
        let text = candidate.summary
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var issues: [CoachCopyValidationIssue] = []
        if trimmed.isEmpty { issues.append(.empty) }
        if trimmed.count > maxCharacters { issues.append(.tooLong(max: maxCharacters)) }
        if sentenceCount(trimmed) > maxSentences { issues.append(.tooManySentences(max: maxSentences)) }
        if containsUnsafeExtraLines(text) { issues.append(.containsUnsafeExtraLines) }
        if !candidate.tips.isEmpty { issues.append(.containsModelSuppliedTips) }
        if mentionsWeightsRepsOrPercentages(trimmed) { issues.append(.mentionsWeightsRepsOrPercentages) }
        if containsRawInjuryLanguage(trimmed) { issues.append(.containsRawInjuryLanguage) }
        if let term = medicalLanguage(in: trimmed) { issues.append(.containsMedicalAdviceLanguage(term)) }
        if containsUnsupportedRecommendation(trimmed) { issues.append(.containsUnsupportedRecommendation) }
        if containsVisibleAILanguage(trimmed) { issues.append(.containsVisibleAILanguage) }
        if let term = discouragedTone(in: trimmed) { issues.append(.containsDiscouragedTone(term)) }
        if let term = cycleCertaintyOverstatement(in: trimmed) { issues.append(.overstatesCycleCertainty(term)) }
        if needsLowConfidenceQualifier(trimmed, packet: packet) { issues.append(.missingLowConfidenceQualifier) }

        let allowed = Set(packet.allowedExerciseNames.map(normalized))
        for name in knownWorkoutExerciseNames().sorted() where !allowed.contains(normalized(name)) {
            if containsExerciseName(name, in: trimmed) {
                issues.append(.mentionsDisallowedExercise(name))
                break
            }
        }
        return issues
    }

    private static func containsUnsafeExtraLines(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).contains(where: { $0.isNewline })
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

    private static func containsVisibleAILanguage(_ text: String) -> Bool {
        let lower = text.lowercased()
        if ["artificial intelligence", "language model", "model output", "prompt", "generated by"].contains(where: { lower.contains($0) }) {
            return true
        }
        return lower.range(of: #"\bai\b"#, options: .regularExpression) != nil
    }

    private static func discouragedTone(in text: String) -> String? {
        let lower = text.lowercased()
        let banned = [
            "no excuses",
            "must push",
            "push harder",
            "earn it",
            "don't be lazy",
            "pain is weakness",
            "hurry",
            "urgent",
            "crush it",
            "beast mode",
            "destroy it",
            "go all out"
        ]
        return banned.first { lower.contains($0) }
    }

    private static func cycleCertaintyOverstatement(in text: String) -> String? {
        let lower = text.lowercased()
        let banned = ["guarantee", "guarantees", "guaranteed", "hormones will", "cycle will", "phase will", "will be stronger"]
        return banned.first { lower.contains($0) }
    }

    private static func needsLowConfidenceQualifier(_ text: String, packet: CoachDecisionPacket) -> Bool {
        guard packet.cyclePhase != nil, let confidence = packet.cycleConfidence, confidence < 0.7 else { return false }
        let lower = text.lowercased()
        let referencesCycle = ["cycle", "phase", "menstrual", "follicular", "ovulation", "luteal"].contains {
            lower.contains($0)
        }
        guard referencesCycle else { return false }
        return ![" may ", " can ", " might ", " could "].contains { lower.contains($0) || lower.hasPrefix($0.trimmingCharacters(in: .whitespaces) + " ") }
    }

    private static func containsExerciseName(_ exercise: String, in text: String) -> Bool {
        let pattern = #"(?i)(^|[^A-Za-z0-9])"# + NSRegularExpression.escapedPattern(for: exercise) + #"([^A-Za-z0-9]|$)"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
