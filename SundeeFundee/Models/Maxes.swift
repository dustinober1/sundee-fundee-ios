import SwiftData
import Foundation

@Model
final class OneRepMax {
    var id: String
    var userID: String
    var exerciseID: String
    var weightKg: Double
    var date: Date
    var isEstimated: Bool  // true = Epley formula, false = actual tested max

    init(
        id: String,
        userID: String,
        exerciseID: String,
        weightKg: Double,
        date: Date = .now,
        isEstimated: Bool = false
    ) {
        self.id = id
        self.userID = userID
        self.exerciseID = exerciseID
        self.weightKg = weightKg
        self.date = date
        self.isEstimated = isEstimated
    }
}

enum RepMaxType: String, Codable {
    case one = "1RM"
    case three = "3RM"
    case five = "5RM"
}

@Model
final class PersonalRecord {
    var id: String
    var userID: String
    var exerciseID: String
    var repMaxTypeRaw: String
    var weightKg: Double
    var reps: Int
    var achievedAt: Date
    var workoutID: String?

    init(
        id: String,
        userID: String,
        exerciseID: String,
        repMaxType: RepMaxType,
        weightKg: Double,
        reps: Int,
        achievedAt: Date = .now,
        workoutID: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.exerciseID = exerciseID
        self.repMaxTypeRaw = repMaxType.rawValue
        self.weightKg = weightKg
        self.reps = reps
        self.achievedAt = achievedAt
        self.workoutID = workoutID
    }

    var repMaxType: RepMaxType {
        get { RepMaxType(rawValue: repMaxTypeRaw) ?? .one }
        set { repMaxTypeRaw = newValue.rawValue }
    }
}

/// Historical lift max (user manually entered max, not auto-detected).
@Model
final class LiftMax {
    var id: String
    var userID: String
    var exerciseID: String
    var weightKg: Double
    var date: Date

    init(id: String, userID: String, exerciseID: String, weightKg: Double, date: Date = .now) {
        self.id = id
        self.userID = userID
        self.exerciseID = exerciseID
        self.weightKg = weightKg
        self.date = date
    }
}
