import Foundation

// MARK: - RecoveryScoreCalculator

/// Pure domain calculator for recovery scores.
///
/// Takes all available biometric and training inputs, scores each dimension
/// 0-100, and produces a weighted total with graceful degradation when
/// inputs are missing. Returns nil when no inputs are present.
///
/// Weight distribution when all inputs present:
/// - HRV: 30%
/// - Sleep: 25%
/// - Training Load: 25%
/// - Cycle Phase: 15%
/// - Pain: 5%
///
/// When inputs are missing, weights are redistributed proportionally
/// among present inputs.
public enum RecoveryScoreCalculator {

    // MARK: - Input Weights

    private enum InputWeight {
        static let hrv: Double = 0.30
        static let sleep: Double = 0.25
        static let trainingLoad: Double = 0.25
        static let cyclePhase: Double = 0.15
        static let pain: Double = 0.05
    }

    // MARK: - Calculate

    /// Calculate recovery score from available inputs.
    ///
    /// - Parameter inputs: Recovery data (all fields optional).
    /// - Returns: Score with sub-scores and recommendation, or nil if all inputs are nil.
    public static func calculate(inputs: RecoveryScoreInputs) -> RecoveryScore? {
        var weightedSum: Double = 0
        var totalWeight: Double = 0
        var subScores: [RecoveryInput: Int] = [:]
        var explanations: [RecoveryInput: String] = [:]

        // HRV
        if let hrv = inputs.hrvMilliseconds {
            let normalized = HRVBaselineNormalizer.normalize(hrvMs: hrv, phase: inputs.cyclePhase)
            let hrvScore = HRVBaselineNormalizer.score(normalizedHrvMs: normalized)
            subScores[.hrv] = hrvScore
            weightedSum += Double(hrvScore) * InputWeight.hrv
            totalWeight += InputWeight.hrv
            let phaseNote = inputs.cyclePhase != nil
                ? " (phase-normalized)"
                : ""
            explanations[.hrv] = "HRV \(Int(hrv))ms → \(hrvScore)/100\(phaseNote)"
        }

        // Sleep
        if let sleep = inputs.sleepDurationHours {
            let sleepScore = scoreSleep(sleep)
            subScores[.sleep] = sleepScore
            weightedSum += Double(sleepScore) * InputWeight.sleep
            totalWeight += InputWeight.sleep
            let formatted = String(format: "%.1f", sleep)
            explanations[.sleep] = sleep >= 7.0
                ? "\(formatted)h — within 7h target"
                : "\(formatted)h — below 7h target"
        }

        // Training Load
        if let summaries = inputs.weeklySummaries {
            let loadResult = TrainingLoadScorer.score(summaries: summaries)
            subScores[.trainingLoad] = loadResult.score
            weightedSum += Double(loadResult.score) * InputWeight.trainingLoad
            totalWeight += InputWeight.trainingLoad
            explanations[.trainingLoad] = loadResult.explanation
        }

        // Cycle Phase
        if let phase = inputs.cyclePhase {
            let phaseResult = CyclePhaseScorer.score(phase: phase)
            subScores[.cyclePhase] = phaseResult.score
            weightedSum += Double(phaseResult.score) * InputWeight.cyclePhase
            totalWeight += InputWeight.cyclePhase
            explanations[.cyclePhase] = phaseResult.explanation
        }

        // Pain
        if let pain = inputs.painIntensity {
            let painResult = PainScorer.score(intensity: pain)
            subScores[.pain] = painResult.score
            weightedSum += Double(painResult.score) * InputWeight.pain
            totalWeight += InputWeight.pain
            explanations[.pain] = painResult.explanation
        }

        guard totalWeight > 0 else { return nil }

        let total = Int((weightedSum / totalWeight).rounded())
        let clamped = min(100, max(0, total))
        let recommendation: TrainingRecommendation = clamped >= 70
            ? .pushDay
            : clamped >= 40
                ? .moderate
                : .restDay

        return RecoveryScore(
            total: clamped,
            recommendation: recommendation,
            subScores: subScores,
            presentInputCount: subScores.count,
            totalInputCount: 5,
            explanations: explanations
        )
    }

    // MARK: - Sleep Scoring

    /// Scores sleep duration on a 0-100 scale.
    ///
    /// - Parameter hours: Total sleep duration in hours.
    /// - Returns: Score from 0-100.
    private static func scoreSleep(_ hours: Double) -> Int {
        switch hours {
        case 8.0...: return 100
        case 7.0..<8.0: return 85
        case 6.0..<7.0: return 60
        case 5.0..<6.0: return 35
        default: return 10
        }
    }
}
