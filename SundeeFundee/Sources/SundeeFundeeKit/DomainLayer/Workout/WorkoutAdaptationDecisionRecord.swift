import Foundation

public struct WorkoutAdaptationDecisionRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let workoutID: String
    public let originalWorkoutJSON: String
    public let adaptedWorkoutJSON: String
    public let reasonIDs: [String]
    public let reasonText: [String]
    public let dateCreated: Date

    public init(
        id: String = UUID().uuidString,
        workoutID: String,
        originalWorkoutJSON: String,
        adaptedWorkoutJSON: String,
        reasonIDs: [String],
        reasonText: [String],
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.workoutID = workoutID
        self.originalWorkoutJSON = originalWorkoutJSON
        self.adaptedWorkoutJSON = adaptedWorkoutJSON
        self.reasonIDs = reasonIDs
        self.reasonText = reasonText
        self.dateCreated = dateCreated
    }
}
