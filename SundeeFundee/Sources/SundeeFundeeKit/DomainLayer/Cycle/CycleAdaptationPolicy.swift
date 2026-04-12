import Foundation

// MARK: - Types

/// Adaptation readiness tier
public enum AdaptationReadinessTier: String, Sendable {
    case low
    case neutral
    case high
}

/// Adaptation confidence level
public enum AdaptationConfidence: String, Sendable {
    case low
    case medium
    case high
}

/// Body region classification for region-specific cycle multipliers.
/// Upper and lower body respond differently to hormonal shifts.
public enum ExerciseRegion: String, Sendable, CaseIterable {
    case upper
    case lower
    case fullBody
    case core
    case conditioning
}

/// Phase-specific multipliers for cycle adaptation
public struct PhaseMultipliers: Sendable {
    public let load: Double
    public let sets: Double
    public let reps: Double

    public init(load: Double, sets: Double, reps: Double) {
        self.load = load
        self.sets = sets
        self.reps = reps
    }

    /// Linear interpolation between two multiplier sets.
    public func lerp(to other: PhaseMultipliers, t: Double) -> PhaseMultipliers {
        PhaseMultipliers(
            load: load + (other.load - load) * t,
            sets: sets + (other.sets - sets) * t,
            reps: reps + (other.reps - reps) * t
        )
    }
}

// MARK: - Constants

/// Default phase multipliers per cycle phase (used as fallback)
public let phaseMultipliers: [CyclePhase: PhaseMultipliers] = [
    .menstrual:  PhaseMultipliers(load: 0.90, sets: 0.90, reps: 0.90),
    .follicular: PhaseMultipliers(load: 1.00, sets: 1.00, reps: 1.00),
    .ovulation:  PhaseMultipliers(load: 1.12, sets: 1.05, reps: 0.95),
    .luteal:     PhaseMultipliers(load: 0.97, sets: 0.95, reps: 0.92),
]

/// Region-specific overrides — upper and lower body respond differently to hormonal shifts.
/// Lower body gets bigger menstrual reduction and bigger ovulation boost.
public let regionPhaseMultipliers: [ExerciseRegion: [CyclePhase: PhaseMultipliers]] = [
    .lower: [
        .menstrual:  PhaseMultipliers(load: 0.85, sets: 0.85, reps: 0.88),
        .follicular: PhaseMultipliers(load: 1.00, sets: 1.00, reps: 1.00),
        .ovulation:  PhaseMultipliers(load: 1.15, sets: 1.08, reps: 0.93),
        .luteal:     PhaseMultipliers(load: 0.95, sets: 0.93, reps: 0.90),
    ],
    .upper: [
        .menstrual:  PhaseMultipliers(load: 0.92, sets: 0.92, reps: 0.92),
        .follicular: PhaseMultipliers(load: 1.00, sets: 1.00, reps: 1.00),
        .ovulation:  PhaseMultipliers(load: 1.10, sets: 1.03, reps: 0.96),
        .luteal:     PhaseMultipliers(load: 0.98, sets: 0.96, reps: 0.93),
    ],
]

private let readinessScales: [AdaptationReadinessTier: Double] = [
    .low:     0.6,
    .neutral: 1.0,
    .high:    1.2,
]

private let confidenceScales: [AdaptationConfidence: Double] = [
    .low:    0.55,
    .medium: 0.8,
    .high:   1.0,
]

// MARK: - Helpers

private func clamp(_ value: Double, min: Double, max: Double) -> Double {
    Swift.min(Swift.max(value, min), max)
}

// MARK: - Exercise Region Classification

/// Classify an exercise name into a body region for region-specific multipliers.
public func classifyExerciseRegion(_ exerciseName: String) -> ExerciseRegion {
    let lower = exerciseName.lowercased()

    let lowerKeywords = ["squat", "deadlift", "leg", "hip thrust", "lunge",
                         "calf", "glute", "hamstring", "good morning"]
    if lowerKeywords.contains(where: { lower.contains($0) }) { return .lower }

    let upperKeywords = ["bench", "press", "row", "pull-up", "chin-up", "curl",
                         "dip", "lat pull", "face pull", "fly", "raise",
                         "overhead", "shoulder", "tricep"]
    if upperKeywords.contains(where: { lower.contains($0) }) { return .upper }

    let coreKeywords = ["plank", "sit-up", "crunch", "ab ", "core", "hollow",
                        "l-sit", "v-up", "toes-to-bar"]
    if coreKeywords.contains(where: { lower.contains($0) }) { return .core }

    let condKeywords = ["run", "row ", "bike", "swim", "burpee", "wall ball",
                        "box jump", "double under", "skierg"]
    if condKeywords.contains(where: { lower.contains($0) }) { return .conditioning }

    // Clean, snatch, jerk, carry, farmer's walk → full body
    return .fullBody
}

/// Look up the phase multipliers for a given phase and optional exercise region.
/// Falls back to the default (non-region) multipliers when no region override exists.
public func resolvePhaseMultipliers(
    phase: CyclePhase,
    region: ExerciseRegion? = nil
) -> PhaseMultipliers {
    if let region, let regionMap = regionPhaseMultipliers[region],
       let multipliers = regionMap[phase] {
        return multipliers
    }
    return phaseMultipliers[phase] ?? PhaseMultipliers(load: 1.0, sets: 1.0, reps: 1.0)
}

// MARK: - Phase Transition Blending

/// Returns blended multipliers when near a phase boundary (within 1 day).
/// Prevents jarring jumps between phases — e.g., follicular→ovulation blends
/// at the transition day rather than switching abruptly.
public func blendedMultiplier(
    phase: CyclePhase,
    cycleDay: Int,
    settings: CycleSettings,
    region: ExerciseRegion? = nil
) -> PhaseMultipliers {
    let boundaries = getPhaseBoundaries(settings: settings)
    let currentMultipliers = resolvePhaseMultipliers(phase: phase, region: region)

    guard let boundary = boundaries[phase] else { return currentMultipliers }

    // Check if we're within 1 day of the END of current phase (transition to next)
    if cycleDay >= boundary.end {
        let nextPhase = nextCyclePhase(after: phase)
        let nextMultipliers = resolvePhaseMultipliers(phase: nextPhase, region: region)
        // Blend: 50% current + 50% next at the exact boundary day
        return currentMultipliers.lerp(to: nextMultipliers, t: 0.5)
    }

    // Check if we're at the START of current phase (transition from previous)
    if cycleDay <= boundary.start {
        let prevPhase = previousCyclePhase(before: phase)
        let prevMultipliers = resolvePhaseMultipliers(phase: prevPhase, region: region)
        return prevMultipliers.lerp(to: currentMultipliers, t: 0.5)
    }

    return currentMultipliers
}

/// Next phase in the cycle sequence
private func nextCyclePhase(after phase: CyclePhase) -> CyclePhase {
    switch phase {
    case .menstrual:  return .follicular
    case .follicular: return .ovulation
    case .ovulation:  return .luteal
    case .luteal:     return .menstrual
    }
}

/// Previous phase in the cycle sequence
private func previousCyclePhase(before phase: CyclePhase) -> CyclePhase {
    switch phase {
    case .menstrual:  return .luteal
    case .follicular: return .menstrual
    case .ovulation:  return .follicular
    case .luteal:     return .ovulation
    }
}

// MARK: - Public API

/// Resolve readiness tier from a 0-10 score
public func resolveReadinessTier(score: Double?) -> AdaptationReadinessTier {
    guard let score else { return .neutral }
    if score <= 3 { return .low }
    if score >= 8 { return .high }
    return .neutral
}

/// Resolve confidence level from cycle data availability
public func resolveConfidence(
    currentPhase: CyclePhase?,
    lastKnownPhase: CyclePhase?,
    periodLogCount: Int,
    lastPeriodStart: Date?,
    referenceDate: Date = Date()
) -> AdaptationConfidence {
    if periodLogCount == 0 { return .low }

    if let lastPeriodStart {
        let daysSince = referenceDate.timeIntervalSince(lastPeriodStart) / (60 * 60 * 24)
        if daysSince > 60 { return .medium }
    }

    if currentPhase != nil && periodLogCount >= 3 { return .high }
    if currentPhase != nil { return .medium }
    return .low
}

/// Apply cycle phase adjustment to an exercise's sets, reps, and load.
/// Optionally accepts an exercise region for region-specific multipliers.
public func applyPhaseAdjustment(
    sets: ExerciseValue,
    reps: ExerciseValue,
    percent1RM: Double?,
    phase: CyclePhase,
    readinessTier: AdaptationReadinessTier,
    confidence: AdaptationConfidence,
    exerciseRegion: ExerciseRegion? = nil
) -> (sets: ExerciseValue, reps: ExerciseValue, percent1RM: Double?) {
    let settings = resolvePhaseMultipliers(phase: phase, region: exerciseRegion)
    let rs = readinessScales[readinessTier] ?? 1.0
    let cs = confidenceScales[confidence] ?? 1.0

    func blendMult(_ target: Double) -> Double {
        clamp(1.0 + (target - 1.0) * rs * cs, min: 0.75, max: 1.25)
    }

    let adjustedSets = adjustExerciseValueByMultiplier(sets, multiplier: blendMult(settings.sets))
    let adjustedReps = adjustExerciseValueByMultiplier(reps, multiplier: blendMult(settings.reps))
    let adjustedLoad = percent1RM.map { clamp($0 * blendMult(settings.load), min: 0.4, max: 1.1) }

    return (sets: adjustedSets, reps: adjustedReps, percent1RM: adjustedLoad)
}
