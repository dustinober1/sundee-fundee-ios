import Foundation
import SwiftData

/// Persisted record of an AI-generated workout.
/// Stored in SwiftData and synced via CloudKit private DB.
///
/// `GeneratedWorkout` (the domain struct) is serialized to JSON and stored in
/// `workoutJSON` to avoid CloudKit enum constraints and nested-model complexity.
@Model
final class GeneratedWorkoutRecord {
    var id: String
    var userID: String
    var createdAt: Date
    var isFavorite: Bool
    /// JSON-encoded `GeneratedWorkout` struct.
    var workoutJSON: String
    var isCompleted: Bool
    var contributedToDatabase: Bool

    init(id: String, userID: String, createdAt: Date, isFavorite: Bool, workoutJSON: String, isCompleted: Bool = false, contributedToDatabase: Bool = false) {
        self.id = id
        self.userID = userID
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.workoutJSON = workoutJSON
        self.isCompleted = isCompleted
        self.contributedToDatabase = contributedToDatabase
    }

    /// Decodes the stored JSON back into the domain struct.
    func toGeneratedWorkout() -> GeneratedWorkout? {
        guard let data = workoutJSON.data(using: .utf8) else { return nil }
        var workout = try? JSONDecoder().decode(GeneratedWorkout.self, from: data)
        workout?.isFavorite = isFavorite
        workout?.isCompleted = isCompleted
        return workout
    }

    /// Creates a record from a domain struct.
    static func from(_ workout: GeneratedWorkout, userID: String, isCompleted: Bool = false, contributedToDatabase: Bool = false) -> GeneratedWorkoutRecord? {
        guard let data = try? JSONEncoder().encode(workout),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return GeneratedWorkoutRecord(
            id: workout.id,
            userID: userID,
            createdAt: workout.createdAt,
            isFavorite: workout.isFavorite,
            workoutJSON: json,
            isCompleted: isCompleted,
            contributedToDatabase: contributedToDatabase
        )
    }
}
