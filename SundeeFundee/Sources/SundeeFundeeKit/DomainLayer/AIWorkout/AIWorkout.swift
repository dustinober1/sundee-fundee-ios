import Foundation

// MARK: - Types

/// Workout focus area
public enum WorkoutFocus: String, Codable, Sendable {
    case upperBody = "upper_body"
    case lowerBody = "lower_body"
    case fullBody = "full_body"
    case push
    case pull
    case core
    case conditioning
}

/// Energy level for workout generation
public enum EnergyLevel: String, Codable, Sendable {
    case low
    case medium
    case high
}

/// Equipment access level
public enum EquipmentAccess: String, Codable, Sendable {
    case fullGym = "full_gym"
    case homeDumbbells = "home_dumbbells"
    case bodyweightOnly = "bodyweight_only"
    case outdoor
}

/// Questionnaire answers for AI workout generation
public struct QuestionnaireAnswers: Codable, Sendable {
    public let timeMinutes: Int
    public let focus: WorkoutFocus
    public let energyLevel: EnergyLevel
    public let equipment: EquipmentAccess

    public init(timeMinutes: Int, focus: WorkoutFocus, energyLevel: EnergyLevel, equipment: EquipmentAccess) {
        self.timeMinutes = timeMinutes
        self.focus = focus
        self.energyLevel = energyLevel
        self.equipment = equipment
    }
}

/// A generated exercise from AI
public struct GeneratedExercise: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let sets: Int
    public let reps: String
    public var weightKg: Double?
    public let restMinutes: Double?
    public let notes: String?
    public let reasoning: String?
    public let bodyweightOnly: Bool

    public init(id: String, name: String, sets: Int, reps: String, weightKg: Double? = nil,
                restMinutes: Double? = nil, notes: String? = nil, reasoning: String? = nil,
                bodyweightOnly: Bool = false) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.restMinutes = restMinutes
        self.notes = notes
        self.reasoning = reasoning
        self.bodyweightOnly = bodyweightOnly
    }
}

/// A complete generated workout
public struct GeneratedWorkout: Codable, Sendable, Identifiable {
    public let id: String
    public let createdAt: Date
    public var isFavorite: Bool
    public let coachingSummary: String
    public let exercises: [GeneratedExercise]
    public let questionnaire: QuestionnaireAnswers
}

/// An exercise max for weight calculation
public struct ExerciseMax: Sendable {
    public let name: String
    public let weightKg: Double

    public init(name: String, weightKg: Double) {
        self.name = name
        self.weightKg = weightKg
    }
}

// MARK: - Extract Muscle Groups

/// Extract targeted muscle groups from exercise names
public func extractMuscleGroups(_ exercises: [GeneratedExercise]) -> [String] {
    var groups = Set<String>()
    for ex in exercises {
        let name = ex.name.lowercased()
        if name.contains("squat") || name.contains("lunge") || name.contains("leg press") { groups.insert("Quads") }
        if name.contains("deadlift") || name.contains("hip thrust") || name.contains("glute") { groups.insert("Glutes") }
        if name.contains("bench") || name.contains("push") || name.contains("chest") || name.contains("fly") { groups.insert("Chest") }
        if name.contains("row") || name.contains("pull") || name.contains("lat") { groups.insert("Back") }
        if name.contains("press") && (name.contains("overhead") || name.contains("shoulder") || name.contains("military")) { groups.insert("Shoulders") }
        if name.contains("curl") || name.contains("bicep") { groups.insert("Biceps") }
        if name.contains("tricep") || name.contains("extension") || name.contains("dip") { groups.insert("Triceps") }
        if name.contains("core") || name.contains("plank") || name.contains("crunch") || name.contains("ab") { groups.insert("Core") }
        if name.contains("calf") { groups.insert("Calves") }
        if name.contains("hamstring") || name.contains("romanian") || name.contains("nordic") { groups.insert("Hamstrings") }
    }
    return groups.sorted()
}

// MARK: - Default Percentage

/// Map rep count string to default %1RM
public func aiDefaultPercentage(reps: String) -> Double {
    let repCount = Int(reps.split(separator: "-").first ?? "") ?? 10
    if repCount >= 1 && repCount <= 3 { return 0.85 }
    if repCount >= 4 && repCount <= 5 { return 0.80 }
    if repCount >= 6 && repCount <= 8 { return 0.70 }
    if repCount >= 9 && repCount <= 12 { return 0.65 }
    return 0.60
}

// MARK: - Assign Rest Minutes

/// Assign rest time based on bodyweight flag and rep count
public func assignRestMinutes(bodyweight: Bool, reps: String) -> Double {
    if bodyweight { return 1.0 }
    let repCount = Int(reps.split(separator: "-").first ?? "") ?? 10
    if repCount >= 1 && repCount <= 5 { return 2.5 }
    if repCount >= 6 && repCount <= 8 { return 2.0 }
    if repCount >= 9 && repCount <= 12 { return 1.5 }
    return 1.0
}

// MARK: - Total Estimated Minutes

/// Estimate total workout duration in minutes
public func totalEstimatedMinutes(_ exercises: [GeneratedExercise]) -> Int {
    let total = exercises.reduce(0.0) { sum, ex in
        let rest = ex.restMinutes ?? 1.5
        return sum + Double(ex.sets) * (rest + 0.5)
    }
    return max(1, Int(total.rounded()))
}

// MARK: - Energy Multiplier

/// Get energy level multiplier
public func energyMultiplier(_ level: EnergyLevel) -> Double {
    switch level {
    case .low:    return 0.85
    case .medium: return 1.0
    case .high:   return 1.05
    }
}

// MARK: - Cycle Phase Multiplier (AI)

/// Get cycle phase multiplier for AI workout generation
public func aiCyclePhaseMultiplier(_ phase: CyclePhase?) -> Double {
    guard let phase else { return 1.0 }
    switch phase {
    case .menstrual:  return 0.90
    case .follicular: return 1.00
    case .ovulation:  return 1.12
    case .luteal:     return 0.97
    }
}

// MARK: - Apply Weights

/// Apply weights to exercises based on user's maxes
public func applyWeights(
    exercises: [GeneratedExercise],
    maxes: [ExerciseMax],
    energyMult: Double,
    cycleMult: Double
) -> [GeneratedExercise] {
    exercises.map { ex in
        guard !ex.bodyweightOnly else { return ex }
        guard let matched = findMatchingMax(ex.name, maxes: maxes) else { return ex }

        let pct = aiDefaultPercentage(reps: ex.reps)
        let raw = matched.weightKg * pct * energyMult * cycleMult
        let rounded = Double(Int(raw / 5.0 + 0.5)) * 5.0

        var modified = ex
        modified.weightKg = rounded
        return modified
    }
}

// MARK: - Find Matching Max (fuzzy)

/// Fuzzy match an exercise name to a user's max
public func findMatchingMax(_ exerciseName: String, maxes: [ExerciseMax]) -> ExerciseMax? {
    let lower = exerciseName.lowercased()
    if let exact = maxes.first(where: { $0.name.lowercased() == lower }) {
        return exact
    }
    return maxes.first { m in
        m.name.lowercased().contains(lower) || lower.contains(m.name.lowercased())
    }
}
