import Foundation

// MARK: - CyclePhaseScorer

/// Scores the current cycle phase as a contextual modifier for recovery.
///
/// Each phase has inherent energy and recovery characteristics:
/// - Follicular: energy rising, good for intensity
/// - Ovulation: peak performance window
/// - Luteal: progesterone rises, recovery may be slower
/// - Menstrual: energy typically lowest
public enum CyclePhaseScorer {

    // MARK: - Scoring

    /// Scores a cycle phase as a recovery input.
    ///
    /// - Parameter phase: Current cycle phase (nil when no data available).
    /// - Returns: Tuple of (score 0-100, explanation string).
    public static func score(phase: CyclePhase?) -> (score: Int, explanation: String) {
        switch phase {
        case .follicular:
            return (80, "Follicular phase — energy rising, good for intensity")
        case .ovulation:
            return (85, "Ovulation phase — peak performance window")
        case .luteal:
            return (60, "Luteal phase — recovery may be slower, focus on maintenance")
        case .menstrual:
            return (50, "Menstrual phase — energy typically lower, prioritize recovery")
        case nil:
            return (70, "No cycle data — moderate default")
        }
    }
}
