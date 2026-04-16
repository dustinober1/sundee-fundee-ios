import Foundation

// MARK: - TrainingLoadScorer

/// Scores training load based on the Acute:Chronic Workload Ratio (ACWR).
///
/// Compares current week workout volume against the prior 3-week average.
/// A ratio around 1.0 indicates balanced load; above 1.5 indicates
/// overreaching; below 0.8 indicates detraining.
public enum TrainingLoadScorer {

    // MARK: - Scoring

    /// Computes a training load sub-score from weekly summaries.
    ///
    /// - Parameter summaries: Weekly summaries (last 4 weeks recommended).
    /// - Returns: Tuple of (score 0-100, explanation string).
    public static func score(
        summaries: [WeeklyLoadAnalyzer.WeeklySummary]
    ) -> (score: Int, explanation: String) {
        guard summaries.count >= 2 else {
            return (75, "Insufficient training history — moderate default")
        }

        let sorted = summaries.sorted { $0.weekStartDate < $1.weekStartDate }
        let currentWeek = sorted.last!
        let priorWeeks = Array(sorted.dropLast())

        let currentCount = Double(currentWeek.workoutCount)
        let priorAvg = priorWeeks.isEmpty
            ? currentCount
            : priorWeeks.map { Double($0.workoutCount) }.reduce(0, +) / Double(priorWeeks.count)

        guard priorAvg > 0 else {
            return (75, "No prior training data — moderate default")
        }

        let acwr = currentCount / priorAvg
        let (score, message) = scoreACWR(acwr)

        return (score, message)
    }

    // MARK: - ACWR Scoring

    /// Scores an ACWR value on a 0-100 scale.
    ///
    /// - Parameter acwr: Acute:Chronic Workload Ratio.
    /// - Returns: Tuple of (score 0-100, explanation string).
    private static func scoreACWR(_ acwr: Double) -> (score: Int, explanation: String) {
        switch acwr {
        case ..<0.8:
            return (90, "Load is well within recovery range — well rested")
        case 0.8..<1.0:
            return (80, "Load is within recovery range")
        case 1.0..<1.3:
            return (60, "Load is within recovery range — building phase")
        case 1.3..<1.5:
            return (40, "High weekly load — body needs recovery time")
        default:
            return (20, "High weekly load — body needs recovery time")
        }
    }
}
