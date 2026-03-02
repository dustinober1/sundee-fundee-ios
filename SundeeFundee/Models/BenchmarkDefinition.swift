import SwiftData
import Foundation

/// Scoring category for a benchmark workout.
/// Determines how the result is displayed and which input field is shown when logging.
enum BenchmarkScoringType: String, Codable, CaseIterable {
    /// Lower is better — stored as total seconds (Double).
    case time
    /// Higher is better — stored as whole number cast to Double.
    case reps
    /// Higher is better — stored as kilograms (Double).
    case weight
    /// Fixed distance, logged as time in seconds — lower is better.
    case distance
    /// AMRAP-style — stored as rounds * 10000 + reps (Double). Higher is better.
    case roundsAndReps
}

/// A named benchmark workout definition — either predefined (ships with the app)
/// or user-created (stored in SwiftData with a non-empty userID).
@Model
final class BenchmarkDefinition {
    var id: String
    /// Empty string for predefined catalog entries; user's ID for custom definitions.
    var userID: String
    var name: String
    var category: String
    var workoutDescription: String
    /// Raw value of `BenchmarkScoringType`.
    var scoringTypeRaw: String
    var isPredefined: Bool
    var sortOrder: Int

    init(
        id: String = UUID().uuidString,
        userID: String,
        name: String,
        category: String,
        workoutDescription: String,
        scoringType: BenchmarkScoringType,
        isPredefined: Bool,
        sortOrder: Int
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.category = category
        self.workoutDescription = workoutDescription
        self.scoringTypeRaw = scoringType.rawValue
        self.isPredefined = isPredefined
        self.sortOrder = sortOrder
    }

    var scoringType: BenchmarkScoringType {
        // Falls back to .time for unknown raw values (e.g. future enum cases on old records).
        assert(BenchmarkScoringType(rawValue: scoringTypeRaw) != nil, "Unknown BenchmarkScoringType raw value: \(scoringTypeRaw)")
        return BenchmarkScoringType(rawValue: scoringTypeRaw) ?? .time
    }
}
