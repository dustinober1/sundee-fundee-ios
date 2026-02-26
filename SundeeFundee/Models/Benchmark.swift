import SwiftData
import Foundation

/// A named benchmark result — a user-defined performance test logged on a specific date.
///
/// Benchmarks allow users to track progress against named tests (e.g. "Month 1 Baseline",
/// "Pre-Program Squat Max") independently of the active training program.
@Model
final class Benchmark {
    var id: String
    var userID: String
    /// User-defined label grouping related entries (e.g. "Pre-Program Baseline").
    var name: String
    /// The exercise performed (should match WeightliftingExerciseCatalog IDs).
    var exercise: String
    var weightKg: Double
    var reps: Int
    var notes: String
    var performedAt: Date

    init(
        id: String = UUID().uuidString,
        userID: String,
        name: String,
        exercise: String,
        weightKg: Double,
        reps: Int,
        notes: String = "",
        performedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.exercise = exercise
        self.weightKg = weightKg
        self.reps = reps
        self.notes = notes
        self.performedAt = performedAt
    }
}
