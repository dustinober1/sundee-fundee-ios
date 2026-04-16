import Foundation

// MARK: - PainScorer

/// Scores pain intensity from DailyPainLog on a 0-100 recovery scale.
///
/// Uses a linear mapping from the 1-10 pain intensity scale (per InjuryModels.swift):
/// - Intensity 1 (minimal pain) → score 100
/// - Intensity 10 (severe pain) → score 1
public enum PainScorer {

    // MARK: - Scoring

    /// Scores a pain intensity value as a recovery input.
    ///
    /// - Parameter intensity: Pain intensity on 1-10 scale. Clamped to valid range.
    /// - Returns: Tuple of (score 0-100, explanation string).
    public static func score(intensity: Int) -> (score: Int, explanation: String) {
        let clamped = max(1, min(10, intensity))
        let score = max(0, 100 - ((clamped - 1) * 11))
        let explanation = explanationForIntensity(clamped)

        return (score, explanation)
    }

    // MARK: - Explanation

    /// Returns a human-readable explanation for a pain intensity level.
    private static func explanationForIntensity(_ intensity: Int) -> String {
        switch intensity {
        case 1...2:
            return "Minimal pain"
        case 3...5:
            return "Moderate soreness"
        default:
            return "High pain — prioritize recovery"
        }
    }
}
