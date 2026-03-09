import SwiftData
import Foundation

@Model
final class ExerciseBarMapping {
    var id: String
    var userID: String
    var exerciseName: String
    var barbellPresetID: String

    init(
        id: String = UUID().uuidString,
        userID: String,
        exerciseName: String,
        barbellPresetID: String
    ) {
        self.id = id
        self.userID = userID
        self.exerciseName = exerciseName
        self.barbellPresetID = barbellPresetID
    }
}
