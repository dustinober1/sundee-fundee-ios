import Foundation

// MARK: - PlateauDetector

/// Detects stalled lifts from 1RM history and generates actionable alerts.
///
/// A plateau is defined as a lift whose 1RM has not increased over a
/// configurable window of attempts. The detector groups records by exercise,
/// sorts chronologically, and checks whether recent attempts show progress.
///
/// Pure domain logic — no framework dependencies.
public enum PlateauDetector {

    // MARK: - Configuration

    /// Minimum number of records required before a plateau can be detected.
    public static let minimumAttempts = 3

    /// Number of most-recent records to evaluate for progress.
    public static let recentWindow = 3

    /// Maximum allowed days between first and last attempt in the window
    /// for a plateau to be flagged. Prevents stale data from triggering alerts.
    public static let maxWindowDays = 90

    /// Minimum percentage improvement required to count as progress.
    /// 0.01 = 1% improvement over the window.
    public static let progressThreshold = 0.01

    // MARK: - Types

    /// A detected plateau for a specific lift.
    public struct PlateauAlert: Sendable, Equatable {
        /// The exercise name that has stalled.
        public let exerciseName: String

        /// The current 1RM weight (most recent).
        public let currentWeight: Double

        /// The weight unit.
        public let unit: WeightUnit

        /// The best weight achieved in the evaluation window.
        public let bestWeight: Double

        /// Number of consecutive attempts without meaningful progress.
        public let stallCount: Int

        /// Days since the best weight was achieved.
        public let daysSinceBest: Int

        /// Actionable recommendation.
        public let recommendation: String
    }

    // MARK: - Detection

    /// Analyzes 1RM records and returns alerts for stalled lifts.
    ///
    /// - Parameter records: All 1RM records for the user, across all exercises.
    /// - Returns: An array of `PlateauAlert` for exercises that appear stalled.
    public static func detect(from records: [OneRepMaxRecord]) -> [PlateauAlert] {
        // Group by exercise name
        let grouped = Dictionary(grouping: records) { $0.exerciseName }

        var alerts: [PlateauAlert] = []

        for (exerciseName, exerciseRecords) in grouped {
            // Need enough data to evaluate
            guard exerciseRecords.count >= minimumAttempts else { continue }

            // Sort chronologically (oldest first)
            let sorted = exerciseRecords.sorted { $0.date < $1.date }

            // Take the most recent window
            let recent = Array(sorted.suffix(recentWindow))
            guard recent.count >= minimumAttempts else { continue }

            // Check the time span — skip if window is too old
            guard let first = recent.first, let last = recent.last else { continue }
            let daySpan = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 0
            guard daySpan <= maxWindowDays else { continue }

            // Find best weight in the window
            let bestWeight = recent.map { $0.weight }.max() ?? 0
            let currentWeight = last.weight

            // Check if there's meaningful progress
            // Progress = current weight is meaningfully higher than oldest in window
            let oldestInWindow = first.weight
            let improvement = oldestInWindow > 0
                ? (bestWeight - oldestInWindow) / oldestInWindow
                : 0

            if improvement < progressThreshold {
                // Count records since the last time a new PR was set.
                // Walk backwards; a "new PR" is a record whose weight exceeds
                // all records that came before it chronologically.
                let peak = sorted.map { $0.weight }.max() ?? 0
                var stallCount = 0
                var seenPeak = false
                for record in sorted.reversed() {
                    if record.weight >= peak && !seenPeak {
                        // First time hitting the peak from the end — still stalled
                        seenPeak = true
                        stallCount += 1
                    } else if seenPeak && record.weight >= peak {
                        // Additional records at peak = continued stall
                        stallCount += 1
                    } else if seenPeak {
                        // Found a record below peak before the peak run = stop
                        break
                    } else {
                        stallCount += 1
                    }
                }
                // At minimum, the recent window is stalled
                stallCount = max(stallCount, recent.count)

                let bestDate = sorted.last(where: { $0.weight == peak })?.date ?? last.date
                let daysSinceBest = Calendar.current.dateComponents(
                    [.day], from: bestDate, to: Date()
                ).day ?? 0

                let recommendation = generateRecommendation(
                    exerciseName: exerciseName,
                    stallCount: stallCount,
                    currentWeight: currentWeight,
                    bestWeight: peak
                )

                alerts.append(PlateauAlert(
                    exerciseName: exerciseName,
                    currentWeight: currentWeight,
                    unit: last.unit,
                    bestWeight: peak,
                    stallCount: stallCount,
                    daysSinceBest: daysSinceBest,
                    recommendation: recommendation
                ))
            }
        }

        // Sort by stall severity (longest stall first)
        return alerts.sorted { $0.stallCount > $1.stallCount }
    }

    // MARK: - Recommendations

    private static func generateRecommendation(
        exerciseName: String,
        stallCount: Int,
        currentWeight: Double,
        bestWeight: Double
    ) -> String {
        if stallCount >= 6 {
            return "Consider changing your rep scheme or adding a variation of \(exerciseName) for 3-4 weeks, then re-test."
        } else if stallCount >= 4 {
            return "Try a deload week at 60% of your \(exerciseName) max, then build back with smaller jumps."
        } else {
            return "Add volume: try 3-5 extra sets of \(exerciseName) per week at 70-80% to break through."
        }
    }
}
