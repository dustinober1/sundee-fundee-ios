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
    var scoringType: String
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
        self.scoringType = scoringType.rawValue
        self.isPredefined = isPredefined
        self.sortOrder = sortOrder
    }

    var resolvedScoringType: BenchmarkScoringType {
        BenchmarkScoringType(rawValue: scoringType) ?? .time
    }
}
