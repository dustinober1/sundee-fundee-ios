import Foundation

// MARK: - Types

/// Workout focus area
public enum WorkoutFocus: String, Codable, Sendable, Equatable {
    case upperBody = "upper_body"
    case lowerBody = "lower_body"
    case fullBody = "full_body"
    case push
    case pull
    case core
    case conditioning
}

/// Energy level for workout generation
public enum EnergyLevel: String, Codable, Sendable, Equatable {
    case low
    case medium
    case high
}

/// Equipment access level
public enum EquipmentAccess: String, Codable, Sendable, Equatable {
    case fullGym = "full_gym"
    case homeDumbbells = "home_dumbbells"
    case bodyweightOnly = "bodyweight_only"
    case kettlebellOnly = "kettlebell_only"
    case outdoor
}

/// Questionnaire answers for AI workout generation
public struct QuestionnaireAnswers: Codable, Sendable, Equatable {
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

/// Movement-pattern metadata used by deterministic workout generation.
public enum WorkoutMovementPattern: String, Codable, Sendable {
    case squat
    case hinge
    case push
    case pull
    case core
    case carry
    case conditioning
}

/// An approved exercise candidate for a generated workout.
public struct WorkoutExerciseCandidate: Equatable, Sendable {
    public let name: String
    public let bodyweightOnly: Bool
    public let pattern: WorkoutMovementPattern
    public let isHighSkill: Bool

    public init(
        name: String,
        bodyweightOnly: Bool,
        pattern: WorkoutMovementPattern,
        isHighSkill: Bool = false
    ) {
        self.name = name
        self.bodyweightOnly = bodyweightOnly
        self.pattern = pattern
        self.isHighSkill = isHighSkill
    }
}

/// Validation issues found after deterministic workout generation.
public enum WorkoutGenerationIssue: Equatable, Sendable {
    case emptyWorkout
    case disallowedEquipment(exerciseName: String, equipment: EquipmentAccess)
    case invalidSets(exerciseName: String, sets: Int)
    case estimatedTimeTooHigh(estimated: Int, limit: Int)
    case duplicateMovementPattern(pattern: WorkoutMovementPattern)
}

/// A generated exercise from AI
public struct GeneratedExercise: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let sets: Int
    public let reps: String
    public var weightKg: Double?
    public let restMinutes: Double?
    public let notes: String?
    public let reasoning: String?
    public let bodyweightOnly: Bool
    public var percentageOfMax: Double?  // Percentage of 1RM used (e.g., 0.70 for 70%)

    public init(id: String, name: String, sets: Int, reps: String, weightKg: Double? = nil,
                restMinutes: Double? = nil, notes: String? = nil, reasoning: String? = nil,
                bodyweightOnly: Bool = false, percentageOfMax: Double? = nil) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.restMinutes = restMinutes
        self.notes = notes
        self.reasoning = reasoning
        self.bodyweightOnly = bodyweightOnly
        self.percentageOfMax = percentageOfMax
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

// MARK: - Workout Builder

public func buildWorkout(
    from generated: GeneratedWorkout,
    name: String? = nil,
    notesPrefix: String? = nil
) -> Workout {
    Workout(
        date: Date(),
        name: name ?? generated.coachingSummary,
        exercises: generated.exercises.map { exercise in
            let reps = Int(exercise.reps.split(separator: "-").first ?? "8") ?? 8
            return Exercise(
                id: UUID().uuidString,
                name: exercise.name,
                category: isWeightliftingExercise(exercise.name) ? .compound : .accessory,
                bodyweight: exercise.bodyweightOnly ? 1.0 : 0.0,
                targetSets: (0..<exercise.sets).map { _ in
                    ExerciseSet(
                        reps: reps,
                        prescribedWeight: exercise.weightKg ?? 0,
                        prescribedPercentage: exercise.percentageOfMax,
                        type: .fixed
                    )
                },
                restMinutes: exercise.restMinutes ?? 1.5
            )
        },
        notes: {
            if let notesPrefix {
                return "\(notesPrefix) - \(generated.coachingSummary)"
            }
            return generated.coachingSummary
        }()
    )
}

// MARK: - Workout Generation Rules

/// Returns the approved exercise pool for the requested focus, equipment, and energy level.
public func workoutExercisePool(
    focus: WorkoutFocus,
    equipment: EquipmentAccess,
    energyLevel: EnergyLevel
) -> [WorkoutExerciseCandidate] {
    var pool: [WorkoutExerciseCandidate]

    switch equipment {
    case .fullGym:
        pool = fullGymExercisePool(for: focus)
    case .homeDumbbells:
        pool = dumbbellExercisePool(for: focus)
    case .bodyweightOnly, .outdoor:
        pool = bodyweightExercisePool(for: focus)
    case .kettlebellOnly:
        pool = kettlebellExercisePool(for: focus)
    }

    if energyLevel == .low {
        pool = pool.filter { !$0.isHighSkill }
    }

    return pool
}

/// Checks whether a generated exercise is allowed for the selected equipment.
public func isExerciseAllowed(_ exerciseName: String, for equipment: EquipmentAccess) -> Bool {
    let normalized = normalizeExerciseName(exerciseName)
    return allowedExerciseNames(for: equipment).contains(normalized)
}

/// Validates that a generated workout obeys equipment, volume, and duration constraints.
public func validateGeneratedWorkout(_ workout: GeneratedWorkout) -> [WorkoutGenerationIssue] {
    var issues: [WorkoutGenerationIssue] = []

    if workout.exercises.isEmpty {
        issues.append(.emptyWorkout)
    }

    for exercise in workout.exercises {
        if !isExerciseAllowed(exercise.name, for: workout.questionnaire.equipment) {
            issues.append(.disallowedEquipment(
                exerciseName: exercise.name,
                equipment: workout.questionnaire.equipment
            ))
        }

        if exercise.sets < 1 || exercise.sets > 6 {
            issues.append(.invalidSets(exerciseName: exercise.name, sets: exercise.sets))
        }
    }

    let estimated = totalEstimatedMinutes(workout.exercises)
    let limit = workout.questionnaire.timeMinutes + 5
    if estimated > limit {
        issues.append(.estimatedTimeTooHigh(estimated: estimated, limit: limit))
    }

    let patternCounts = Dictionary(grouping: workout.exercises, by: movementPattern(for:))
        .mapValues(\.count)
    for (pattern, count) in patternCounts where count > 2 {
        issues.append(.duplicateMovementPattern(pattern: pattern))
    }

    return issues
}

/// Repairs invalid output by replacing it with a conservative approved template.
public func repairGeneratedWorkout(_ workout: GeneratedWorkout) -> GeneratedWorkout {
    guard !validateGeneratedWorkout(workout).isEmpty else { return workout }

    let exercises = safeTemplateExercises(for: workout.questionnaire)
    return GeneratedWorkout(
        id: workout.id,
        createdAt: workout.createdAt,
        isFavorite: workout.isFavorite,
        coachingSummary: workout.coachingSummary,
        exercises: exercises,
        questionnaire: workout.questionnaire
    )
}

public func knownWorkoutExerciseNames() -> Set<String> {
    Set(allWorkoutCandidates().map(\.name))
}

private func allowedExerciseNames(for equipment: EquipmentAccess) -> Set<String> {
    switch equipment {
    case .fullGym:
        return Set(allWorkoutCandidates().map { normalizeExerciseName($0.name) })
    case .homeDumbbells:
        return Set(allDumbbellCandidates().map { normalizeExerciseName($0.name) })
    case .bodyweightOnly, .outdoor:
        return Set(allBodyweightCandidates().map { normalizeExerciseName($0.name) })
    case .kettlebellOnly:
        return Set(allKettlebellCandidates().map { normalizeExerciseName($0.name) })
    }
}

private func safeTemplateExercises(for preferences: QuestionnaireAnswers) -> [GeneratedExercise] {
    let sets = preferences.energyLevel == .low ? 3 : 4
    let reps = preferences.focus == .conditioning ? "10-12" : "6-8"
    let targetCount = max(3, min(5, preferences.timeMinutes / 10))
    var usedPatterns = Set<WorkoutMovementPattern>()

    let selected = workoutExercisePool(
        focus: preferences.focus,
        equipment: preferences.equipment,
        energyLevel: preferences.energyLevel
    )
    .filter { candidate in
        if usedPatterns.contains(candidate.pattern) {
            return false
        }
        usedPatterns.insert(candidate.pattern)
        return true
    }
    .prefix(targetCount)

    return selected.map { candidate in
        GeneratedExercise(
            id: UUID().uuidString,
            name: candidate.name,
            sets: sets,
            reps: reps,
            restMinutes: preferences.focus == .conditioning ? 1.0 : 1.5,
            reasoning: "Approved \(preferences.equipment.rawValue.replacingOccurrences(of: "_", with: " ")) movement",
            bodyweightOnly: candidate.bodyweightOnly
        )
    }
}

private func movementPattern(for exercise: GeneratedExercise) -> WorkoutMovementPattern {
    let normalized = normalizeExerciseName(exercise.name)
    return allWorkoutCandidates().first {
        normalizeExerciseName($0.name) == normalized
    }?.pattern ?? .conditioning
}

private func normalizeExerciseName(_ name: String) -> String {
    name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

private func fullGymExercisePool(for focus: WorkoutFocus) -> [WorkoutExerciseCandidate] {
    switch focus {
    case .upperBody, .push:
        return [
            .init(name: "Flat Barbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Strict Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Incline Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dips (Weighted)", bodyweightOnly: false, pattern: .push),
            .init(name: "Face Pull", bodyweightOnly: false, pattern: .pull),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push)
        ]
    case .pull:
        return [
            .init(name: "Barbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Lat Pulldown", bodyweightOnly: false, pattern: .pull),
            .init(name: "Cable Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Bicep Curl (Barbell)", bodyweightOnly: false, pattern: .pull)
        ]
    case .lowerBody:
        return [
            .init(name: "Back Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Romanian Deadlift (No Straps)", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Leg Press", bodyweightOnly: false, pattern: .squat),
            .init(name: "Hip Thrust", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat)
        ]
    case .fullBody:
        return [
            .init(name: "Back Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Romanian Deadlift (No Straps)", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Flat Barbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Barbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Strict Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Pull-Up", bodyweightOnly: true, pattern: .pull)
        ]
    case .core:
        return bodyweightExercisePool(for: .core) + [
            .init(name: "Cable Crunch", bodyweightOnly: false, pattern: .core),
            .init(name: "Farmer Carry", bodyweightOnly: false, pattern: .carry)
        ]
    case .conditioning:
        return [
            .init(name: "Burpee", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Kettlebell Swing", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Wall Ball", bodyweightOnly: false, pattern: .conditioning),
            .init(name: "Box Jump", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Thruster", bodyweightOnly: false, pattern: .push),
            .init(name: "Air Squat", bodyweightOnly: true, pattern: .squat)
        ]
    }
}

private func dumbbellExercisePool(for focus: WorkoutFocus) -> [WorkoutExerciseCandidate] {
    switch focus {
    case .upperBody, .push:
        return [
            .init(name: "Dumbbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Incline Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Shoulder Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push)
        ]
    case .pull:
        return [
            .init(name: "Dumbbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell Pullover", bodyweightOnly: false, pattern: .pull),
            .init(name: "Dumbbell Curl", bodyweightOnly: false, pattern: .pull),
            .init(name: "Reverse Fly", bodyweightOnly: false, pattern: .pull)
        ]
    case .lowerBody:
        return [
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Romanian Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Hip Thrust", bodyweightOnly: false, pattern: .hinge)
        ]
    case .fullBody:
        return [
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Dumbbell Romanian Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Bench Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Farmer Carry", bodyweightOnly: false, pattern: .carry)
        ]
    case .core:
        return [
            .init(name: "Dumbbell Dead Bug", bodyweightOnly: false, pattern: .core),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core)
        ]
    case .conditioning:
        return [
            .init(name: "Dumbbell Thruster", bodyweightOnly: false, pattern: .push),
            .init(name: "Dumbbell Clean", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Dumbbell Step-Up", bodyweightOnly: false, pattern: .squat),
            .init(name: "Farmer Carry", bodyweightOnly: false, pattern: .carry)
        ]
    }
}

private func bodyweightExercisePool(for focus: WorkoutFocus) -> [WorkoutExerciseCandidate] {
    switch focus {
    case .upperBody, .push:
        return [
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Pike Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Dips", bodyweightOnly: true, pattern: .push)
        ]
    case .pull:
        return [
            .init(name: "Pull-Up", bodyweightOnly: true, pattern: .pull),
            .init(name: "Inverted Row", bodyweightOnly: true, pattern: .pull),
            .init(name: "Prone W Raise", bodyweightOnly: true, pattern: .pull)
        ]
    case .lowerBody:
        return [
            .init(name: "Air Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Reverse Lunge", bodyweightOnly: true, pattern: .squat),
            .init(name: "Glute Bridge", bodyweightOnly: true, pattern: .hinge)
        ]
    case .fullBody:
        return [
            .init(name: "Air Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Glute Bridge", bodyweightOnly: true, pattern: .hinge),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Prone W Raise", bodyweightOnly: true, pattern: .pull),
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core)
        ]
    case .core:
        return [
            .init(name: "Plank Hold", bodyweightOnly: true, pattern: .core),
            .init(name: "V-up", bodyweightOnly: true, pattern: .core),
            .init(name: "Dead Bug", bodyweightOnly: true, pattern: .core),
            .init(name: "Sit-Up", bodyweightOnly: true, pattern: .core),
            .init(name: "L-Sit Hold", bodyweightOnly: true, pattern: .core)
        ]
    case .conditioning:
        return [
            .init(name: "Burpee", bodyweightOnly: true, pattern: .conditioning),
            .init(name: "Air Squat", bodyweightOnly: true, pattern: .squat),
            .init(name: "Push-Up", bodyweightOnly: true, pattern: .push),
            .init(name: "Mountain Climber", bodyweightOnly: true, pattern: .core)
        ]
    }
}

private func kettlebellExercisePool(for focus: WorkoutFocus) -> [WorkoutExerciseCandidate] {
    switch focus {
    case .upperBody, .push:
        return [
            .init(name: "Kettlebell Strict Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Floor Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Push Press", bodyweightOnly: false, pattern: .push, isHighSkill: true),
            .init(name: "Kettlebell Rack Hold", bodyweightOnly: false, pattern: .core)
        ]
    case .pull:
        return [
            .init(name: "Kettlebell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Kettlebell High Pull", bodyweightOnly: false, pattern: .pull, isHighSkill: true),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry)
        ]
    case .lowerBody:
        return [
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Kettlebell Reverse Lunge", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Swing", bodyweightOnly: false, pattern: .hinge)
        ]
    case .fullBody:
        return [
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Deadlift", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Kettlebell Strict Press", bodyweightOnly: false, pattern: .push),
            .init(name: "Kettlebell Row", bodyweightOnly: false, pattern: .pull),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Turkish Get-Up", bodyweightOnly: false, pattern: .core, isHighSkill: true)
        ]
    case .core:
        return [
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry),
            .init(name: "Kettlebell Rack Hold", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Dead Bug", bodyweightOnly: false, pattern: .core),
            .init(name: "Kettlebell Windmill", bodyweightOnly: false, pattern: .core, isHighSkill: true),
            .init(name: "Turkish Get-Up", bodyweightOnly: false, pattern: .core, isHighSkill: true)
        ]
    case .conditioning:
        return [
            .init(name: "Kettlebell Swing", bodyweightOnly: false, pattern: .hinge),
            .init(name: "Goblet Squat", bodyweightOnly: false, pattern: .squat),
            .init(name: "Kettlebell Clean", bodyweightOnly: false, pattern: .hinge, isHighSkill: true),
            .init(name: "Kettlebell Snatch", bodyweightOnly: false, pattern: .conditioning, isHighSkill: true),
            .init(name: "Kettlebell High Pull", bodyweightOnly: false, pattern: .pull, isHighSkill: true),
            .init(name: "Suitcase Carry", bodyweightOnly: false, pattern: .carry)
        ]
    }
}

private func allWorkoutCandidates() -> [WorkoutExerciseCandidate] {
    allBodyweightCandidates() + allDumbbellCandidates() + allKettlebellCandidates() +
        WorkoutFocus.allRuleCases.flatMap { fullGymExercisePool(for: $0) }
}

private func allBodyweightCandidates() -> [WorkoutExerciseCandidate] {
    WorkoutFocus.allRuleCases.flatMap { bodyweightExercisePool(for: $0) }
}

private func allDumbbellCandidates() -> [WorkoutExerciseCandidate] {
    WorkoutFocus.allRuleCases.flatMap { dumbbellExercisePool(for: $0) } + allBodyweightCandidates()
}

private func allKettlebellCandidates() -> [WorkoutExerciseCandidate] {
    WorkoutFocus.allRuleCases.flatMap { kettlebellExercisePool(for: $0) }
}

private extension WorkoutFocus {
    static let allRuleCases: [WorkoutFocus] = [
        .upperBody, .lowerBody, .fullBody, .push, .pull, .core, .conditioning
    ]
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

/// Get cycle phase multiplier for AI workout generation.
/// When an exercise region is provided, uses region-specific multipliers
/// (e.g., lower body gets bigger menstrual reduction).
public func aiCyclePhaseMultiplier(
    _ phase: CyclePhase?,
    region: ExerciseRegion? = nil
) -> Double {
    guard let phase else { return 1.0 }
    return resolvePhaseMultipliers(phase: phase, region: region).load
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

        // Store the effective percentage (including multipliers) for display
        let effectivePct = pct * energyMult * cycleMult

        var modified = ex
        modified.weightKg = rounded
        modified.percentageOfMax = effectivePct
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

// MARK: - Volume-Targeted Workout Generation

/// Suggested set breakdown for reaching a volume target.
public struct VolumeTargetBreakdown: Sendable {
    /// Suggested sets.
    public let sets: Int
    /// Suggested reps per set.
    public let reps: Int
    /// Weight per rep in the user's unit.
    public let weight: Double
    /// Total volume from this breakdown.
    public let totalVolume: Double
    /// How close this is to the target (within ±5% is ideal).
    public let variancePercent: Double
}

/// Generates a suggested sets/reps/weight breakdown to reach a target volume for an exercise.
///
/// Uses the user's working weight (from maxes at 70% 1RM) and distributes reps
/// across sets to approximate the target volume.
///
/// - Parameters:
///   - targetVolumeLbs: The volume goal (reps × weight).
///   - exerciseName: The exercise to target.
///   - maxes: The user's 1RM records.
/// - Returns: A breakdown suggestion, or nil if no max is found.
public func generateVolumeTargetedBreakdown(
    targetVolumeLbs: Double,
    exerciseName: String,
    maxes: [ExerciseMax]
) -> VolumeTargetBreakdown? {
    guard let matched = findMatchingMax(exerciseName, maxes: maxes) else {
        return nil
    }

    // Use 70% of 1RM as the working weight (moderate intensity for volume work)
    let workingWeight = (matched.weightKg * 0.70 * 2.20462).rounded() // Convert kg to lbs
    let roundedWeight = Double(Int(workingWeight / 5.0 + 0.5)) * 5.0 // Round to nearest 5 lbs

    guard roundedWeight > 0 else { return nil }

    // Calculate total reps needed
    let totalRepsNeeded = targetVolumeLbs / roundedWeight

    // Distribute across sets (target 8-12 reps per set)
    let idealReps = 8
    let setsNeeded = max(1, min(6, Int((totalRepsNeeded / Double(idealReps)).rounded(.up))))
    let repsPerSet = max(1, min(15, Int((totalRepsNeeded / Double(setsNeeded)).rounded())))

    let totalVolume = Double(setsNeeded * repsPerSet) * roundedWeight
    let variance = targetVolumeLbs > 0
        ? (totalVolume - targetVolumeLbs) / targetVolumeLbs * 100
        : 0

    return VolumeTargetBreakdown(
        sets: setsNeeded,
        reps: repsPerSet,
        weight: roundedWeight,
        totalVolume: totalVolume,
        variancePercent: variance
    )
}
