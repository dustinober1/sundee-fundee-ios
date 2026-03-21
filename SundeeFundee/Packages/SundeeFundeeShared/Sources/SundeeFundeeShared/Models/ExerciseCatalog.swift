import Foundation

public enum WeightliftingExerciseCatalog {

    public enum Category: String, CaseIterable, Sendable {
        case squat    = "Squat"
        case hinge    = "Hip Hinge"
        case press    = "Press"
        case pull     = "Pull"
        case carry    = "Carry"
        case olympic  = "Olympic Weightlifting"
    }

    public struct Entry: Identifiable, Sendable {
        public let id: String
        public let category: Category
        public init(id: String, category: Category) {
            self.id = id; self.category = category
        }
    }

    public static let all: [Entry] = [
        // Squat
        Entry(id: "Back Squat",            category: .squat),
        Entry(id: "Front Squat",           category: .squat),
        Entry(id: "Safety Bar Squat",      category: .squat),
        Entry(id: "Box Squat",             category: .squat),
        Entry(id: "Pause Squat",           category: .squat),
        Entry(id: "Goblet Squat",          category: .squat),
        // Hip hinge
        Entry(id: "Conventional Deadlift (No Straps)", category: .hinge),
        Entry(id: "Conventional Deadlift (With Straps)", category: .hinge),
        Entry(id: "Romanian Deadlift (No Straps)",     category: .hinge),
        Entry(id: "Romanian Deadlift (With Straps)",     category: .hinge),
        Entry(id: "Sumo Deadlift (No Straps)",         category: .hinge),
        Entry(id: "Sumo Deadlift (With Straps)",         category: .hinge),
        Entry(id: "Trap Bar Deadlift (No Straps)",     category: .hinge),
        Entry(id: "Trap Bar Deadlift (With Straps)",     category: .hinge),
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
        // Olympic Weightlifting
        Entry(id: "Squat Snatch",          category: .olympic),
        Entry(id: "Squat Clean",           category: .olympic),
        Entry(id: "Power Clean",           category: .olympic),
        Entry(id: "Power Snatch",          category: .olympic),
        Entry(id: "Hang Clean",            category: .olympic),
        Entry(id: "Hang Snatch",           category: .olympic),
        Entry(id: "Split Jerk",            category: .olympic),
        Entry(id: "Push Jerk",             category: .olympic),
        Entry(id: "Clean and Jerk",        category: .olympic),
    ]

    public static let exerciseIDs: Set<String> = Set(all.map(\.id))
    public static let defaultExerciseID: String = all.first!.id

    public static var sortedByCategory: [Entry] {
        let order: [Category] = [.squat, .hinge, .press, .pull, .carry, .olympic]
        return order.flatMap { cat in
            all.filter { $0.category == cat }.sorted { $0.id < $1.id }
        }
    }

    public static func isWeightliftingExercise(_ exerciseID: String) -> Bool {
        exerciseIDs.contains(exerciseID)
    }
}

public enum ConditioningScoringType: String, Codable, CaseIterable, Sendable {
    case time = "time"
    case reps = "reps"

    public func isBetterThan(newValue: Double, existingValue: Double?) -> Bool {
        guard let existing = existingValue else { return true }
        switch self {
        case .time: return newValue < existing
        case .reps: return newValue > existing
        }
    }

    public func formatValue(_ value: Double) -> String {
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

public enum ConditioningExerciseCatalog {

    public struct Entry: Identifiable, Sendable {
        public let id: String
        public let defaultScoringType: ConditioningScoringType
        public init(id: String, defaultScoringType: ConditioningScoringType) {
            self.id = id; self.defaultScoringType = defaultScoringType
        }
    }

    public static let all: [Entry] = [
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

    public static let exerciseIDs: Set<String> = Set(all.map(\.id))

    public static func isConditioningExercise(_ exerciseID: String) -> Bool {
        exerciseIDs.contains(exerciseID)
    }

    public static func scoringType(for exerciseID: String) -> ConditioningScoringType? {
        all.first { $0.id == exerciseID }?.defaultScoringType
    }
}
