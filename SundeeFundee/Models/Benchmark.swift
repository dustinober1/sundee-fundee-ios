import SwiftData
import Foundation

/// A logged result for a named benchmark workout.
///
/// `scoreValue` interpretation depends on `BenchmarkDefinition.resolvedScoringType`:
/// - `.time` / `.distance` → total seconds (lower is better)
/// - `.weight` → kilograms (higher is better)
/// - `.reps` → count cast as Double (higher is better)
@Model
final class BenchmarkResult {
    var id: String
    var userID: String
    /// ID of the `BenchmarkDefinition` this result belongs to.
    var definitionID: String
    var scoreValue: Double
    var notes: String
    var performedAt: Date

    init(
        id: String = UUID().uuidString,
        userID: String,
        definitionID: String,
        scoreValue: Double,
        notes: String = "",
        performedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.definitionID = definitionID
        self.scoreValue = scoreValue
        self.notes = notes
        self.performedAt = performedAt
    }
}
