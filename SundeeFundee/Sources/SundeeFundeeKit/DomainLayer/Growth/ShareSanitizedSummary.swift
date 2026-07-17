import Foundation

/// Safe, presentation-only metadata intended for sharing. Deliberately contains no
/// HealthKit values, cycle or pain data, private notes, prompts, or generated copy.
public struct ShareSanitizedSummary: Codable, Sendable, Equatable {
    public let title: String
    public let subtitle: String?
    public let metricLabel: String?
    public let metricValue: String?
    public let modelVersion: String

    public enum ValidationError: Error, Sendable, Equatable { case emptyTitle, emptyModelVersion, unsafeContent }

    /// Builds the privacy-safe readiness card payload from the persisted snapshot.
    /// Only the derived state and score cross the share boundary; no source signals
    /// (HealthKit, cycle, pain, or notes) are included.
    public init(readinessSnapshot: DailyReadinessSnapshot) throws {
        let state = readinessSnapshot.stateRaw
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        try self.init(
            title: "Today's readiness",
            subtitle: state,
            metricLabel: "Readiness",
            metricValue: "\(readinessSnapshot.totalScore) / 100",
            modelVersion: readinessSnapshot.modelVersion
        )
    }

    /// Builds the deload outcome card without exposing the underlying pain,
    /// sleep, cycle, or readiness signals that produced the recommendation.
    public init(deloadRecommendation: DeloadRecommendation, modelVersion: String = "deload-2.0") throws {
        try self.init(
            title: deloadRecommendation.isRecommended ? "Active recovery recommended" : "Training on track",
            subtitle: deloadRecommendation.isRecommended
                ? "A lighter session may help you recover"
                : "No deload needed today",
            metricLabel: deloadRecommendation.isRecommended ? "Recommended days" : nil,
            metricValue: deloadRecommendation.isRecommended ? "\(deloadRecommendation.recommendedDays)" : nil,
            modelVersion: modelVersion
        )
    }
    public init(title: String, subtitle: String?, metricLabel: String?, metricValue: String?, modelVersion: String) throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !modelVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ValidationError.emptyTitle : ValidationError.emptyModelVersion
        }
        guard [title, subtitle, metricLabel, metricValue].compactMap({ $0 }).allSatisfy(Self.isSafeDisplayText) else {
            throw ValidationError.unsafeContent
        }
        self.title = title; self.subtitle = subtitle; self.metricLabel = metricLabel; self.metricValue = metricValue; self.modelVersion = modelVersion
    }

    private static func isSafeDisplayText(_ value: String) -> Bool {
        let normalized = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let prohibited = [
            "healthkit", "health kit", "cycle", "menstrual", "ovulation", "fertility", "period",
            "pain", "sore", "cramp", "symptom", "private note", "private-note", "prompt",
            "generated text", "generated-text", "ai-generated", "model output", "sleep", "hrv",
            "heart rate", "recovery score", "readiness score"
        ]
        guard prohibited.allSatisfy({ !normalized.contains($0) }) else { return false }
        return !value.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) }
    }

    private enum CodingKeys: String, CodingKey { case title, subtitle, metricLabel, metricValue, modelVersion }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            title: values.decode(String.self, forKey: .title),
            subtitle: values.decodeIfPresent(String.self, forKey: .subtitle),
            metricLabel: values.decodeIfPresent(String.self, forKey: .metricLabel),
            metricValue: values.decodeIfPresent(String.self, forKey: .metricValue),
            modelVersion: values.decode(String.self, forKey: .modelVersion)
        )
    }
}
