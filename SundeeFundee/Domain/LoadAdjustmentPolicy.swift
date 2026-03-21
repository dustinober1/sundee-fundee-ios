import Foundation

/// Phase-specific multipliers for exercise load, sets, and reps.
/// Applied to replacement exercises during injury adaptation.
enum LoadAdjustmentPolicy {

    struct Multipliers {
        let load: Double
        let sets: Double
        let reps: Double
    }

    /// Returns multipliers for a given recovery phase.
    static func multipliers(for phase: RecoveryPhase) -> Multipliers {
        switch phase {
        case .acute:
            return Multipliers(load: 0.0, sets: 0.0, reps: 0.0)
        case .rehab:
            return Multipliers(load: 0.30, sets: 0.50, reps: 0.70)
        case .lightLoad:
            return Multipliers(load: 0.50, sets: 0.75, reps: 0.85)
        case .returnToPlay:
            return Multipliers(load: 0.80, sets: 0.90, reps: 1.0)
        case .resolved:
            return Multipliers(load: 1.0, sets: 1.0, reps: 1.0)
        }
    }

    /// Applies multipliers to an exercise value (sets or reps).
    static func adjustValue(_ value: ExerciseValue, multiplier: Double) -> ExerciseValue {
        switch value {
        case .fixed(let n):
            return .fixed(max(1, Int(round(Double(n) * multiplier))))
        case .range(let lo, let hi):
            return .range(max(1, Int(round(Double(lo) * multiplier))), max(1, Int(round(Double(hi) * multiplier))))
        case .amrap, .text:
            return value
        }
    }

    /// Applies load multiplier to percent1RM.
    static func adjustLoad(_ percent1RM: Double?, multiplier: Double) -> Double? {
        guard let pct = percent1RM else { return nil }
        return pct * multiplier
    }

    /// Applies full multiplier set to a ProgramExercise.
    static func applyMultipliers(_ exercise: ProgramExercise, phase: RecoveryPhase) -> ProgramExercise {
        let m = multipliers(for: phase)
        guard m.load < 1.0 || m.sets < 1.0 || m.reps < 1.0 else { return exercise }
        return ProgramExercise(
            exercise: exercise.exercise,
            variant: exercise.variant,
            sets: adjustValue(exercise.sets, multiplier: m.sets),
            reps: adjustValue(exercise.reps, multiplier: m.reps),
            percent1RM: adjustLoad(exercise.percent1RM, multiplier: m.load),
            restMinutes: exercise.restMinutes,
            notes: exercise.notes,
            bodyweightOnly: exercise.bodyweightOnly
        )
    }
}
