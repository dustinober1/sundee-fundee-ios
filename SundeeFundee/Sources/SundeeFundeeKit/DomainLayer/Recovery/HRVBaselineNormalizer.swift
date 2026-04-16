import Foundation

// MARK: - HRVBaselineNormalizer

/// Normalizes HRV readings against per-cycle-phase baselines.
///
/// Progesterone suppresses HRV 10-20% during the luteal phase.
/// Without phase-relative normalization, luteal-phase readings would
/// consistently produce artificially low recovery scores.
/// The normalizer divides raw HRV by a phase-specific multiplier,
/// producing a phase-adjusted value that can be scored uniformly.
public enum HRVBaselineNormalizer {

    // MARK: - Phase Multipliers

    /// Returns the HRV normalization multiplier for a given cycle phase.
    ///
    /// - Parameter phase: Current cycle phase (nil when no cycle data available).
    /// - Returns: Multiplier applied to raw HRV for normalization.
    public static func phaseMultiplier(for phase: CyclePhase?) -> Double {
        switch phase {
        case .follicular: return 1.0
        case .ovulation: return 1.05
        case .luteal: return 0.85
        case .menstrual: return 0.90
        case nil: return 1.0
        }
    }

    // MARK: - Normalization

    /// Normalizes an HRV reading against the phase baseline.
    ///
    /// - Parameters:
    ///   - hrvMs: Raw HRV in milliseconds.
    ///   - phase: Current cycle phase (nil if unavailable).
    /// - Returns: Phase-normalized HRV value.
    public static func normalize(hrvMs: Double, phase: CyclePhase?) -> Double {
        let multiplier = phaseMultiplier(for: phase)
        return hrvMs / multiplier
    }

    // MARK: - Scoring

    /// Scores a normalized HRV value on a 0-100 scale.
    ///
    /// Uses continuous linear interpolation within bands so that
    /// phase-normalization differences produce different scores
    /// even within the same band.
    ///
    /// - Parameter normalizedHrvMs: Phase-normalized HRV in milliseconds.
    /// - Returns: Score from 0-100.
    public static func score(normalizedHrvMs: Double) -> Int {
        switch normalizedHrvMs {
        case 80...:
            return 100
        case 60..<80:
            // 60ms → 60, 80ms → 100 (linear)
            let fraction = (normalizedHrvMs - 60.0) / 20.0
            return Int((60.0 + fraction * 40.0).rounded())
        case 40..<60:
            // 40ms → 30, 60ms → 60 (linear)
            let fraction = (normalizedHrvMs - 40.0) / 20.0
            return Int((30.0 + fraction * 30.0).rounded())
        case 20..<40:
            // 20ms → 10, 40ms → 30 (linear)
            let fraction = (normalizedHrvMs - 20.0) / 20.0
            return Int((10.0 + fraction * 20.0).rounded())
        default:
            return 0
        }
    }
}
