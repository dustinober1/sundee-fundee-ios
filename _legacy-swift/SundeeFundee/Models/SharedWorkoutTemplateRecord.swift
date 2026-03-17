import SwiftData
import Foundation

/// Local CloudKit cache of shared workout templates from the public database.
/// Users can browse and start these shared workouts without creating their own.
@Model
final class SharedWorkoutTemplateRecord {
    @Attribute(.unique) var id: String  // CloudKit record name
    var userID: String                  // empty string for public workouts
    var createdAt: Date
    var downloadedAt: Date
    /// JSON-encoded shared workout template (same format as GeneratedWorkout)
    var workoutJSON: String
    var focusRaw: String
    var durationMinutes: Int
    var equipmentRaw: String

    init(
        id: String,
        userID: String,
        createdAt: Date,
        downloadedAt: Date,
        workoutJSON: String,
        focusRaw: String,
        durationMinutes: Int,
        equipmentRaw: String
    ) {
        self.id = id
        self.userID = userID
        self.createdAt = createdAt
        self.downloadedAt = downloadedAt
        self.workoutJSON = workoutJSON
        self.focusRaw = focusRaw
        self.durationMinutes = durationMinutes
        self.equipmentRaw = equipmentRaw
    }
}
