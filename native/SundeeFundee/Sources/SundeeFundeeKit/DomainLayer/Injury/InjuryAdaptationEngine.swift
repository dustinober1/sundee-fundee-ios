import Foundation

// MARK: - Injury Adaptation Engine

/// Modifies workouts based on user's active injuries
public struct InjuryAdaptationEngine {

    // MARK: - Contraindication Rules

    struct ContraindicationRule {
        let categories: [String]
        let keywords: [String]
    }

    /// Rules for determining which exercises are contraindicated for each body region
    private static let contraindicationRules: [String: ContraindicationRule] = [
        "knee": ContraindicationRule(
            categories: ["Squat"],
            keywords: ["squat", "lunge", "leg press", "leg extension", "box jump", "jump"]
        ),
        "shoulder": ContraindicationRule(
            categories: ["Press", "Olympic Weightlifting"],
            keywords: ["press", "overhead", "bench", "push-up", "dip", "fly", "raise"]
        ),
        "back": ContraindicationRule(
            categories: ["Hip Hinge"],
            keywords: ["deadlift", "good morning", "row", "back extension", "hyperextension"]
        ),
        "hip": ContraindicationRule(
            categories: [],
            keywords: ["hip thrust", "glute", "hamstring", "lunge", "step-up"]
        ),
        "wrist": ContraindicationRule(
            categories: ["Olympic Weightlifting"],
            keywords: ["clean", "snatch", "jerk", "front squat", "wrist"]
        ),
        "elbow": ContraindicationRule(
            categories: [],
            keywords: ["curl", "tricep", "extension", "press"]
        ),
        "ankle": ContraindicationRule(
            categories: [],
            keywords: ["calf", "jump", "run", "sprint", "box jump"]
        ),
    ]

    // MARK: - Clinical Synonyms

    /// Maps clinical terms to body region engine keys
    private static let clinicalSynonyms: [String: String] = [
        "acl": "knee",
        "mcl": "knee",
        "meniscus": "knee",
        "patella": "knee",
        "rotator cuff": "shoulder",
        "labrum": "shoulder",
        "frozen shoulder": "shoulder",
        "lumbar": "back",
        "herniated disc": "back",
        "sciatica": "back",
        "si joint": "hip",
        "piriformis": "hip",
        "carpal tunnel": "wrist",
        "tennis elbow": "elbow",
        "golfers elbow": "elbow",
        "achilles": "ankle",
        "plantar fascia": "ankle",
    ]

    // MARK: - Regression Table

    /// Maps exercises to progressively easier alternatives
    private static let regressionTable: [String: [String]] = [
        "Back Squat": ["Goblet Squat", "Box Squat", "Air Squats"],
        "Front Squat": ["Goblet Squat", "Box Squat", "Air Squats"],
        "Flat Barbell Bench Press": ["Dumbbell Bench Press", "Push-Ups", "Floor Press"],
        "Incline Barbell Bench Press": ["Dumbbell Bench Press", "Push-Ups", "Floor Press"],
        "Strict Press": ["Lateral Raises", "Z-Press", "Seated Dumbbell Press"],
        "Push Press": ["Dumbbell Overhead Press", "Lateral Raises", "Arnold Press"],
        "Conventional Deadlift": ["Romanian Deadlift", "Trap Bar Deadlift", "Kettlebell Deadlift"],
        "Romanian Deadlift": ["Nordic Curl", "Glute Bridge", "Hip Thrust"],
        "Squat Snatch": ["Power Snatch", "Hang Snatch", "Overhead Squat"],
        "Squat Clean": ["Power Clean", "Hang Clean", "Front Squat"],
        "Power Clean": ["Hang Clean", "Kettlebell Deadlift", "Hip Thrust"],
        "Power Snatch": ["Hang Snatch", "Kettlebell Deadlift", "Hip Thrust"],
        "Clean and Jerk": ["Power Clean", "Push Press", "Front Squat"],
        "Split Jerk": ["Push Press", "Push Jerk", "Strict Press"],
        "Pull-Up": ["Lat Pulldown", "Band-Assisted Pull-Up", "TRX Row"],
        "Toes-to-Bar": ["Knees-to-Elbows", "Hanging Leg Raises", "Lying Leg Raises"],
        "Box Jump": ["Step-Up", "Box Step-Up", "Air Squats"],
        "Burpee": ["Step-Up Burpee", "Squat Thrust", "Air Squat"],
    ]

    // MARK: - Load Multipliers by Phase

    /// Load reduction multipliers for each recovery phase
    private static let loadMultipliers: [RecoveryPhase: Double] = [
        .acute: 0.3,
        .rehab: 0.5,
        .lightLoad: 0.7,
        .returnToPlay: 0.85,
        .resolved: 1.0,
    ]

    // MARK: - Public Methods

    /// Check if an exercise is contraindicated for the given injuries
    public static func isContraindicated(
        exerciseName: String,
        exerciseCategory: String?,
        injuries: [Injury]
    ) -> Bool {
        // No active injuries (only resolved ones)
        let activeInjuries = injuries.filter { $0.recoveryPhase != .resolved }
        guard !activeInjuries.isEmpty else { return false }

        let lowerExerciseName = exerciseName.lowercased()

        for injury in activeInjuries {
            let regions = injury.bodyRegions

            for region in regions {
                // Check clinical synonyms first
                let engineKey = clinicalSynonyms[injury.name.lowercased()] ?? region.engineKey

                guard let rule = contraindicationRules[engineKey] else { continue }

                // Check category match
                if let category = exerciseCategory {
                    if rule.categories.contains(where: { category.localizedCaseInsensitiveContains($0) }) {
                        return true
                    }
                }

                // Check keyword match
                for keyword in rule.keywords {
                    if lowerExerciseName.contains(keyword.lowercased()) {
                        return true
                    }
                }
            }
        }

        return false
    }

    /// Get regressions for an exercise based on injuries
    public static func getRegressions(
        exerciseName: String,
        injuries: [Injury]
    ) -> [String] {
        // Find the base exercise name in the regression table
        for (baseExercise, regressions) in regressionTable {
            if exerciseName.lowercased().contains(baseExercise.lowercased()) ||
               baseExercise.lowercased().contains(exerciseName.lowercased()) {
                return regressions
            }
        }

        return []
    }

    /// Calculate appropriate load multiplier based on injuries
    public static func calculateLoadMultiplier(
        baseLoad: Double,
        injuries: [Injury]
    ) -> Double {
        // Find the most severe (lowest multiplier) injury
        let activeInjuries = injuries.filter { $0.recoveryPhase != .resolved }

        guard !activeInjuries.isEmpty else { return 1.0 }

        let minMultiplier = activeInjuries
            .compactMap { loadMultipliers[$0.recoveryPhase] }
            .min() ?? 1.0

        return baseLoad * minMultiplier
    }

    /// Get recommended exercises for a given injury
    public static func getRecommendedExercises(for injury: Injury) -> [String] {
        let regions = injury.bodyRegions
        var recommendations: [String] = []

        for region in regions {
            switch region.engineKey {
            case "knee":
                recommendations += ["Box Squat", "Glute Bridge", "Hip Thrust", "Calf Raises"]
            case "shoulder":
                recommendations += ["Lateral Raises", "Front Raises", "Face Pulls", "Band Pull-Aparts"]
            case "back":
                recommendations += ["Bird Dog", "Cat-Cow", "Plank", "Side Plank"]
            case "hip":
                recommendations += ["Clamshells", "Fire Hydrants", "Glute Bridges", "Lateral Band Walks"]
            case "wrist":
                recommendations += ["Knuckle Push-Ups", "Ring Rows", "Farmer's Carries"]
            case "elbow":
                recommendations += ["Hammer Curls", "Reverse Curls", "Tricep Pushdowns (Light Band)"]
            case "ankle":
                recommendations += ["Ankle Circles", "Single-Leg Balance", "Calf Raises (Seated)"]
            default:
                break
            }
        }

        return Array(Set(recommendations)) // Remove duplicates
    }

    /// Get contraindicated keywords for a given injury
    public static func getContraindicatedKeywords(for injury: Injury) -> [String] {
        let regions = injury.bodyRegions
        var keywords: [String] = []

        for region in regions {
            // Check clinical synonyms first
            let engineKey = clinicalSynonyms[injury.name.lowercased()] ?? region.engineKey

            if let rule = contraindicationRules[engineKey] {
                keywords.append(contentsOf: rule.keywords)
            }
        }

        return Array(Set(keywords)) // Remove duplicates
    }
}
