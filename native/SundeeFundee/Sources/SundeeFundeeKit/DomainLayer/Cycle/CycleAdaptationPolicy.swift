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
}

// MARK: - Constants

/// Phase multipliers per cycle phase
public let phaseMultipliers: [CyclePhase: PhaseMultipliers] = [
    .menstrual:  PhaseMultipliers(load: 0.90, sets: 0.90, reps: 0.90),
    .follicular: PhaseMultipliers(load: 1.00, sets: 1.00, reps: 1.00),
    .ovulation:  PhaseMultipliers(load: 1.12, sets: 1.05, reps: 0.95),
    .luteal:     PhaseMultipliers(load: 0.97, sets: 0.95, reps: 0.92),
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

/// Apply cycle phase adjustment to an exercise's sets, reps, and load
public func applyPhaseAdjustment(
    sets: ExerciseValue,
    reps: ExerciseValue,
    percent1RM: Double?,
    phase: CyclePhase,
    readinessTier: AdaptationReadinessTier,
    confidence: AdaptationConfidence
) -> (sets: ExerciseValue, reps: ExerciseValue, percent1RM: Double?) {
    let settings = phaseMultipliers[phase] ?? PhaseMultipliers(load: 1.0, sets: 1.0, reps: 1.0)
    let rs = readinessScales[readinessTier] ?? 1.0
    let cs = confidenceScales[confidence] ?? 1.0

    func blendMultiplier(_ target: Double) -> Double {
        clamp(1.0 + (target - 1.0) * rs * cs, min: 0.75, max: 1.25)
    }

    let adjustedSets = adjustExerciseValueByMultiplier(sets, multiplier: blendMultiplier(settings.sets))
    let adjustedReps = adjustExerciseValueByMultiplier(reps, multiplier: blendMultiplier(settings.reps))
    let adjustedLoad = percent1RM.map { clamp($0 * blendMultiplier(settings.load), min: 0.4, max: 1.1) }

    return (sets: adjustedSets, reps: adjustedReps, percent1RM: adjustedLoad)
}
