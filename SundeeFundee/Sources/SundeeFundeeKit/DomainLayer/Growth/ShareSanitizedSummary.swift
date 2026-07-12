import Foundation

/// Safe, presentation-only metadata intended for sharing. Deliberately contains no
/// HealthKit values, cycle or pain data, private notes, prompts, or generated copy.
public struct ShareSanitizedSummary: Codable, Sendable, Equatable {
    public let title: String
    public let subtitle: String?
    public let metricLabel: String?
    public let metricValue: String?
    public let modelVersion: String

    public enum ValidationError: Error, Sendable, Equatable { case emptyTitle, emptyModelVersion }
    public init(title: String, subtitle: String?, metricLabel: String?, metricValue: String?, modelVersion: String) throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !modelVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ValidationError.emptyTitle : ValidationError.emptyModelVersion
        }
        self.title = title; self.subtitle = subtitle; self.metricLabel = metricLabel; self.metricValue = metricValue; self.modelVersion = modelVersion
    }
}
