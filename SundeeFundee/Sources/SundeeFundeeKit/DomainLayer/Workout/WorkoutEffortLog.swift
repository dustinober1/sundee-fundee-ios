import Foundation

public struct WorkoutEffortLog: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let workoutID: String
    public let exerciseName: String?
    public let setID: String?
    public let rpe: Int
    public let note: String?
    public let dateCreated: Date

    public init(
        id: String = UUID().uuidString,
        workoutID: String,
        exerciseName: String?,
        setID: String?,
        rpe: Int,
        note: String? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.workoutID = workoutID
        self.exerciseName = exerciseName
        self.setID = setID
        self.rpe = min(10, max(1, rpe))
        self.note = note
        self.dateCreated = dateCreated
    }
}
