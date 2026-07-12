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
