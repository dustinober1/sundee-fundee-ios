import Foundation

// MARK: - Injury Profile

/// Minimal interface for injury adaptation
public struct InjuryProfile: Sendable {
    public let id: String
    public let location: String  // comma-separated region IDs or free-text
    public let recoveryPhase: RecoveryPhase

    public init(id: String, location: String, recoveryPhase: RecoveryPhase) {
        self.id = id
        self.location = location
        self.recoveryPhase = recoveryPhase
    }
}

// MARK: - Contraindication Rules

private struct ContraindicationRule {
    let categories: [String]
    let keywords: [String]
}

private let contraindicationRules: [String: ContraindicationRule] = [
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

private let clinicalSynonyms: [String: String] = [
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

private let regressionTable: [String: [String]] = [
    "Back Squat":                  ["Goblet Squat", "Box Squat", "Air Squats"],
    "Front Squat":                 ["Goblet Squat", "Box Squat", "Air Squats"],
    "Flat Barbell Bench Press":    ["Dumbbell Bench Press", "Push-Ups", "Floor Press"],
    "Incline Barbell Bench Press": ["Dumbbell Bench Press", "Push-Ups", "Floor Press"],
    "Strict Press":                ["Lateral Raises", "Z-Press", "Seated Dumbbell Press"],
    "Push Press":                  ["Dumbbell Overhead Press", "Lateral Raises", "Arnold Press"],
    "Conventional Deadlift (No Straps)":   ["Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
    "Conventional Deadlift (With Straps)": ["Romanian Deadlift (No Straps)", "Trap Bar Deadlift (No Straps)", "Kettlebell Deadlift"],
    "Romanian Deadlift (No Straps)":  ["Nordic Curl", "Glute Bridge", "Hip Thrust"],
    "Romanian Deadlift (With Straps)": ["Nordic Curl", "Glute Bridge", "Hip Thrust"],
    "Squat Snatch":    ["Power Snatch", "Hang Snatch", "Overhead Squat"],
    "Squat Clean":     ["Power Clean", "Hang Clean", "Front Squat"],
    "Power Clean":     ["Hang Clean", "Kettlebell Deadlift", "Hip Thrust"],
    "Power Snatch":    ["Hang Snatch", "Kettlebell Deadlift", "Hip Thrust"],
    "Clean and Jerk":  ["Power Clean", "Push Press", "Front Squat"],
    "Split Jerk":      ["Push Press", "Push Jerk", "Strict Press"],
    "Pull-Up":         ["Lat Pulldown", "Band-Assisted Pull-Up", "TRX Row"],
    "Barbell Row":     ["Dumbbell Row", "Cable Row", "TRX Row"],
    "Pendlay Row":     ["Dumbbell Row", "Cable Row", "TRX Row"],
]

// MARK: - Recovery Prep Map

private let recoveryPrepMap: [String: [String]] = [
    "knee":     ["Bird-Dogs", "Reverse Lunges", "Terminal Knee Extension"],
    "shoulder": ["Band Pull-Aparts", "Face Pulls", "Wall Slides"],
    "back":     ["Cat-Cow", "Bird-Dogs", "Dead Bugs"],
    "hip":      ["Glute Bridges", "Clamshells", "Side-Lying Hip Abduction"],
    "wrist":    ["Wrist Circles", "Finger Extensions", "Prayer Stretches"],
    "elbow":    ["Wrist Curls", "Reverse Wrist Curls", "Forearm Pronation"],
    "ankle":    ["Calf Raises", "Ankle Circles", "Banded Dorsiflexion"],
]

private let safeBodyweight = ["Air Squats", "Bird-Dogs", "Bodyweight Lunges"]

// MARK: - normalizeBodyRegions

/// Normalize injury location to engine keys
public func normalizeBodyRegions(regions: [String], freeText: String? = nil) -> [String] {
    var result = Set<String>()
    let knownKeys = Set(contraindicationRules.keys)

    for regionId in regions {
        if let bodyRegion = bodyRegions.first(where: { $0.id == regionId }),
           knownKeys.contains(bodyRegion.engineKey) {
            result.insert(bodyRegion.engineKey)
        }
    }

    if let freeText, !freeText.isEmpty {
        let lower = freeText.lowercased()
        for key in knownKeys {
            if lower.contains(key) { result.insert(key) }
        }
        for (synonym, key) in clinicalSynonyms {
            if lower.contains(synonym) { result.insert(key) }
        }
    }

    return Array(result)
}

// MARK: - mostRestrictivePhase

private let phaseOrder: [RecoveryPhase] = [.acute, .rehab, .lightLoad, .returnToPlay, .resolved]

/// Find the most restrictive phase among a set of phases
public func mostRestrictivePhase(_ phases: [RecoveryPhase]) -> RecoveryPhase? {
    guard !phases.isEmpty else { return nil }
    return phases.min { a, b in
        (phaseOrder.firstIndex(of: a) ?? 0) < (phaseOrder.firstIndex(of: b) ?? 0)
    }
}

// MARK: - Contraindication Check

private func isContraindicated(_ exerciseName: String, engineKeys: [String]) -> Bool {
    let lower = exerciseName.lowercased()
    for key in engineKeys {
        guard let rule = contraindicationRules[key] else { continue }
        for keyword in rule.keywords {
            if lower.contains(keyword) { return true }
        }
        for cat in rule.categories {
            if lower.contains(cat.lowercased()) { return true }
        }
    }
    return false
}

private func findReplacement(_ exerciseName: String, engineKeys: [String]) -> String {
    if let regressions = regressionTable[exerciseName] {
        for candidate in regressions {
            if !isContraindicated(candidate, engineKeys: engineKeys) {
                return candidate
            }
        }
    }
    for safe in safeBodyweight {
        if !isContraindicated(safe, engineKeys: engineKeys) {
            return safe
        }
    }
    return exerciseName
}

// MARK: - Recovery Prep Block

/// A simple exercise entry for recovery prep
public struct RecoveryPrepExercise: Sendable {
    public let exercise: String
    public let sets: Int
    public let reps: Int
    public let restMinutes: Double
    public let notes: String
}

/// Build a recovery prep block for the given injuries
public func buildRecoveryPrepBlock(injuries: [InjuryProfile], phase: RecoveryPhase? = nil) -> [RecoveryPrepExercise] {
    var seen = Set<String>()
    var block: [RecoveryPrepExercise] = []

    var engineKeys: [String] = []
    for injury in injuries {
        let regions = injury.location.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let keys = normalizeBodyRegions(regions: regions, freeText: injury.location)
        engineKeys.append(contentsOf: keys)
    }
    let uniqueKeys = Array(Set(engineKeys))

    for key in uniqueKeys {
        let exercises = recoveryPrepMap[key] ?? []
        for ex in exercises {
            guard !seen.contains(ex) else { continue }
            seen.insert(ex)

            var sets = 2, reps = 10
            var notes = "Recovery prep — gentle movement only"

            if phase == .rehab {
                sets = 3; reps = 12
                notes = "Recovery prep — controlled movement"
            } else if phase == .lightLoad {
                sets = 2; reps = 15
                notes = "Recovery prep — slow and controlled"
            }

            block.append(RecoveryPrepExercise(exercise: ex, sets: sets, reps: reps, restMinutes: 1, notes: notes))
        }
    }

    return block
}
