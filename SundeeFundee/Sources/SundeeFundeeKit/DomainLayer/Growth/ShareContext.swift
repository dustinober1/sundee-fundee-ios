import Foundation

public enum ShareSurface: String, Codable, Sendable {
    case completedWorkout
    case personalRecord
    case cycleInsight
    case challenge
    case starterWorkout
}

public struct ShareContext: Codable, Sendable, Equatable {
    public let surface: ShareSurface
    public let sourceID: String?
    public let title: String
    public let referralCode: String?

    public init(
        surface: ShareSurface,
        sourceID: String? = nil,
        title: String,
        referralCode: String? = nil
    ) {
        self.surface = surface
        self.sourceID = sourceID
        self.title = title
        self.referralCode = referralCode
    }
}
