import Foundation

/// Catalog of exercises eligible for 1RM/max tracking.
/// Only barbell and dumbbell compound movements where strength progression
/// and 1RM estimation are meaningful are included.
enum WeightliftingExerciseCatalog {

    enum Category: String, CaseIterable {
        case squat    = "Squat"
        case hinge    = "Hip Hinge"
        case press    = "Press"
        case pull     = "Pull"
        case carry    = "Carry"
    }

    struct Entry: Identifiable {
        let id: String       // canonical exercise name used as exerciseID in data models
        let category: Category
    }

    static let all: [Entry] = [
        // Squat
        Entry(id: "Back Squat",            category: .squat),
        Entry(id: "Front Squat",           category: .squat),
        Entry(id: "Safety Bar Squat",      category: .squat),
        Entry(id: "Box Squat",             category: .squat),
        Entry(id: "Pause Squat",           category: .squat),
        Entry(id: "Goblet Squat",          category: .squat),
        // Hip hinge
        Entry(id: "Conventional Deadlift", category: .hinge),
        Entry(id: "Romanian Deadlift",     category: .hinge),
        Entry(id: "Sumo Deadlift",         category: .hinge),
        Entry(id: "Trap Bar Deadlift",     category: .hinge),
        Entry(id: "Good Morning",          category: .hinge),
        Entry(id: "Hip Thrust",            category: .hinge),
        // Press
        Entry(id: "Flat Barbell Bench Press",  category: .press),
        Entry(id: "Incline Barbell Bench Press", category: .press),
        Entry(id: "Strict Press",          category: .press),
        Entry(id: "Push Press",            category: .press),
        Entry(id: "Dumbbell Bench Press",  category: .press),
        Entry(id: "Dumbbell Overhead Press", category: .press),
        // Pull
        Entry(id: "Barbell Row",           category: .pull),
        Entry(id: "Pendlay Row",           category: .pull),
        Entry(id: "Pull-Up",               category: .pull),
        Entry(id: "Weighted Pull-Up",      category: .pull),
        Entry(id: "Lat Pulldown",          category: .pull),
        Entry(id: "Cable Row",             category: .pull),
        // Carry
        Entry(id: "Farmers Carry",         category: .carry),
        Entry(id: "Suitcase Carry",        category: .carry),
    ]

    /// Set of canonical exercise IDs for O(1) membership tests.
    static let exerciseIDs: Set<String> = Set(all.map(\.id))

    /// Exercises sorted alphabetically within each category, then by category order.
    static var sortedByCategory: [Entry] {
        let order: [Category] = [.squat, .hinge, .press, .pull, .carry]
        return order.flatMap { cat in
            all.filter { $0.category == cat }.sorted { $0.id < $1.id }
        }
    }

    /// Returns `true` when `exerciseID` is a tracked weightlifting movement.
    static func isWeightliftingExercise(_ exerciseID: String) -> Bool {
        exerciseIDs.contains(exerciseID)
    }
}
