import Foundation

// MARK: - Weightlifting Exercise Catalog

/// Category of weightlifting exercise
public enum WeightliftingCategory: String, Codable, Sendable, CaseIterable {
    case squat = "Squat"
    case hipHinge = "Hip Hinge"
    case press = "Press"
    case pull = "Pull"
    case carry = "Carry"
    case olympicWeightlifting = "Olympic Weightlifting"
}

/// A weightlifting exercise definition
public struct WeightliftingEntry: Sendable, Identifiable {
    public let id: String
    public let category: WeightliftingCategory
}

/// All recognized weightlifting exercises
public let weightliftingExercises: [WeightliftingEntry] = [
    // Squat
    WeightliftingEntry(id: "Back Squat",            category: .squat),
    WeightliftingEntry(id: "Front Squat",           category: .squat),
    WeightliftingEntry(id: "Safety Bar Squat",      category: .squat),
    WeightliftingEntry(id: "Box Squat",             category: .squat),
    WeightliftingEntry(id: "Pause Squat",           category: .squat),
    WeightliftingEntry(id: "Goblet Squat",          category: .squat),
    WeightliftingEntry(id: "Leg Press",             category: .squat),
    WeightliftingEntry(id: "Hack Squat",            category: .squat),
    WeightliftingEntry(id: "Leg Extension",         category: .squat),
    // Hip Hinge
    WeightliftingEntry(id: "Conventional Deadlift (No Straps)",   category: .hipHinge),
    WeightliftingEntry(id: "Conventional Deadlift (With Straps)", category: .hipHinge),
    WeightliftingEntry(id: "Romanian Deadlift (No Straps)",       category: .hipHinge),
    WeightliftingEntry(id: "Romanian Deadlift (With Straps)",     category: .hipHinge),
    WeightliftingEntry(id: "Sumo Deadlift (No Straps)",           category: .hipHinge),
    WeightliftingEntry(id: "Sumo Deadlift (With Straps)",         category: .hipHinge),
    WeightliftingEntry(id: "Trap Bar Deadlift (No Straps)",       category: .hipHinge),
    WeightliftingEntry(id: "Trap Bar Deadlift (With Straps)",     category: .hipHinge),
    WeightliftingEntry(id: "Good Morning",          category: .hipHinge),
    WeightliftingEntry(id: "Hip Thrust",            category: .hipHinge),
    WeightliftingEntry(id: "Leg Curl (Lying)",      category: .hipHinge),
    WeightliftingEntry(id: "Leg Curl (Seated)",     category: .hipHinge),
    WeightliftingEntry(id: "Glute Ham Raise",       category: .hipHinge),
    // Press
    WeightliftingEntry(id: "Flat Barbell Bench Press",    category: .press),
    WeightliftingEntry(id: "Incline Barbell Bench Press", category: .press),
    WeightliftingEntry(id: "Decline Barbell Bench Press", category: .press),
    WeightliftingEntry(id: "Strict Press",                category: .press),
    WeightliftingEntry(id: "Push Press",                  category: .press),
    WeightliftingEntry(id: "Dumbbell Bench Press",        category: .press),
    WeightliftingEntry(id: "Dumbbell Incline Press",      category: .press),
    WeightliftingEntry(id: "Dumbbell Overhead Press",     category: .press),
    WeightliftingEntry(id: "Dips (Weighted)",             category: .press),
    WeightliftingEntry(id: "Close Grip Bench Press",      category: .press),
    // Pull
    WeightliftingEntry(id: "Barbell Row",       category: .pull),
    WeightliftingEntry(id: "Pendlay Row",       category: .pull),
    WeightliftingEntry(id: "Pull-Up",           category: .pull),
    WeightliftingEntry(id: "Weighted Pull-Up",  category: .pull),
    WeightliftingEntry(id: "Lat Pulldown",      category: .pull),
    WeightliftingEntry(id: "Cable Row",         category: .pull),
    WeightliftingEntry(id: "Dumbbell Row",      category: .pull),
    WeightliftingEntry(id: "Face Pull",         category: .pull),
    WeightliftingEntry(id: "Bicep Curl (Barbell)",  category: .pull),
    WeightliftingEntry(id: "Bicep Curl (Dumbbell)", category: .pull),
    WeightliftingEntry(id: "Hammer Curl",           category: .pull),
    WeightliftingEntry(id: "Upright Row",           category: .pull),
    // Carry
    WeightliftingEntry(id: "Farmers Carry",   category: .carry),
    WeightliftingEntry(id: "Suitcase Carry",  category: .carry),
    WeightliftingEntry(id: "Zercher Carry",   category: .carry),
    WeightliftingEntry(id: "Yoke Walk",       category: .carry),
    // Olympic Weightlifting
    WeightliftingEntry(id: "Squat Snatch",    category: .olympicWeightlifting),
    WeightliftingEntry(id: "Squat Clean",     category: .olympicWeightlifting),
    WeightliftingEntry(id: "Power Clean",     category: .olympicWeightlifting),
    WeightliftingEntry(id: "Power Snatch",    category: .olympicWeightlifting),
    WeightliftingEntry(id: "Hang Clean",      category: .olympicWeightlifting),
    WeightliftingEntry(id: "Hang Snatch",     category: .olympicWeightlifting),
    WeightliftingEntry(id: "Split Jerk",      category: .olympicWeightlifting),
    WeightliftingEntry(id: "Push Jerk",       category: .olympicWeightlifting),
    WeightliftingEntry(id: "Clean and Jerk",  category: .olympicWeightlifting),
    WeightliftingEntry(id: "Muscle Snatch",   category: .olympicWeightlifting),
    WeightliftingEntry(id: "Muscle Clean",    category: .olympicWeightlifting),
]

private let weightliftingIDs: Set<String> = Set(weightliftingExercises.map(\.id))

/// Check if an exercise ID is a weightlifting exercise
public func isWeightliftingExercise(_ id: String) -> Bool {
    weightliftingIDs.contains(id)
}

// MARK: - Conditioning Exercise Catalog

/// Scoring type for conditioning exercises
public enum ConditioningScoringType: String, Codable, Sendable {
    case time
    case reps
}

/// A conditioning exercise definition
public struct ConditioningEntry: Sendable, Identifiable {
    public let id: String
    public let defaultScoringType: ConditioningScoringType
}

/// All recognized conditioning exercises
public let conditioningExercises: [ConditioningEntry] = [
    // Reps-based
    ConditioningEntry(id: "Wall Ball",               defaultScoringType: .reps),
    ConditioningEntry(id: "Box Jump",                defaultScoringType: .reps),
    ConditioningEntry(id: "Burpee",                  defaultScoringType: .reps),
    ConditioningEntry(id: "Kettlebell Swing",        defaultScoringType: .reps),
    ConditioningEntry(id: "Double Under",            defaultScoringType: .reps),
    ConditioningEntry(id: "Pull-Up (Kipping)",       defaultScoringType: .reps),
    ConditioningEntry(id: "Toes-to-Bar",             defaultScoringType: .reps),
    ConditioningEntry(id: "Muscle-Up",               defaultScoringType: .reps),
    ConditioningEntry(id: "Push-Up",                 defaultScoringType: .reps),
    ConditioningEntry(id: "Sit-Up",                  defaultScoringType: .reps),
    ConditioningEntry(id: "Air Squat",               defaultScoringType: .reps),
    ConditioningEntry(id: "Thruster",                defaultScoringType: .reps),
    ConditioningEntry(id: "Rowing (Calories)",       defaultScoringType: .reps),
    ConditioningEntry(id: "Assault Bike (Calories)", defaultScoringType: .reps),
    ConditioningEntry(id: "SkiErg (Calories)",       defaultScoringType: .reps),
    ConditioningEntry(id: "Box Step-up",             defaultScoringType: .reps),
    ConditioningEntry(id: "Lunges (Alternating)",    defaultScoringType: .reps),
    ConditioningEntry(id: "Wall Walk",               defaultScoringType: .reps),
    ConditioningEntry(id: "Handstand Push-up",       defaultScoringType: .reps),
    ConditioningEntry(id: "GHD Sit-up",              defaultScoringType: .reps),
    ConditioningEntry(id: "V-up",                    defaultScoringType: .reps),
    // Time-based
    ConditioningEntry(id: "400m Run",        defaultScoringType: .time),
    ConditioningEntry(id: "800m Run",        defaultScoringType: .time),
    ConditioningEntry(id: "1-Mile Run",      defaultScoringType: .time),
    ConditioningEntry(id: "5K Run",          defaultScoringType: .time),
    ConditioningEntry(id: "500m Row",        defaultScoringType: .time),
    ConditioningEntry(id: "2K Row",          defaultScoringType: .time),
    ConditioningEntry(id: "1K Assault Bike", defaultScoringType: .time),
    ConditioningEntry(id: "2K SkiErg",       defaultScoringType: .time),
    ConditioningEntry(id: "Plank Hold",      defaultScoringType: .time),
    ConditioningEntry(id: "L-Sit Hold",      defaultScoringType: .time),
]

private let conditioningMap: [String: ConditioningScoringType] = {
    Dictionary(uniqueKeysWithValues: conditioningExercises.map { ($0.id, $0.defaultScoringType) })
}()

/// Check if an exercise ID is a conditioning exercise
public func isConditioningExercise(_ id: String) -> Bool {
    conditioningMap[id] != nil
}

/// Get the default scoring type for a conditioning exercise
public func conditioningScoringType(for id: String) -> ConditioningScoringType? {
    conditioningMap[id]
}

/// Format a conditioning value for display
public func formatConditioningValue(_ value: Double, type: ConditioningScoringType) -> String {
    if type == .time {
        let totalSeconds = Int(value)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    let count = Int(value)
    return count == 1 ? "1 rep" : "\(count) reps"
}

/// Check if a new conditioning score is better than an existing one
public func isBetterConditioningScore(
    newValue: Double,
    existingValue: Double?,
    type: ConditioningScoringType
) -> Bool {
    guard let existingValue else { return true }
    return type == .time ? newValue < existingValue : newValue > existingValue
}
