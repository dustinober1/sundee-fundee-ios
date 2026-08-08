import Foundation

// MARK: - Training Exercise Catalog

public enum TrainingEquipmentTag: String, Codable, Sendable, CaseIterable, Equatable {
    case barbell
    case plates
    case dumbbells
    case kettlebell
    case bands
    case bodyweight
    case machine
    case cable
    case cardio
    case box
}

public struct TrainingExerciseDefinition: Sendable, Identifiable, Equatable {
    public let id: String
    public let categoryLabel: String
    public let movementPattern: WorkoutMovementPattern
    public let equipmentTags: [TrainingEquipmentTag]
    public let bodyweightOnly: Bool
    public let isMaxTrackable: Bool
    public let defaultScoringType: ConditioningScoringType?

    public init(
        id: String,
        categoryLabel: String,
        movementPattern: WorkoutMovementPattern,
        equipmentTags: [TrainingEquipmentTag],
        bodyweightOnly: Bool = false,
        isMaxTrackable: Bool = false,
        defaultScoringType: ConditioningScoringType? = nil
    ) {
        self.id = id
        self.categoryLabel = categoryLabel
        self.movementPattern = movementPattern
        self.equipmentTags = equipmentTags
        self.bodyweightOnly = bodyweightOnly
        self.isMaxTrackable = isMaxTrackable
        self.defaultScoringType = defaultScoringType
    }
}

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

private let maxExerciseEquipment: [String: [TrainingEquipmentTag]] = [
    "Goblet Squat": [.dumbbells],
    "Dumbbell Bench Press": [.dumbbells],
    "Dumbbell Incline Press": [.dumbbells],
    "Dumbbell Overhead Press": [.dumbbells],
    "Dumbbell Row": [.dumbbells],
    "Bicep Curl (Dumbbell)": [.dumbbells],
    "Hammer Curl": [.dumbbells],
    "Dips (Weighted)": [.bodyweight],
    "Pull-Up": [.bodyweight],
    "Weighted Pull-Up": [.bodyweight],
    "Lat Pulldown": [.machine],
    "Cable Row": [.cable],
    "Face Pull": [.cable],
    "Leg Press": [.machine],
    "Hack Squat": [.machine],
    "Leg Extension": [.machine],
    "Leg Curl (Lying)": [.machine],
    "Leg Curl (Seated)": [.machine],
    "Glute Ham Raise": [.bodyweight],
    "Farmers Carry": [.dumbbells],
    "Suitcase Carry": [.dumbbells],
    "Yoke Walk": [.barbell],
]

// MARK: - Legacy ID Aliases

/// Retired exercise IDs mapped to the canonical ID that replaced them.
///
/// Each pair named one movement twice — same movement pattern, same equipment —
/// which split a user's logged sets and 1RM history across two names and showed
/// both in exercise search. The canonical side is whichever ID is max-trackable,
/// so existing PR history survives the collapse.
///
/// Records already saved under a retired ID are *not* rewritten: CloudKit is the
/// only backend and there is no migration path, so lookups resolve through
/// `canonicalExerciseID(_:)` instead. Never remove an entry from this table —
/// doing so orphans historical records.
public let legacyExerciseAliases: [String: String] = [
    "Dumbbell Shoulder Press": "Dumbbell Overhead Press",
    "Farmer Carry": "Farmers Carry",
    "Dumbbell Curl": "Bicep Curl (Dumbbell)",
    "Dumbbell Hammer Curl": "Hammer Curl",
    "Dumbbell Skull Crusher": "Skull Crusher",
    "Reverse Fly": "Rear Delt Fly",
    "Dumbbell Chest-Supported Row": "Chest-Supported Row"
]

/// Resolves a possibly-retired exercise ID to the catalog's canonical ID.
///
/// Safe to call on any name: unknown IDs pass through unchanged.
public func canonicalExerciseID(_ id: String) -> String {
    legacyExerciseAliases[id] ?? id
}

private func movementPattern(for category: WeightliftingCategory) -> WorkoutMovementPattern {
    switch category {
    case .squat: return .squat
    case .hipHinge: return .hinge
    case .press: return .push
    case .pull: return .pull
    case .carry: return .carry
    case .olympicWeightlifting: return .conditioning
    }
}

private let weightliftingIDs: Set<String> = Set(weightliftingExercises.map(\.id))

/// Check if an exercise ID is a weightlifting exercise
public func isWeightliftingExercise(_ id: String) -> Bool {
    weightliftingIDs.contains(canonicalExerciseID(id))
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

/// Movement pattern and equipment for each conditioning entry, stated rather
/// than inferred from the name.
///
/// These were previously derived by substring matching, which mislabelled every
/// erg distance as a `.pull` (matching "row" in "500m Row") and tagged the
/// barbell thruster as bodyweight. `ExerciseCatalogTests` asserts this table
/// covers `conditioningExercises` exactly, so a new entry cannot silently fall
/// back to a wrong default.
private let conditioningMetadata: [String: (WorkoutMovementPattern, [TrainingEquipmentTag])] = [
    // Reps-based
    "Wall Ball":               (.conditioning, [.plates]),
    "Box Jump":                (.conditioning, [.box]),
    "Burpee":                  (.conditioning, [.bodyweight]),
    "Kettlebell Swing":        (.hinge, [.kettlebell]),
    "Double Under":            (.conditioning, [.bodyweight]),
    "Pull-Up (Kipping)":       (.pull, [.bodyweight]),
    "Toes-to-Bar":             (.core, [.bodyweight]),
    "Muscle-Up":               (.pull, [.bodyweight]),
    "Push-Up":                 (.push, [.bodyweight]),
    "Sit-Up":                  (.core, [.bodyweight]),
    "Air Squat":               (.squat, [.bodyweight]),
    "Thruster":                (.push, [.barbell, .plates]),
    "Rowing (Calories)":       (.conditioning, [.cardio]),
    "Assault Bike (Calories)": (.conditioning, [.cardio]),
    "SkiErg (Calories)":       (.conditioning, [.cardio]),
    "Box Step-up":             (.squat, [.box]),
    "Lunges (Alternating)":    (.squat, [.bodyweight]),
    "Wall Walk":               (.push, [.bodyweight]),
    "Handstand Push-up":       (.push, [.bodyweight]),
    "GHD Sit-up":              (.core, [.machine]),
    "V-up":                    (.core, [.bodyweight]),
    // Time-based
    "400m Run":        (.conditioning, [.bodyweight]),
    "800m Run":        (.conditioning, [.bodyweight]),
    "1-Mile Run":      (.conditioning, [.bodyweight]),
    "5K Run":          (.conditioning, [.bodyweight]),
    "500m Row":        (.conditioning, [.cardio]),
    "2K Row":          (.conditioning, [.cardio]),
    "1K Assault Bike": (.conditioning, [.cardio]),
    "2K SkiErg":       (.conditioning, [.cardio]),
    "Plank Hold":      (.core, [.bodyweight]),
    "L-Sit Hold":      (.core, [.bodyweight])
]

/// Movements that load the body only, stated explicitly.
///
/// This cannot be derived from `equipmentTags == [.bodyweight]`: a weighted dip
/// and a weighted pull-up are tagged `.bodyweight` because that is the apparatus
/// they use, but both take external load. Getting this wrong means the logger
/// never asks for a weight (`AIWorkoutView`) and substitution scoring pairs
/// loaded lifts with unloaded ones.
private let bodyweightOnlyExercises: Set<String> = [
    // Max-tracked, apparatus-tagged but genuinely unloaded
    "Pull-Up", "Glute Ham Raise",
    // Conditioning
    "Burpee", "Double Under", "Pull-Up (Kipping)", "Toes-to-Bar", "Muscle-Up",
    "Push-Up", "Sit-Up", "Air Squat", "Box Jump", "Box Step-up",
    "Lunges (Alternating)", "Wall Walk", "Handstand Push-up", "GHD Sit-up",
    "V-up", "400m Run", "800m Run", "1-Mile Run", "5K Run", "Plank Hold",
    "L-Sit Hold"
]

private let bandTrainingExercises: [TrainingExerciseDefinition] = [
    .init(id: "Band Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bands]),
    .init(id: "Band Split Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bands]),
    .init(id: "Band Reverse Lunge", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bands]),
    .init(id: "Band Lateral Walk", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bands]),
    .init(id: "Band Monster Walk", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bands]),
    .init(id: "Band Romanian Deadlift", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bands]),
    .init(id: "Band Good Morning", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bands]),
    .init(id: "Band Pull-Through", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bands]),
    .init(id: "Band Glute Bridge", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bands]),
    .init(id: "Band Hamstring Curl", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bands]),
    .init(id: "Band Chest Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band Push-Up", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band Overhead Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band Lateral Raise", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band Front Raise", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band Triceps Pressdown", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bands]),
    .init(id: "Band Lat Pulldown", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bands]),
    .init(id: "Band Face Pull", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bands]),
    .init(id: "Band Pull-Apart", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bands]),
    .init(id: "Band Biceps Curl", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bands]),
    .init(id: "Band Hammer Curl", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bands]),
    .init(id: "Band Straight-Arm Pulldown", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bands]),
    .init(id: "Pallof Press", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bands]),
    .init(id: "Band Wood Chop", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bands]),
    .init(id: "Band Dead Bug", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bands]),
    .init(id: "Band Anti-Rotation Hold", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bands]),
    .init(id: "Band Thruster", categoryLabel: "Conditioning", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band Squat to Press", categoryLabel: "Conditioning", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band High Pull", categoryLabel: "Conditioning", movementPattern: .pull, equipmentTags: [.bands]),
]

/// Movements that generated workouts draw on beyond the max-tracked and
/// conditioning lists above. They are logged, substituted and searched like any
/// other exercise; they simply are not 1RM-tracked, so they live here rather
/// than in `weightliftingExercises`.
private let supplementalTrainingExercises: [TrainingExerciseDefinition] = [
    // Squat
    .init(id: "Band Bulgarian Split Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bands]),
    .init(id: "Band Calf Raise", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bands]),
    .init(id: "Band Hip Abduction", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bands]),
    .init(id: "Bulgarian Split Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Calf Raise", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Cossack Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Dumbbell Bulgarian Split Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Calf Raise", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Front Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Lateral Lunge", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Lunge", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Split Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Step-Up", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.dumbbells]),
    .init(id: "Jump Lunge", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Kettlebell Calf Raise", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Front Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Lateral Lunge", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Reverse Lunge", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Split Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Step-Up", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.kettlebell]),
    .init(id: "Lateral Lunge", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Reverse Lunge", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Split Squat", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Squat Jump", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Standing Calf Raise", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.machine]),
    .init(id: "Step-Up", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Walking Lunge", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Wall Sit", categoryLabel: "Squat", movementPattern: .squat, equipmentTags: [.bodyweight], bodyweightOnly: true),
    // Hip Hinge
    .init(id: "Kettlebell Single-Arm Swing", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.kettlebell]),
    .init(id: "Band Deadlift", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bands]),
    .init(id: "Band Hip Thrust", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bands]),
    .init(id: "Dumbbell Clean", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Good Morning", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Hip Thrust", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Romanian Deadlift", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Single-Leg Deadlift", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Swing", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.dumbbells]),
    .init(id: "Glute Bridge", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Good Morning (Bodyweight)", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Kettlebell Clean", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Deadlift", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Good Morning", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Hip Thrust", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Single-Leg Deadlift", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.kettlebell]),
    .init(id: "Nordic Curl Negative", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Single-Leg Deadlift", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Single-Leg Glute Bridge", categoryLabel: "Hip Hinge", movementPattern: .hinge, equipmentTags: [.bodyweight], bodyweightOnly: true),
    // Press
    .init(id: "Kettlebell Half-Kneeling Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Tall-Kneeling Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.kettlebell]),
    .init(id: "Band Chest Fly", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band Incline Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band Overhead Triceps Extension", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Band Triceps Kickback", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bands]),
    .init(id: "Bench Dip", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Cable Chest Fly", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.cable]),
    .init(id: "Cable Triceps Pressdown", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.cable]),
    .init(id: "Decline Push-Up", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Diamond Push-Up", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Dips", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Dumbbell Arnold Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Floor Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Front Raise", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Lateral Raise", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Push Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Squeeze Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Thruster", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Triceps Kickback", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.dumbbells]),
    .init(id: "Handstand Hold", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Incline Push-Up", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Kettlebell Bottoms-Up Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Floor Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Push Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell See-Saw Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Strict Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Thruster", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Z Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.kettlebell]),
    .init(id: "Machine Chest Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.machine]),
    .init(id: "Machine Shoulder Press", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.machine]),
    .init(id: "Overhead Triceps Extension", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.dumbbells]),
    .init(id: "Pike Push-Up", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Pseudo Planche Push-Up", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Skull Crusher", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.dumbbells]),
    .init(id: "Wide Push-Up", categoryLabel: "Press", movementPattern: .push, equipmentTags: [.bodyweight], bodyweightOnly: true),
    // Pull
    .init(id: "Kettlebell Chest-Supported Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Shrug", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.kettlebell]),
    .init(id: "Band Reverse Fly", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bands]),
    .init(id: "Band Shrug", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bands]),
    .init(id: "Band Upright Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bands]),
    .init(id: "Barbell Shrug", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.barbell, .plates]),
    .init(id: "Cable Curl", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.cable]),
    .init(id: "Chest-Supported Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.dumbbells]),
    .init(id: "Chin-Up", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Dumbbell Concentration Curl", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell High Pull", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Pullover", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Renegade Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Shrug", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.dumbbells]),
    .init(id: "Inverted Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Kettlebell Curl", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Gorilla Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell High Pull", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Renegade Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Upright Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.kettlebell]),
    .init(id: "Negative Pull-Up", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Prone W Raise", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Prone Y Raise", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Rear Delt Fly", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.dumbbells]),
    .init(id: "Scapular Pull-Up", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Straight-Arm Pulldown", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.cable]),
    .init(id: "Towel Inverted Row", categoryLabel: "Pull", movementPattern: .pull, equipmentTags: [.bodyweight], bodyweightOnly: true),
    // Core
    .init(id: "Kettlebell Overhead Hold", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Plank Pull-Through", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.kettlebell]),
    .init(id: "Ab Wheel Rollout", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Band Russian Twist", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bands]),
    .init(id: "Bicycle Crunch", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Bird Dog", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Cable Crunch", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.cable]),
    .init(id: "Cable Wood Chop", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.cable]),
    .init(id: "Dead Bug", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Dumbbell Dead Bug", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Russian Twist", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Side Bend", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.dumbbells]),
    .init(id: "Dumbbell Weighted Sit-Up", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.dumbbells]),
    .init(id: "Flutter Kick", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Hanging Leg Raise", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Hollow Body Hold", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Kettlebell Dead Bug", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Halo", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Rack Hold", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Russian Twist", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Side Bend", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.kettlebell]),
    .init(id: "Kettlebell Windmill", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.kettlebell]),
    .init(id: "Leg Raise", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Mountain Climber", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Side Plank Hold", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Superman Hold", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Turkish Get-Up", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.kettlebell]),
    .init(id: "Weighted Sit-Up", categoryLabel: "Core", movementPattern: .core, equipmentTags: [.plates]),
    // Carry
    .init(id: "Bear Crawl", categoryLabel: "Carry", movementPattern: .carry, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Kettlebell Farmer Carry", categoryLabel: "Carry", movementPattern: .carry, equipmentTags: [.kettlebell]),
    // Conditioning
    .init(id: "Assault Bike Interval", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.cardio]),
    .init(id: "Battle Rope Wave", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.machine]),
    .init(id: "Broad Jump", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Dumbbell Snatch", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.dumbbells]),
    .init(id: "High Knees", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Jumping Jack", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Kettlebell Snatch", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.kettlebell]),
    .init(id: "Rowing Machine Interval", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.cardio]),
    .init(id: "Shuttle Run", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "Skater Jump", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.bodyweight], bodyweightOnly: true),
    .init(id: "SkiErg Interval", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.cardio]),
    .init(id: "Sled Push", categoryLabel: "Conditioning", movementPattern: .conditioning, equipmentTags: [.machine])
]

public let trainingExerciseCatalog: [TrainingExerciseDefinition] = {
    let maxEntries = weightliftingExercises.map { entry in
        TrainingExerciseDefinition(
            id: entry.id,
            categoryLabel: entry.category.rawValue,
            movementPattern: movementPattern(for: entry.category),
            equipmentTags: maxExerciseEquipment[entry.id] ?? [.barbell, .plates],
            bodyweightOnly: bodyweightOnlyExercises.contains(entry.id),
            isMaxTrackable: true,
            defaultScoringType: nil
        )
    }
    let conditioningEntries = conditioningExercises.map { entry in
        let metadata = conditioningMetadata[entry.id] ?? (.conditioning, [.bodyweight])
        return TrainingExerciseDefinition(
            id: entry.id,
            categoryLabel: "Conditioning",
            movementPattern: metadata.0,
            equipmentTags: metadata.1,
            bodyweightOnly: bodyweightOnlyExercises.contains(entry.id),
            isMaxTrackable: false,
            defaultScoringType: entry.defaultScoringType
        )
    }
    var seen = Set<String>()
    return (maxEntries + conditioningEntries + bandTrainingExercises + supplementalTrainingExercises)
        .filter { definition in
            seen.insert(definition.id).inserted
        }
}()

private let conditioningMap: [String: ConditioningScoringType] = {
    Dictionary(uniqueKeysWithValues: conditioningExercises.map { ($0.id, $0.defaultScoringType) })
}()

/// Check if an exercise ID is a conditioning exercise
public func isConditioningExercise(_ id: String) -> Bool {
    conditioningMap[canonicalExerciseID(id)] != nil
}

/// Get the default scoring type for a conditioning exercise
public func conditioningScoringType(for id: String) -> ConditioningScoringType? {
    conditioningMap[canonicalExerciseID(id)]
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
