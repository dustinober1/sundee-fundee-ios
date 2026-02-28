import Foundation

/// Scoring type for conditioning exercises.
enum ConditioningScoringType: String, Codable, CaseIterable, Sendable {
    case time = "time"
    case reps = "reps"

    /// Returns `true` when `newValue` is better than `existingValue`.
    /// A nil existing value means no previous score, so any new value wins.
    func isBetterThan(newValue: Double, existingValue: Double?) -> Bool {
        guard let existing = existingValue else { return true }
        switch self {
        case .time: return newValue < existing   // lower is better
        case .reps: return newValue > existing   // higher is better
        }
    }

    /// Human-readable format: time → "M:SS", reps → "N reps" / "1 rep".
    func formatValue(_ value: Double) -> String {
        switch self {
        case .time:
            let totalSeconds = Int(value)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return "\(minutes):\(String(format: "%02d", seconds))"
        case .reps:
            let count = Int(value)
            return count == 1 ? "1 rep" : "\(count) reps"
        }
    }
}

/// Catalog of conditioning exercises with their default scoring types.
enum ConditioningExerciseCatalog {

    struct Entry: Identifiable {
        let id: String
        let defaultScoringType: ConditioningScoringType
    }

    static let all: [Entry] = [
        // Reps-based
        Entry(id: "Wall Ball",               defaultScoringType: .reps),
        Entry(id: "Box Jump",                defaultScoringType: .reps),
        Entry(id: "Burpee",                  defaultScoringType: .reps),
        Entry(id: "Kettlebell Swing",        defaultScoringType: .reps),
        Entry(id: "Double Under",            defaultScoringType: .reps),
        Entry(id: "Pull-Up (Kipping)",       defaultScoringType: .reps),
        Entry(id: "Toes-to-Bar",             defaultScoringType: .reps),
        Entry(id: "Muscle-Up",               defaultScoringType: .reps),
        Entry(id: "Push-Up",                 defaultScoringType: .reps),
        Entry(id: "Sit-Up",                  defaultScoringType: .reps),
        Entry(id: "Air Squat",               defaultScoringType: .reps),
        Entry(id: "Thruster",                defaultScoringType: .reps),
        Entry(id: "Rowing (Calories)",       defaultScoringType: .reps),
        Entry(id: "Assault Bike (Calories)", defaultScoringType: .reps),
        // Time-based
        Entry(id: "400m Run",                defaultScoringType: .time),
        Entry(id: "800m Run",                defaultScoringType: .time),
        Entry(id: "1-Mile Run",              defaultScoringType: .time),
        Entry(id: "5K Run",                  defaultScoringType: .time),
        Entry(id: "500m Row",                defaultScoringType: .time),
        Entry(id: "2K Row",                  defaultScoringType: .time),
        Entry(id: "1K Assault Bike",         defaultScoringType: .time),
    ]

    /// Set of canonical exercise IDs for O(1) membership tests.
    static let exerciseIDs: Set<String> = Set(all.map(\.id))

    /// Returns `true` when `exerciseID` is a tracked conditioning movement.
    static func isConditioningExercise(_ exerciseID: String) -> Bool {
        exerciseIDs.contains(exerciseID)
    }

    /// Returns the default scoring type for a conditioning exercise, or nil if not found.
    static func scoringType(for exerciseID: String) -> ConditioningScoringType? {
        all.first { $0.id == exerciseID }?.defaultScoringType
    }
}
