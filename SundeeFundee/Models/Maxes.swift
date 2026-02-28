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

/// Auto-detected conditioning personal record (reps-based or time-based).
@Model
final class ConditioningPR {
    var id: String
    var userID: String
    var exerciseID: String
    var scoringTypeRaw: String       // "time" or "reps" — CloudKit-safe
    var bestValue: Double            // seconds for time, count for reps
    var weightKg: Double?            // optional: for weighted conditioning
    var achievedAt: Date
    var workoutID: String?

    init(
        id: String,
        userID: String,
        exerciseID: String,
        scoringType: ConditioningScoringType,
        bestValue: Double,
        weightKg: Double? = nil,
        achievedAt: Date = .now,
        workoutID: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.exerciseID = exerciseID
        self.scoringTypeRaw = scoringType.rawValue
        self.bestValue = bestValue
        self.weightKg = weightKg
        self.achievedAt = achievedAt
        self.workoutID = workoutID
    }

    var scoringType: ConditioningScoringType {
        get { ConditioningScoringType(rawValue: scoringTypeRaw) ?? .reps }
        set { scoringTypeRaw = newValue.rawValue }
    }
}
