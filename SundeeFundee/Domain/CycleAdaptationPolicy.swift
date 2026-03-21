import Foundation

// MARK: - Adaptation enums

enum AdaptationReadinessTier { case low, neutral, high }
enum AdaptationConfidence    { case low, medium, high }

// MARK: - CycleAdaptationPolicy

struct CycleAdaptationPolicy {

    private static let baselinePhaseSettings: [CyclePhase: (load: Double, sets: Double, reps: Double)] = [
        .menstrual:  (0.90, 0.90, 0.90),
        .follicular: (1.00, 1.00, 1.00),
        .ovulation:  (1.12, 1.05, 0.95),
        .luteal:     (0.97, 0.95, 0.92),
    ]

    private static let readinessScales: [AdaptationReadinessTier: Double] = [
        .low: 0.6, .neutral: 1.0, .high: 1.2,
    ]

    private static let confidenceScales: [AdaptationConfidence: Double] = [
        .low: 0.55, .medium: 0.8, .high: 1.0,
    ]

    func resolveReadinessTier(readinessScore: Double?) -> AdaptationReadinessTier {
        guard let score = readinessScore else { return .neutral }
        if score <= 3 { return .low   }
        if score >= 8 { return .high  }
        return .neutral
    }

    func resolveConfidenceScale(
        confidence: AdaptationConfidence,
        lowConfidenceScale: Double = 0.7
    ) -> Double {
        let base = Self.confidenceScales[confidence] ?? 1.0
        guard confidence == .low else { return base }
        return (base * lowConfidenceScale).clamped(to: 0.1...1.0)
    }

    func resolvePhase(
        currentPhase: CyclePhase?,
        lastKnownPhase: CyclePhase?,
        fallbackPhase: String = "follicular"
    ) -> CyclePhase {
        if let p = currentPhase  { return p }
        if let p = lastKnownPhase { return p }
        return CyclePhase(rawValue: fallbackPhase) ?? .follicular
    }

    func resolveConfidence(
        currentPhase: CyclePhase?,
        lastKnownPhase: CyclePhase?,
        periodLogCount: Int,
        lastPeriodStart: Date?,
        referenceDate: Date = .now
    ) -> AdaptationConfidence {
        guard periodLogCount > 0 else { return .low }
        if let last = lastPeriodStart, referenceDate.timeIntervalSince(last) > 45 * 86400 {
            return .low
        }
        if currentPhase != nil && periodLogCount >= 3 { return .high   }
        if currentPhase != nil                        { return .medium  }
        return .low
    }

    func applyPhaseAdjustment(
        exercise: ProgramExercise,
        phase: CyclePhase,
        readinessTier: AdaptationReadinessTier,
        confidence: AdaptationConfidence,
        profile: ProgramCycleAdjustmentProfile?
    ) -> ProgramExercise {
        let settings = resolvePhaseSettings(phase: phase, profile: profile)
        let rs = Self.readinessScales[readinessTier] ?? 1.0
        let cs = resolveConfidenceScale(
            confidence: confidence,
            lowConfidenceScale: profile?.lowConfidenceScale ?? 0.7
        )

        func blendMultiplier(_ target: Double) -> Double {
            (1.0 + (target - 1.0) * rs * cs).clamped(to: 0.75...1.25)
        }

        return ProgramExercise(
            exercise:      exercise.exercise,
            variant:       exercise.variant,
            sets:          scaleValue(exercise.sets, multiplier: blendMultiplier(settings.sets)),
            reps:          scaleValue(exercise.reps, multiplier: blendMultiplier(settings.reps)),
            percent1RM:    exercise.percent1RM.map { ($0 * blendMultiplier(settings.load)).clamped(to: 0.4...1.1) },
            restMinutes:   exercise.restMinutes,
            notes:         exercise.notes,
            bodyweightOnly: exercise.bodyweightOnly
        )
    }

    // MARK: - Helpers

    private func resolvePhaseSettings(
        phase: CyclePhase,
        profile: ProgramCycleAdjustmentProfile?
    ) -> (load: Double, sets: Double, reps: Double) {
        if let ps = profile?.phaseSettings[phase.rawValue] {
            return (ps.loadMultiplier, ps.setsMultiplier, ps.repsMultiplier)
        }
        return Self.baselinePhaseSettings[phase] ?? (1.0, 1.0, 1.0)
    }

    private func scaleValue(_ value: ExerciseValue, multiplier: Double) -> ExerciseValue {
        switch value {
        case .fixed(let n):
            return .fixed(max(1, Int((Double(n) * multiplier).rounded())))
        case .range(let lo, let hi):
            let newLo = max(1, Int((Double(lo) * multiplier).rounded()))
            let newHi = max(newLo, Int((Double(hi) * multiplier).rounded()))
            return .range(newLo, newHi)
        case .amrap, .text:
            return value
        }
    }
}

// MARK: - Swift standard library helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
