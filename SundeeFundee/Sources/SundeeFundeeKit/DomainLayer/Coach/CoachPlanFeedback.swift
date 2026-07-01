import Foundation

public enum CoachPlanFeedbackRating: String, Codable, Sendable, Equatable {
    case helpful
    case notHelpful
}

public struct CoachPlanFeedbackRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let ratingRaw: String
    public let surface: String
    public let workoutID: String?
    public let copySource: String
    public let promptVersion: String
    public let reasonCodesJSON: String?
    public let dateCreated: Date

    public var rawPrompt: String? { nil }
    public var rawOutput: String? { nil }

    public init(
        id: String = UUID().uuidString,
        rating: CoachPlanFeedbackRating,
        surface: String,
        workoutID: String?,
        copySource: String,
        promptVersion: String,
        reasonCodesJSON: String?,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.ratingRaw = rating.rawValue
        self.surface = surface
        self.workoutID = workoutID
        self.copySource = copySource
        self.promptVersion = promptVersion
        self.reasonCodesJSON = reasonCodesJSON
        self.dateCreated = dateCreated
    }
}
