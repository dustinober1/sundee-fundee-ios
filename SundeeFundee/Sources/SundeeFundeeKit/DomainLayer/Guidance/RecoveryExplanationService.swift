import Foundation

public struct RecoveryExplanation: Sendable, Equatable, Identifiable {
    public let input: RecoveryInput?
    public let text: String

    public var id: String {
        if let input {
            return input.rawValue + ":" + text
        }
        return "general:" + text
    }

    public init(input: RecoveryInput?, text: String) {
        self.input = input
        self.text = text
    }
}

public enum RecoveryExplanationService {
    public static func topExplanations(
        from score: RecoveryScore?,
        limit: Int = 3
    ) -> [RecoveryExplanation] {
        guard let score else {
            return [
                RecoveryExplanation(
                    input: nil,
                    text: "Connect sleep or HRV data and log pain to improve today's recovery guidance."
                )
            ]
        }

        var candidates: [(priority: Int, explanation: RecoveryExplanation)] = []
        for input in RecoveryInput.allCases {
            guard let explanation = score.explanations[input] else { continue }
            let value = score.subScores[input] ?? 50
            let priority = max(0, 100 - value)
            candidates.append((
                priority: priority,
                explanation: RecoveryExplanation(
                    input: input,
                    text: sanitizedExplanation(explanation, input: input)
                )
            ))
        }

        let sorted = candidates.sorted { lhs, rhs in
            if lhs.priority == rhs.priority {
                return lhs.explanation.text < rhs.explanation.text
            }
            return lhs.priority > rhs.priority
        }

        var output = Array(sorted.prefix(limit).map(\.explanation))
        if score.presentInputCount < score.totalInputCount {
            output.append(
                RecoveryExplanation(
                    input: nil,
                    text: "Add missing inputs (sleep, HRV, cycle, pain, or recent training) for a sharper recommendation."
                )
            )
        }
        return Array(output.prefix(limit))
    }

    private static func sanitizedExplanation(
        _ text: String,
        input: RecoveryInput
    ) -> String {
        let lower = text.lowercased()
        let containsInternal = lower.contains("hkerrordomain")
            || lower.contains("localizeddescription")
            || lower.contains("cloudkit")
            || lower.contains("healthkit")
            || lower.contains("error domain")

        guard containsInternal else { return text }

        switch input {
        case .sleep:
            return "Sleep data is missing or incomplete today."
        case .hrv:
            return "HRV data is missing or incomplete today."
        case .trainingLoad:
            return "Recent training load data is limited."
        case .cyclePhase:
            return "Cycle context is limited right now."
        case .pain:
            return "Pain check-in data is limited right now."
        }
    }
}
