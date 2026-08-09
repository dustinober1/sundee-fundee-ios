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

    public static let allCasesForTesting: [WorkoutFocus] = [
        .upperBody, .lowerBody, .fullBody, .push, .pull, .core, .conditioning
    ]
}

/// Energy level for workout generation
public enum EnergyLevel: String, Codable, Sendable, Equatable {
    case low
    case medium
    case high
}

/// Equipment access level
public enum EquipmentAccess: String, Codable, Sendable, Equatable, Hashable {
    case fullGym = "full_gym"
    case homeDumbbells = "home_dumbbells"
    case resistanceBands = "resistance_bands"
    case bodyweightOnly = "bodyweight_only"
    case kettlebellOnly = "kettlebell_only"
    case outdoor

    public var displayName: String {
        switch self {
        case .fullGym: return "Full Gym"
        case .homeDumbbells: return "Dumbbells"
        case .resistanceBands: return "Bands Only"
        case .bodyweightOnly: return "Bodyweight Only"
        case .kettlebellOnly: return "Kettlebell Only"
        case .outdoor: return "Outdoor"
        }
    }

    public var shortDescription: String {
        switch self {
        case .fullGym: return "Barbells, machines, dumbbells, bands"
        case .homeDumbbells: return "Dumbbells and bench"
        case .resistanceBands: return "Resistance-band training"
        case .bodyweightOnly: return "No equipment"
        case .kettlebellOnly: return "Single or pair of bells"
        case .outdoor: return "Outdoor and bodyweight work"
        }
    }

    public static let userSelectableDefaults: [EquipmentAccess] = [
        .fullGym, .homeDumbbells, .resistanceBands, .kettlebellOnly, .bodyweightOnly
    ]
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
    case .resistanceBands:
        pool = resistanceBandExercisePool(for: focus)
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

    let patternLimit = maxExercisesPerPattern(
        focus: workout.questionnaire.focus,
        exerciseCount: workout.exercises.count
    )
    let patternCounts = Dictionary(grouping: workout.exercises, by: movementPattern(for:))
        .mapValues(\.count)
    for (pattern, count) in patternCounts where count > patternLimit {
        issues.append(.duplicateMovementPattern(pattern: pattern))
    }

    return issues
}

/// How many exercises of a single movement pattern a session may contain.
///
/// A flat cap of two was fine when every generated workout was three or four
/// exercises long, but it made longer sessions impossible to fill and it
/// punished focused days for doing exactly what the user asked: a push day is
/// supposed to be mostly pushing. The allowance therefore scales with session
/// length, and focused sessions let their namesake pattern run free.
func maxExercisesPerPattern(focus: WorkoutFocus, exerciseCount: Int) -> Int {
    switch focus {
    case .push, .pull, .core:
        return max(2, exerciseCount)
    case .upperBody, .lowerBody:
        return max(2, (exerciseCount + 1) / 2)
    case .fullBody, .conditioning:
        return max(2, (exerciseCount + 2) / 3)
    }
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
    case .resistanceBands:
        return Set(allResistanceBandCandidates().map { normalizeExerciseName($0.name) })
    case .bodyweightOnly, .outdoor:
        return Set(allBodyweightCandidates().map { normalizeExerciseName($0.name) })
    case .kettlebellOnly:
        return Set(allKettlebellCandidates().map { normalizeExerciseName($0.name) })
    }
}

private func safeTemplateExercises(for preferences: QuestionnaireAnswers) -> [GeneratedExercise] {
    let reps = preferences.focus == .conditioning ? "10-12" : "6-8"
    let rest = preferences.focus == .conditioning ? 1.0 : 1.5
    var usedPatterns = Set<WorkoutMovementPattern>()

    let shortlist = workoutExercisePool(
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

    // The repair path is deliberately conservative — one movement per pattern
    // and a low set ceiling — but it still respects the window it was asked for.
    let volume = WorkoutVolumePlanner.plan(
        timeMinutes: preferences.timeMinutes,
        availableExercises: shortlist.count,
        restMinutes: rest,
        model: .generatedWorkout,
        maxSets: 3,
        minExercises: 2,
        maxExercises: 5
    )

    return zip(shortlist, volume.setsPerExercise).map { candidate, sets in
        GeneratedExercise(
            id: UUID().uuidString,
            name: candidate.name,
            sets: sets,
            reps: reps,
            restMinutes: rest,
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

/// Fuzzy match an exercise name to a user's max.
///
/// Both sides resolve through `canonicalExerciseID` first, so a max logged under
/// a retired ID still matches the canonical name a generated workout now uses.
public func findMatchingMax(_ exerciseName: String, maxes: [ExerciseMax]) -> ExerciseMax? {
    let lower = canonicalExerciseID(exerciseName).lowercased()
    if let exact = maxes.first(where: { canonicalExerciseID($0.name).lowercased() == lower }) {
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
