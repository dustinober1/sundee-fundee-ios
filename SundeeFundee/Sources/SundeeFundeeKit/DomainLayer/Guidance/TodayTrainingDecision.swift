import Foundation

public enum TodayTrainingDecisionKind: String, Codable, Sendable, Equatable {
    case train
    case modify
    case recover
}

public struct TodayTrainingDecision: Sendable, Equatable {
    public let kind: TodayTrainingDecisionKind
    public let title: String
    public let subtitle: String
    public let reasons: [String]
    public let primaryActionTitle: String
    public let systemImage: String

    public init(
        kind: TodayTrainingDecisionKind,
        title: String,
        subtitle: String,
        reasons: [String],
        primaryActionTitle: String,
        systemImage: String
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.reasons = reasons
        self.primaryActionTitle = primaryActionTitle
        self.systemImage = systemImage
    }
}
