import Foundation

public struct WorkoutCompletionCheckInRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let workoutID: String
    public let sessionRPE: Int?
    public let soreness: Int
    public let pain: Int
    public let wasRightForToday: Bool
    public let dateCreated: Date

    public init(
        id: String = UUID().uuidString,
        workoutID: String,
        sessionRPE: Int?,
        soreness: Int,
        pain: Int,
        wasRightForToday: Bool,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.workoutID = workoutID
        self.sessionRPE = sessionRPE
        self.soreness = soreness
        self.pain = pain
        self.wasRightForToday = wasRightForToday
        self.dateCreated = dateCreated
    }
}
