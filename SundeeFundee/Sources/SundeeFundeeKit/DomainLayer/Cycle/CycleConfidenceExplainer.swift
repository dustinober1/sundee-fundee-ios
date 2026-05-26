import Foundation

public struct CycleConfidenceExplanation: Sendable, Equatable {
    public let label: String
    public let description: String
    public let actionTitle: String

    public init(label: String, description: String, actionTitle: String) {
        self.label = label
        self.description = description
        self.actionTitle = actionTitle
    }
}

public enum CycleConfidenceExplainer {
    public static func explain(confidence: Double?) -> CycleConfidenceExplanation {
        guard let confidence else {
            return CycleConfidenceExplanation(
                label: "No Confidence Yet",
                description: "Cycle phase confidence is unavailable until more cycle data is logged.",
                actionTitle: "Log Period Dates"
            )
        }

        if confidence >= 0.7 {
            return CycleConfidenceExplanation(
                label: "High Confidence",
                description: "Recent cycle data supports a strong phase estimate.",
                actionTitle: "Keep Logging"
            )
        }

        if confidence >= 0.4 {
            return CycleConfidenceExplanation(
                label: "Medium Confidence",
                description: "The estimate is usable but can improve with more recent cycle entries.",
                actionTitle: "Add Recent Cycle Data"
            )
        }

        return CycleConfidenceExplanation(
            label: "Low Confidence",
            description: "Phase guidance may be noisy right now due to limited or stale cycle data.",
            actionTitle: "Update Cycle Tracking"
        )
    }
}
