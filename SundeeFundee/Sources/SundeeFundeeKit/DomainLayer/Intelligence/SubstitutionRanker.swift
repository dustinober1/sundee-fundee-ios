import Foundation

// MARK: - SubstitutionRanker

/// Ranks substitute exercises by similarity, equipment match, and injury compatibility.
///
/// Given a target exercise the user cannot or does not want to perform,
/// plus their context (injuries, available equipment, time constraints),
/// returns a ranked list of alternatives from the exercise catalog.
///
/// Pure domain logic — no framework dependencies.
public enum SubstitutionRanker {

    // MARK: - Types

    /// A ranked substitute exercise.
    public struct RankedSubstitution: Sendable, Equatable {
        /// The substitute exercise name.
        public let exerciseName: String

        /// The category of the substitute.
        public let category: WeightliftingCategory

        /// Overall match score (0.0–1.0, higher is better).
        public let score: Double

        /// Why this exercise is a good substitute.
        public let reason: String
    }

    /// Available equipment context for filtering.
    public struct EquipmentContext: Sendable {
        /// Whether a barbell is available.
        public let hasBarbell: Bool
        /// Whether dumbbells are available.
        public let hasDumbbells: Bool
        /// Whether kettlebells are available.
        public let hasKettlebells: Bool
        /// Whether a pull-up bar is available.
        public let hasPullUpBar: Bool
        /// Whether machines/cables are available.
        public let hasMachines: Bool
        /// Whether resistance bands are available.
        public let hasBands: Bool

        public init(hasBarbell: Bool = true, hasDumbbells: Bool = true,
                    hasKettlebells: Bool = true, hasPullUpBar: Bool = true, hasMachines: Bool = true,
                    hasBands: Bool = true) {
            self.hasBarbell = hasBarbell
            self.hasDumbbells = hasDumbbells
            self.hasKettlebells = hasKettlebells
            self.hasPullUpBar = hasPullUpBar
            self.hasMachines = hasMachines
            self.hasBands = hasBands
        }

        /// Full gym — everything available.
        public static let fullGym = EquipmentContext()

        /// Home with dumbbells only.
        public static let homeDumbbells = EquipmentContext(
            hasBarbell: false, hasDumbbells: true,
            hasKettlebells: false,
            hasPullUpBar: false, hasMachines: false,
            hasBands: false
        )

        /// Bodyweight only.
        public static let bodyweightOnly = EquipmentContext(
            hasBarbell: false, hasDumbbells: false,
            hasKettlebells: false,
            hasPullUpBar: false, hasMachines: false,
            hasBands: false
        )

        /// Resistance bands only.
        public static let resistanceBands = EquipmentContext(
            hasBarbell: false, hasDumbbells: false,
            hasKettlebells: false,
            hasPullUpBar: false, hasMachines: false,
            hasBands: true
        )

        /// Kettlebell only.
        public static let kettlebellOnly = EquipmentContext(
            hasBarbell: false, hasDumbbells: false,
            hasKettlebells: true,
            hasPullUpBar: false, hasMachines: false,
            hasBands: false
        )
    }

    private struct SubstitutionCatalogEntry {
        let id: String
        let category: WeightliftingCategory
    }

    // MARK: - Muscle Activation Map

    /// Primary muscle groups activated by each exercise.
    ///
    /// Keys match exact `trainingExerciseCatalog` IDs. Coverage has to stay
    /// complete: `muscleOverlapScore` returns 0 for any exercise missing here,
    /// which silently drops it to equipment-and-category matching and produces
    /// visibly worse substitution suggestions.
    /// Internal rather than private so a test can assert catalog coverage.
    static let muscleGroups: [String: Set<String>] = [
        // Squat
        "Back Squat":           ["Quads", "Glutes", "Hamstrings", "Core"],
        "Front Squat":          ["Quads", "Glutes", "Core", "Upper Back"],
        "Safety Bar Squat":     ["Quads", "Glutes", "Hamstrings", "Core"],
        "Box Squat":            ["Quads", "Glutes", "Hamstrings"],
        "Pause Squat":          ["Quads", "Glutes", "Hamstrings", "Core"],
        "Goblet Squat":         ["Quads", "Glutes", "Core"],
        "Leg Press":            ["Quads", "Glutes", "Hamstrings"],
        "Hack Squat":           ["Quads", "Glutes"],
        "Leg Extension":        ["Quads"],
        // Hip Hinge
        "Conventional Deadlift (No Straps)":   ["Hamstrings", "Glutes", "Lower Back", "Core", "Upper Back"],
        "Conventional Deadlift (With Straps)": ["Hamstrings", "Glutes", "Lower Back", "Core", "Upper Back"],
        "Romanian Deadlift (No Straps)":       ["Hamstrings", "Glutes", "Lower Back"],
        "Romanian Deadlift (With Straps)":     ["Hamstrings", "Glutes", "Lower Back"],
        "Sumo Deadlift (No Straps)":           ["Hamstrings", "Glutes", "Adductors", "Lower Back"],
        "Sumo Deadlift (With Straps)":         ["Hamstrings", "Glutes", "Adductors", "Lower Back"],
        "Trap Bar Deadlift (No Straps)":       ["Quads", "Glutes", "Hamstrings", "Lower Back"],
        "Trap Bar Deadlift (With Straps)":     ["Quads", "Glutes", "Hamstrings", "Lower Back"],
        "Good Morning":         ["Hamstrings", "Glutes", "Lower Back"],
        "Hip Thrust":           ["Glutes", "Hamstrings"],
        "Leg Curl (Lying)":     ["Hamstrings"],
        "Leg Curl (Seated)":    ["Hamstrings"],
        "Glute Ham Raise":      ["Hamstrings", "Glutes", "Lower Back"],
        // Press
        "Flat Barbell Bench Press":    ["Chest", "Triceps", "Front Delts"],
        "Incline Barbell Bench Press": ["Upper Chest", "Triceps", "Front Delts"],
        "Decline Barbell Bench Press": ["Chest", "Triceps", "Front Delts"],
        "Strict Press":                ["Front Delts", "Triceps", "Upper Chest"],
        "Push Press":                  ["Front Delts", "Triceps", "Upper Chest", "Core"],
        "Dumbbell Bench Press":        ["Chest", "Triceps", "Front Delts"],
        "Dumbbell Incline Press":      ["Upper Chest", "Triceps", "Front Delts"],
        "Dumbbell Overhead Press":     ["Front Delts", "Triceps", "Side Delts"],
        "Dips (Weighted)":             ["Chest", "Triceps", "Front Delts"],
        "Close Grip Bench Press":      ["Triceps", "Chest", "Front Delts"],
        "Band Chest Press":            ["Chest", "Triceps", "Front Delts"],
        "Band Push-Up":                ["Chest", "Triceps", "Front Delts"],
        "Band Overhead Press":         ["Front Delts", "Triceps", "Side Delts"],
        "Band Lateral Raise":          ["Side Delts"],
        "Band Front Raise":            ["Front Delts"],
        "Band Triceps Pressdown":      ["Triceps"],
        // Pull
        "Barbell Row":              ["Upper Back", "Lats", "Biceps", "Rear Delts"],
        "Pendlay Row":              ["Upper Back", "Lats", "Biceps"],
        "Pull-Up":                  ["Lats", "Biceps", "Upper Back"],
        "Weighted Pull-Up":         ["Lats", "Biceps", "Upper Back"],
        "Lat Pulldown":             ["Lats", "Biceps", "Upper Back"],
        "Cable Row":                ["Upper Back", "Lats", "Biceps"],
        "Dumbbell Row":             ["Upper Back", "Lats", "Biceps"],
        "Face Pull":                ["Rear Delts", "Upper Back"],
        "Bicep Curl (Barbell)":     ["Biceps"],
        "Bicep Curl (Dumbbell)":    ["Biceps"],
        "Hammer Curl":              ["Biceps", "Forearms"],
        "Upright Row":              ["Side Delts", "Traps", "Biceps"],
        "Band Row":                 ["Upper Back", "Lats", "Biceps"],
        "Band Lat Pulldown":        ["Lats", "Biceps", "Upper Back"],
        "Band Face Pull":           ["Rear Delts", "Upper Back"],
        "Band Pull-Apart":          ["Rear Delts", "Upper Back"],
        "Band Biceps Curl":         ["Biceps"],
        "Band Hammer Curl":         ["Biceps", "Forearms"],
        "Band Straight-Arm Pulldown": ["Lats", "Upper Back"],
        // Band lower body and core
        "Band Squat":               ["Quads", "Glutes", "Core"],
        "Band Split Squat":         ["Quads", "Glutes"],
        "Band Reverse Lunge":       ["Quads", "Glutes"],
        "Band Lateral Walk":        ["Glutes"],
        "Band Monster Walk":        ["Glutes"],
        "Band Romanian Deadlift":   ["Hamstrings", "Glutes", "Lower Back"],
        "Band Good Morning":        ["Hamstrings", "Glutes", "Lower Back"],
        "Band Pull-Through":        ["Hamstrings", "Glutes"],
        "Band Glute Bridge":        ["Glutes", "Hamstrings"],
        "Band Hamstring Curl":      ["Hamstrings"],
        "Pallof Press":             ["Core"],
        "Band Wood Chop":           ["Core"],
        "Band Dead Bug":            ["Core"],
        "Band Anti-Rotation Hold":  ["Core"],
        "Band Thruster":            ["Quads", "Glutes", "Shoulders", "Triceps", "Core"],
        "Band Squat to Press":      ["Quads", "Glutes", "Shoulders", "Triceps", "Core"],
        "Band High Pull":           ["Upper Back", "Traps", "Biceps"],
        // Carry
        "Farmers Carry":     ["Grip", "Core", "Traps", "Shoulders"],
        "Suitcase Carry":    ["Core", "Grip", "Shoulders"],
        "Zercher Carry":     ["Core", "Upper Back", "Biceps"],
        "Yoke Walk":         ["Core", "Traps", "Quads", "Glutes"],
        // Olympic
        "Squat Snatch":      ["Quads", "Glutes", "Shoulders", "Core", "Upper Back"],
        "Squat Clean":       ["Quads", "Glutes", "Hamstrings", "Upper Back", "Core"],
        "Power Clean":       ["Quads", "Glutes", "Hamstrings", "Upper Back", "Core"],
        "Power Snatch":      ["Quads", "Glutes", "Shoulders", "Core"],
        "Hang Clean":        ["Hamstrings", "Glutes", "Upper Back", "Core"],
        "Hang Snatch":       ["Hamstrings", "Glutes", "Shoulders", "Core"],
        "Split Jerk":        ["Quads", "Shoulders", "Triceps", "Core"],
        "Push Jerk":         ["Shoulders", "Triceps", "Core", "Quads"],
        "Clean and Jerk":    ["Quads", "Glutes", "Hamstrings", "Shoulders", "Core", "Upper Back"],
        "Muscle Snatch":     ["Shoulders", "Upper Back", "Core"],
        "Muscle Clean":      ["Upper Back", "Biceps", "Core"],
        // Squat and lunge variations
        "Dumbbell Front Squat":           ["Quads", "Glutes", "Core"],
        "Kettlebell Front Squat":         ["Quads", "Glutes", "Core", "Upper Back"],
        "Split Squat":                    ["Quads", "Glutes"],
        "Bulgarian Split Squat":          ["Quads", "Glutes"],
        "Dumbbell Split Squat":           ["Quads", "Glutes"],
        "Dumbbell Bulgarian Split Squat": ["Quads", "Glutes"],
        "Kettlebell Split Squat":         ["Quads", "Glutes"],
        "Band Bulgarian Split Squat":     ["Quads", "Glutes"],
        "Reverse Lunge":                  ["Quads", "Glutes"],
        "Walking Lunge":                  ["Quads", "Glutes"],
        "Dumbbell Lunge":                 ["Quads", "Glutes"],
        "Kettlebell Reverse Lunge":       ["Quads", "Glutes"],
        "Lateral Lunge":                  ["Quads", "Glutes", "Adductors"],
        "Dumbbell Lateral Lunge":         ["Quads", "Glutes", "Adductors"],
        "Kettlebell Lateral Lunge":       ["Quads", "Glutes", "Adductors"],
        "Cossack Squat":                  ["Quads", "Glutes", "Adductors"],
        "Step-Up":                        ["Quads", "Glutes"],
        "Dumbbell Step-Up":               ["Quads", "Glutes"],
        "Kettlebell Step-Up":             ["Quads", "Glutes"],
        "Wall Sit":                       ["Quads"],
        "Squat Jump":                     ["Quads", "Glutes", "Calves"],
        "Jump Lunge":                     ["Quads", "Glutes", "Calves"],
        "Band Hip Abduction":             ["Glutes"],
        "Calf Raise":                     ["Calves"],
        "Standing Calf Raise":            ["Calves"],
        "Dumbbell Calf Raise":            ["Calves"],
        "Kettlebell Calf Raise":          ["Calves"],
        "Band Calf Raise":                ["Calves"],
        // Hip hinge variations
        "Dumbbell Romanian Deadlift":     ["Hamstrings", "Glutes", "Lower Back"],
        "Kettlebell Deadlift":            ["Hamstrings", "Glutes", "Lower Back"],
        "Band Deadlift":                  ["Hamstrings", "Glutes", "Lower Back"],
        "Single-Leg Deadlift":            ["Hamstrings", "Glutes", "Core"],
        "Dumbbell Single-Leg Deadlift":   ["Hamstrings", "Glutes", "Core"],
        "Kettlebell Single-Leg Deadlift": ["Hamstrings", "Glutes", "Core"],
        "Good Morning (Bodyweight)":      ["Hamstrings", "Glutes", "Lower Back"],
        "Dumbbell Good Morning":          ["Hamstrings", "Glutes", "Lower Back"],
        "Kettlebell Good Morning":        ["Hamstrings", "Glutes", "Lower Back"],
        "Glute Bridge":                   ["Glutes", "Hamstrings"],
        "Single-Leg Glute Bridge":        ["Glutes", "Hamstrings"],
        "Dumbbell Hip Thrust":            ["Glutes", "Hamstrings"],
        "Kettlebell Hip Thrust":          ["Glutes", "Hamstrings"],
        "Band Hip Thrust":                ["Glutes", "Hamstrings"],
        "Nordic Curl Negative":           ["Hamstrings", "Glutes"],
        "Dumbbell Swing":                 ["Hamstrings", "Glutes", "Core"],
        "Kettlebell Single-Arm Swing":    ["Hamstrings", "Glutes", "Core", "Grip"],
        "Dumbbell Clean":                 ["Hamstrings", "Glutes", "Upper Back", "Core"],
        "Kettlebell Clean":               ["Hamstrings", "Glutes", "Upper Back", "Core"],
        // Press variations
        "Machine Chest Press":             ["Chest", "Triceps", "Front Delts"],
        "Dumbbell Floor Press":            ["Chest", "Triceps", "Front Delts"],
        "Dumbbell Squeeze Press":          ["Chest", "Triceps"],
        "Kettlebell Floor Press":          ["Chest", "Triceps", "Front Delts"],
        "Cable Chest Fly":                 ["Chest", "Front Delts"],
        "Band Chest Fly":                  ["Chest", "Front Delts"],
        "Band Incline Press":              ["Upper Chest", "Triceps", "Front Delts"],
        "Machine Shoulder Press":          ["Front Delts", "Triceps", "Side Delts"],
        "Dumbbell Arnold Press":           ["Front Delts", "Side Delts", "Triceps"],
        "Kettlebell Strict Press":         ["Front Delts", "Triceps", "Upper Chest"],
        "Kettlebell Z Press":              ["Front Delts", "Triceps", "Core"],
        "Kettlebell Half-Kneeling Press":  ["Front Delts", "Triceps", "Core"],
        "Kettlebell Tall-Kneeling Press":  ["Front Delts", "Triceps", "Core"],
        "Kettlebell See-Saw Press":        ["Front Delts", "Triceps", "Core"],
        "Kettlebell Bottoms-Up Press":     ["Front Delts", "Triceps", "Grip", "Core"],
        "Dumbbell Push Press":             ["Front Delts", "Triceps", "Core", "Quads"],
        "Kettlebell Push Press":           ["Front Delts", "Triceps", "Core", "Quads"],
        "Dumbbell Thruster":               ["Quads", "Glutes", "Shoulders", "Triceps", "Core"],
        "Kettlebell Thruster":             ["Quads", "Glutes", "Shoulders", "Triceps", "Core"],
        "Dumbbell Lateral Raise":          ["Side Delts"],
        "Dumbbell Front Raise":            ["Front Delts"],
        "Skull Crusher":                   ["Triceps"],
        "Overhead Triceps Extension":      ["Triceps"],
        "Band Overhead Triceps Extension": ["Triceps"],
        "Cable Triceps Pressdown":         ["Triceps"],
        "Dumbbell Triceps Kickback":       ["Triceps"],
        "Band Triceps Kickback":           ["Triceps"],
        "Dips":                            ["Chest", "Triceps", "Front Delts"],
        "Bench Dip":                       ["Triceps", "Chest", "Front Delts"],
        "Incline Push-Up":                 ["Chest", "Triceps", "Front Delts"],
        "Decline Push-Up":                 ["Chest", "Triceps", "Front Delts"],
        "Wide Push-Up":                    ["Chest", "Front Delts", "Triceps"],
        "Diamond Push-Up":                 ["Triceps", "Chest"],
        "Pike Push-Up":                    ["Front Delts", "Triceps", "Upper Chest"],
        "Pseudo Planche Push-Up":          ["Chest", "Front Delts", "Triceps", "Core"],
        "Handstand Hold":                  ["Front Delts", "Triceps", "Core"],
        // Pull variations
        "Chest-Supported Row":            ["Upper Back", "Lats", "Biceps", "Rear Delts"],
        "Kettlebell Chest-Supported Row": ["Upper Back", "Lats", "Biceps"],
        "Kettlebell Row":                 ["Upper Back", "Lats", "Biceps"],
        "Kettlebell Gorilla Row":         ["Upper Back", "Lats", "Biceps"],
        "Dumbbell Renegade Row":          ["Upper Back", "Lats", "Core"],
        "Kettlebell Renegade Row":        ["Upper Back", "Lats", "Core"],
        "Inverted Row":                   ["Upper Back", "Lats", "Biceps"],
        "Towel Inverted Row":             ["Upper Back", "Lats", "Biceps", "Grip"],
        "Chin-Up":                        ["Lats", "Biceps", "Upper Back"],
        "Negative Pull-Up":               ["Lats", "Biceps", "Upper Back"],
        "Scapular Pull-Up":               ["Lats", "Upper Back", "Traps"],
        "Straight-Arm Pulldown":          ["Lats", "Upper Back"],
        "Dumbbell Pullover":              ["Lats", "Chest"],
        "Rear Delt Fly":                  ["Rear Delts", "Upper Back"],
        "Band Reverse Fly":               ["Rear Delts", "Upper Back"],
        "Prone W Raise":                  ["Rear Delts", "Upper Back"],
        "Prone Y Raise":                  ["Rear Delts", "Upper Back", "Traps"],
        "Barbell Shrug":                  ["Traps"],
        "Dumbbell Shrug":                 ["Traps"],
        "Kettlebell Shrug":               ["Traps"],
        "Band Shrug":                     ["Traps"],
        "Kettlebell Upright Row":         ["Side Delts", "Traps", "Biceps"],
        "Band Upright Row":               ["Side Delts", "Traps", "Biceps"],
        "Dumbbell High Pull":             ["Traps", "Side Delts", "Upper Back"],
        "Kettlebell High Pull":           ["Traps", "Side Delts", "Upper Back"],
        "Cable Curl":                     ["Biceps"],
        "Kettlebell Curl":                ["Biceps"],
        "Dumbbell Concentration Curl":    ["Biceps"],
        // Carries
        "Kettlebell Farmer Carry": ["Grip", "Core", "Traps", "Shoulders"],
        "Bear Crawl":              ["Core", "Shoulders", "Quads"],
        // Core
        "Plank Hold":                    ["Core"],
        "Side Plank Hold":               ["Core"],
        "Hollow Body Hold":              ["Core"],
        "Dead Bug":                      ["Core"],
        "Dumbbell Dead Bug":             ["Core"],
        "Kettlebell Dead Bug":           ["Core"],
        "Bird Dog":                      ["Core", "Lower Back", "Glutes"],
        "Superman Hold":                 ["Lower Back", "Glutes", "Upper Back"],
        "Sit-Up":                        ["Core"],
        "Weighted Sit-Up":               ["Core"],
        "Dumbbell Weighted Sit-Up":      ["Core"],
        "V-up":                          ["Core"],
        "Bicycle Crunch":                ["Core"],
        "Flutter Kick":                  ["Core"],
        "Leg Raise":                     ["Core"],
        "Hanging Leg Raise":             ["Core", "Grip", "Lats"],
        "L-Sit Hold":                    ["Core", "Triceps", "Quads"],
        "Cable Crunch":                  ["Core"],
        "Cable Wood Chop":               ["Core"],
        "Band Russian Twist":            ["Core"],
        "Dumbbell Russian Twist":        ["Core"],
        "Kettlebell Russian Twist":      ["Core"],
        "Dumbbell Side Bend":            ["Core"],
        "Kettlebell Side Bend":          ["Core"],
        "Ab Wheel Rollout":              ["Core", "Lats"],
        "Mountain Climber":              ["Core", "Shoulders"],
        "Kettlebell Halo":               ["Core", "Shoulders"],
        "Kettlebell Rack Hold":          ["Core", "Grip", "Upper Back"],
        "Kettlebell Overhead Hold":      ["Core", "Shoulders", "Grip"],
        "Kettlebell Plank Pull-Through": ["Core", "Shoulders"],
        "Kettlebell Windmill":           ["Core", "Shoulders", "Hamstrings"],
        "Turkish Get-Up":                ["Core", "Shoulders", "Quads", "Glutes"],
        // Conditioning
        "Air Squat":               ["Quads", "Glutes", "Core"],
        "Box Step-up":             ["Quads", "Glutes"],
        "Lunges (Alternating)":    ["Quads", "Glutes"],
        "Box Jump":                ["Quads", "Glutes", "Calves"],
        "Broad Jump":              ["Quads", "Glutes", "Calves"],
        "Skater Jump":             ["Glutes", "Quads", "Adductors", "Calves"],
        "Shuttle Run":             ["Quads", "Glutes", "Calves"],
        "High Knees":              ["Quads", "Calves", "Core"],
        "Jumping Jack":            ["Calves", "Side Delts", "Quads"],
        "Double Under":            ["Calves", "Shoulders", "Core"],
        "Burpee":                  ["Quads", "Chest", "Core", "Triceps"],
        "Push-Up":                 ["Chest", "Triceps", "Front Delts"],
        "Handstand Push-up":       ["Front Delts", "Triceps", "Core"],
        "Wall Walk":               ["Front Delts", "Core", "Triceps"],
        "Muscle-Up":               ["Lats", "Biceps", "Triceps", "Chest", "Core"],
        "Pull-Up (Kipping)":       ["Lats", "Biceps", "Upper Back", "Core"],
        "Toes-to-Bar":             ["Core", "Lats", "Grip"],
        "GHD Sit-up":              ["Core", "Quads"],
        "Thruster":                ["Quads", "Glutes", "Shoulders", "Triceps", "Core"],
        "Wall Ball":               ["Quads", "Glutes", "Shoulders", "Triceps"],
        "Kettlebell Swing":        ["Hamstrings", "Glutes", "Core", "Grip"],
        "Kettlebell Snatch":       ["Hamstrings", "Glutes", "Shoulders", "Core"],
        "Dumbbell Snatch":         ["Hamstrings", "Glutes", "Shoulders", "Core"],
        "Sled Push":               ["Quads", "Glutes", "Calves", "Core"],
        "Battle Rope Wave":        ["Shoulders", "Core", "Grip"],
        "400m Run":                ["Quads", "Hamstrings", "Calves", "Glutes"],
        "800m Run":                ["Quads", "Hamstrings", "Calves", "Glutes"],
        "1-Mile Run":              ["Quads", "Hamstrings", "Calves", "Glutes"],
        "5K Run":                  ["Quads", "Hamstrings", "Calves", "Glutes"],
        "500m Row":                ["Lats", "Quads", "Upper Back", "Hamstrings", "Core"],
        "2K Row":                  ["Lats", "Quads", "Upper Back", "Hamstrings", "Core"],
        "Rowing (Calories)":       ["Lats", "Quads", "Upper Back", "Hamstrings", "Core"],
        "Rowing Machine Interval": ["Lats", "Quads", "Upper Back", "Hamstrings", "Core"],
        "2K SkiErg":               ["Lats", "Core", "Triceps", "Upper Back"],
        "SkiErg (Calories)":       ["Lats", "Core", "Triceps", "Upper Back"],
        "SkiErg Interval":         ["Lats", "Core", "Triceps", "Upper Back"],
        "1K Assault Bike":         ["Quads", "Hamstrings", "Shoulders", "Core"],
        "Assault Bike (Calories)": ["Quads", "Hamstrings", "Shoulders", "Core"],
        "Assault Bike Interval":   ["Quads", "Hamstrings", "Shoulders", "Core"],
    ]

    // MARK: - Ranking

    /// Finds and ranks substitute exercises for a given target.
    ///
    /// - Parameters:
    ///   - target: The exercise to substitute.
    ///   - injuries: Current active injuries (used for graded injury compatibility scoring).
    ///   - equipment: Available equipment.
    ///   - profile: Optional coach profile for user history preferences.
    ///   - limit: Maximum number of results (default 5).
    /// - Returns: Ranked substitutions, best first.
    public static func rank(
        substitutesFor target: String,
        injuries: [Injury] = [],
        equipment: EquipmentContext = .fullGym,
        profile: CoachProfile? = nil,
        limit: Int = 5
    ) -> [RankedSubstitution] {
        guard let targetEntry = substitutionCatalog.first(where: { $0.id == target }) else {
            return []
        }
        let targetCategory = targetEntry.category

        let candidates = substitutionCatalog.filter {
            $0.id != target
        }

        var scored: [RankedSubstitution] = []

        for candidate in candidates {
            // Graded injury compatibility (replaces binary filtering)
            let injuryScore = injuryCompatibilityScore(
                exerciseName: candidate.id,
                injuries: injuries
            )
            // Skip fully contraindicated exercises (acute/rehab phase)
            if injuryScore <= 0 { continue }

            // Skip if equipment doesn't match
            if !matchesEquipment(candidate.id, equipment: equipment) {
                continue
            }

            var score = 0.0
            var reasons: [String] = []

            // Muscle activation overlap (strongest signal)
            let muscleOverlap = muscleOverlapScore(target, candidate.id)
            if muscleOverlap > 0 {
                score += muscleOverlap * 0.4
                if muscleOverlap > 0.5 {
                    reasons.append("targets similar muscles")
                }
            }

            // Same category bonus (reduced from 0.5 to 0.35 since muscle overlap is now primary)
            if candidate.category == targetCategory {
                score += 0.35
                if muscleOverlap == 0 {
                    reasons.append("same movement pattern")
                }
            } else if areRelatedCategories(targetCategory, candidate.category) {
                score += 0.2
                reasons.append("related movement")
            }

            // Similarity bonus based on name overlap
            let nameSimilarity = nameSimilarityScore(target, candidate.id)
            score += nameSimilarity * 0.2
            if nameSimilarity > 0.3 {
                reasons.append("similar exercise variant")
            }

            // Equipment simplicity bonus
            if isDumbbellExercise(candidate.id) && !isDumbbellExercise(target) {
                score += 0.1
                reasons.append("dumbbell alternative")
            }

            // Machine alternative bonus when injured
            if !injuries.isEmpty && isMachineExercise(candidate.id) {
                score += 0.1
                reasons.append("machine (more controlled)")
            }

            // User history preferences from CoachProfile
            if let profile = profile {
                if profile.favoriteExercises.contains(candidate.id) {
                    score += 0.15
                    reasons.append("matches your preferences")
                }
                if profile.avoidedExercises.contains(candidate.id) {
                    score -= 0.2
                    reasons.append("previously avoided")
                }
            }

            // Apply graded injury penalty
            score *= injuryScore
            if injuryScore < 1.0 && injuryScore > 0 {
                reasons.append("caution: near injury area")
            }

            let reason = reasons.isEmpty ? "alternative option" : reasons.joined(separator: ", ")
            let capped = min(max(score, 0), 1.0)

            scored.append(RankedSubstitution(
                exerciseName: candidate.id,
                category: candidate.category,
                score: capped,
                reason: reason.prefix(1).uppercased() + reason.dropFirst()
            ))
        }

        return Array(scored.sorted { $0.score > $1.score }.prefix(limit))
    }

    // MARK: - Muscle Overlap

    private static var substitutionCatalog: [SubstitutionCatalogEntry] {
        var seen = Set<String>()
        let maxEntries = weightliftingExercises.map {
            SubstitutionCatalogEntry(id: $0.id, category: $0.category)
        }
        let trainingEntries = trainingExerciseCatalog.map {
            SubstitutionCatalogEntry(
                id: $0.id,
                category: category(for: $0.movementPattern)
            )
        }
        return (maxEntries + trainingEntries).filter { seen.insert($0.id).inserted }
    }

    private static func category(for pattern: WorkoutMovementPattern) -> WeightliftingCategory {
        switch pattern {
        case .squat: return .squat
        case .hinge: return .hipHinge
        case .push: return .press
        case .pull: return .pull
        case .carry, .core, .conditioning: return .carry
        }
    }

    /// Computes Jaccard similarity between the muscle groups of two exercises.
    /// Returns 0 if either exercise has no known muscle data.
    private static func muscleOverlapScore(_ a: String, _ b: String) -> Double {
        guard let aMuscles = muscleGroups[canonicalExerciseID(a)],
              let bMuscles = muscleGroups[canonicalExerciseID(b)] else {
            return 0
        }
        let intersection = aMuscles.intersection(bMuscles)
        let union = aMuscles.union(bMuscles)
        guard !union.isEmpty else { return 0 }
        return Double(intersection.count) / Double(union.count)
    }

    // MARK: - Injury Compatibility

    /// Returns a graded injury compatibility score.
    /// - 1.0: fully safe (no relevant injuries or resolved phase)
    /// - 0.5: partially restricted (lightLoad or returnToPlay phase)
    /// - 0.0: contraindicated (acute or rehab phase)
    private static func injuryCompatibilityScore(
        exerciseName: String,
        injuries: [Injury]
    ) -> Double {
        guard !injuries.isEmpty else { return 1.0 }

        var worstScore = 1.0
        for injury in injuries {
            let contraindicated = InjuryAdaptationEngine.isContraindicated(
                exerciseName: exerciseName,
                exerciseCategory: nil,
                injuries: [injury]
            )
            if contraindicated {
                switch injury.recoveryPhase {
                case .acute, .rehab:
                    return 0.0
                case .lightLoad, .returnToPlay:
                    worstScore = min(worstScore, 0.5)
                case .resolved:
                    break
                }
            }
        }
        return worstScore
    }

    // MARK: - Private Helpers

    private static func matchesEquipment(_ exercise: String, equipment: EquipmentContext) -> Bool {
        let name = exercise.lowercased()

        if let definition = trainingExerciseCatalog.first(where: { $0.id == canonicalExerciseID(exercise) }) {
            return definition.equipmentTags.allSatisfy { tag in
                switch tag {
                case .barbell, .plates:
                    return equipment.hasBarbell
                case .dumbbells:
                    return equipment.hasDumbbells
                case .kettlebell:
                    return equipment.hasKettlebells
                case .bands:
                    return equipment.hasBands
                case .machine, .cable, .cardio, .box:
                    return equipment.hasMachines
                case .bodyweight:
                    return true
                }
            }
        }

        if name.contains("barbell") || name.contains("bar ") {
            return equipment.hasBarbell
        }
        if name.contains("dumbbell") {
            return equipment.hasDumbbells
        }
        if name.contains("kettlebell") {
            return equipment.hasKettlebells
        }
        if name.contains("band") || name.contains("pallof") {
            return equipment.hasBands
        }
        if name.contains("pull-up") || name.contains("chin-up") || name.contains("muscle-up") {
            return equipment.hasPullUpBar
        }
        if name.contains("cable") || name.contains("machine") || name.contains("lat pulldown")
            || name.contains("leg press") || name.contains("hack squat")
            || name.contains("leg extension") || name.contains("leg curl") {
            return equipment.hasMachines
        }

        return true
    }

    private static func areRelatedCategories(
        _ a: WeightliftingCategory,
        _ b: WeightliftingCategory
    ) -> Bool {
        let relatedPairs: Set<Set<WeightliftingCategory>> = [
            [.squat, .hipHinge],
            [.press, .olympicWeightlifting],
            [.pull, .olympicWeightlifting],
        ]
        return relatedPairs.contains([a, b])
    }

    private static func nameSimilarityScore(_ a: String, _ b: String) -> Double {
        let aWords = Set(a.lowercased().split(separator: " ").map(String.init))
        let bWords = Set(b.lowercased().split(separator: " ").map(String.init))
        let common = aWords.intersection(bWords)
        let total = aWords.union(bWords)
        guard !total.isEmpty else { return 0 }
        return Double(common.count) / Double(total.count)
    }

    private static func isDumbbellExercise(_ name: String) -> Bool {
        name.lowercased().contains("dumbbell")
    }

    private static func isMachineExercise(_ name: String) -> Bool {
        let keywords = ["machine", "cable", "lat pulldown", "leg press",
                        "hack squat", "leg extension", "leg curl"]
        let lower = name.lowercased()
        return keywords.contains(where: { lower.contains($0) })
    }
}
