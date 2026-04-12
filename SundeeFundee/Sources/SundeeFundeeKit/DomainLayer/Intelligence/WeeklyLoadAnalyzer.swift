import Foundation

// MARK: - WeeklyLoadAnalyzer

/// Analyzes completed workout history to surface volume, intensity,
/// frequency, and muscle-group balance trends over rolling weeks.
///
/// Pure domain logic — no framework dependencies.
public enum WeeklyLoadAnalyzer {

    // MARK: - Types

    /// Summary of a single training week.
    public struct WeeklySummary: Sendable, Equatable {
        /// The Monday that starts this ISO week.
        public let weekStartDate: Date

        /// Total number of workouts completed.
        public let workoutCount: Int

        /// Total training duration in minutes.
        public let totalMinutes: Int

        /// Distinct muscle groups trained (from exercise names).
        public let muscleGroupsHit: Set<String>

        /// Exercises performed this week.
        public let exerciseNames: [String]
    }

    /// A detected trend across multiple weeks.
    public struct LoadTrend: Sendable, Equatable {
        public let type: TrendType
        public let message: String
        public let severity: TrendSeverity
    }

    public enum TrendType: String, Sendable, Equatable {
        /// Workout frequency is declining.
        case frequencyDrop
        /// Workout frequency is increasing nicely.
        case frequencyRise
        /// Muscle group imbalance detected.
        case muscleImbalance
        /// Possible overreaching (too much volume).
        case overreaching
        /// Undertraining (very low volume).
        case undertraining
        /// Consistent training pattern.
        case consistent
        /// Push/pull ratio imbalance within a week.
        case pushPullImbalance
        /// Repeating pattern of missed/dropped weeks.
        case missedSessionPattern
    }

    public enum TrendSeverity: String, Sendable, Equatable {
        case info
        case warning
        case positive
    }

    // MARK: - Analysis

    /// Builds weekly summaries from completed workout records.
    ///
    /// - Parameters:
    ///   - workouts: Completed workout records.
    ///   - weekCount: Number of recent weeks to analyze (default 4).
    /// - Returns: Weekly summaries sorted oldest-first.
    public static func weeklySummaries(
        from workouts: [CompletedWorkoutRecord],
        weekCount: Int = 4
    ) -> [WeeklySummary] {
        let calendar = Calendar.current

        // Group workouts by ISO week start (Monday)
        var weekBuckets: [Date: [CompletedWorkoutRecord]] = [:]

        for workout in workouts {
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: workout.date)?.start else {
                continue
            }
            weekBuckets[weekStart, default: []].append(workout)
        }

        // Build summaries for the most recent N weeks
        let sortedWeeks = weekBuckets.keys.sorted()
        let recentWeeks = Array(sortedWeeks.suffix(weekCount))

        return recentWeeks.map { weekStart in
            let records = weekBuckets[weekStart] ?? []
            let allExercises = records.flatMap { $0.exerciseNames }
            let muscleGroups = Set(allExercises.compactMap { classifyMuscleGroup($0) })
            let totalMinutes = records.compactMap { $0.duration }.reduce(0, +)

            return WeeklySummary(
                weekStartDate: weekStart,
                workoutCount: records.count,
                totalMinutes: totalMinutes,
                muscleGroupsHit: muscleGroups,
                exerciseNames: allExercises
            )
        }
    }

    /// Detects trends from weekly summaries.
    ///
    /// - Parameter summaries: Weekly summaries (oldest-first).
    /// - Returns: Detected trends.
    public static func detectTrends(from summaries: [WeeklySummary]) -> [LoadTrend] {
        guard summaries.count >= 2 else { return [] }

        var trends: [LoadTrend] = []

        // Frequency analysis
        let counts = summaries.map(\.workoutCount)
        let recentAvg = Double(counts.suffix(2).reduce(0, +)) / 2.0
        let olderAvg = Double(counts.prefix(summaries.count - 2 < 1 ? 1 : summaries.count - 2).reduce(0, +))
            / Double(max(1, summaries.count - 2))

        if recentAvg < olderAvg * 0.6 && olderAvg > 0 {
            trends.append(LoadTrend(
                type: .frequencyDrop,
                message: "Your workout frequency dropped from ~\(Int(olderAvg.rounded())) to ~\(Int(recentAvg.rounded())) sessions/week.",
                severity: .warning
            ))
        } else if recentAvg > olderAvg * 1.3 && olderAvg > 0 {
            trends.append(LoadTrend(
                type: .frequencyRise,
                message: "Great consistency — you're training ~\(Int(recentAvg.rounded())) sessions/week, up from ~\(Int(olderAvg.rounded())).",
                severity: .positive
            ))
        }

        // Overreaching check (>6 sessions/week sustained for 2+ weeks)
        let highVolumeWeeks = counts.suffix(2).filter { $0 >= 6 }.count
        if highVolumeWeeks >= 2 {
            trends.append(LoadTrend(
                type: .overreaching,
                message: "You've trained 6+ times/week for 2 consecutive weeks. Consider a lighter week.",
                severity: .warning
            ))
        }

        // Undertraining check (<2 sessions/week for 2+ weeks)
        let lowVolumeWeeks = counts.suffix(2).filter { $0 <= 1 }.count
        if lowVolumeWeeks >= 2 {
            trends.append(LoadTrend(
                type: .undertraining,
                message: "Only 0-1 sessions/week recently. Even 2-3 short sessions help maintain progress.",
                severity: .warning
            ))
        }

        // Muscle group balance
        if let lastWeek = summaries.last {
            let majorGroups: Set<String> = ["Upper Push", "Upper Pull", "Lower", "Core"]
            let missing = majorGroups.subtracting(lastWeek.muscleGroupsHit)
            if !missing.isEmpty && lastWeek.workoutCount >= 3 {
                let missingList = missing.sorted().joined(separator: ", ")
                trends.append(LoadTrend(
                    type: .muscleImbalance,
                    message: "Last week missed: \(missingList). Try to hit all major groups each week.",
                    severity: .info
                ))
            }
        }

        // Push/pull ratio imbalance
        if let lastWeek = summaries.last, lastWeek.workoutCount >= 2 {
            let ratio = pushPullRatio(from: lastWeek)
            if ratio.push > 0 && ratio.pull > 0 {
                if ratio.push > ratio.pull * 2 {
                    trends.append(LoadTrend(
                        type: .pushPullImbalance,
                        message: "Push/Pull ratio is \(ratio.push):\(ratio.pull) this week. Aim for roughly 1:1 to prevent shoulder and posture issues.",
                        severity: .warning
                    ))
                } else if ratio.pull > ratio.push * 2 {
                    trends.append(LoadTrend(
                        type: .pushPullImbalance,
                        message: "Pull/Push ratio is \(ratio.pull):\(ratio.push) this week. Add some pressing to maintain balance.",
                        severity: .warning
                    ))
                }
            }
        }

        // Missed session pattern detection
        if summaries.count >= 4 {
            let pattern = detectMissedSessionPattern(counts: counts)
            if let pattern {
                trends.append(pattern)
            }
        }

        // Consistency
        if trends.isEmpty && summaries.count >= 3 {
            let variance = counts.variance()
            if variance < 1.5 {
                trends.append(LoadTrend(
                    type: .consistent,
                    message: "Solid consistency over the last \(summaries.count) weeks. Keep it up.",
                    severity: .positive
                ))
            }
        }

        return trends
    }

    // MARK: - Push/Pull Ratio

    /// Computes the count of Upper Push vs Upper Pull exercises in a weekly summary.
    public static func pushPullRatio(from summary: WeeklySummary) -> (push: Int, pull: Int) {
        var push = 0
        var pull = 0
        for name in summary.exerciseNames {
            let group = classifyMuscleGroup(name)
            if group == "Upper Push" { push += 1 }
            if group == "Upper Pull" { pull += 1 }
        }
        return (push, pull)
    }

    // MARK: - Missed Session Pattern Detection

    /// Looks for repeating drop-off patterns in workout counts.
    /// E.g., [4, 4, 1, 4, 4, 1] → drop-off every 3rd week.
    private static func detectMissedSessionPattern(counts: [Int]) -> LoadTrend? {
        guard counts.count >= 4 else { return nil }

        let avg = Double(counts.reduce(0, +)) / Double(counts.count)
        guard avg > 1 else { return nil }

        // Find weeks that are significantly below average (< 40% of avg)
        let dropThreshold = avg * 0.4
        let dropWeeks = counts.enumerated().filter { Double($0.element) < dropThreshold }

        // Need at least 2 drop weeks to detect a pattern
        guard dropWeeks.count >= 2 else { return nil }

        // Check if drops are evenly spaced
        let gaps = zip(dropWeeks, dropWeeks.dropFirst()).map { $1.offset - $0.offset }
        guard let firstGap = gaps.first, firstGap >= 2 else { return nil }
        let allSameGap = gaps.allSatisfy { $0 == firstGap }

        if allSameGap {
            let ordinal = firstGap == 2 ? "3rd" : "\(firstGap + 1)th"
            return LoadTrend(
                type: .missedSessionPattern,
                message: "You tend to drop off every \(ordinal) week. Consider scheduling a deliberate lighter week instead of skipping.",
                severity: .info
            )
        }

        return nil
    }

    // MARK: - Muscle Group Classification

    /// Maps an exercise name to a broad muscle group category.
    public static func classifyMuscleGroup(_ exerciseName: String) -> String? {
        let name = exerciseName.lowercased()

        // Lower body
        let lowerKeywords = ["squat", "deadlift", "lunge", "leg", "hip thrust",
                             "glute", "hamstring", "calf", "step-up", "box jump"]
        if lowerKeywords.contains(where: { name.contains($0) }) {
            return "Lower"
        }

        // Upper push
        let pushKeywords = ["bench", "press", "push-up", "pushup", "dip",
                            "overhead", "shoulder", "jerk", "thruster"]
        if pushKeywords.contains(where: { name.contains($0) }) {
            return "Upper Push"
        }

        // Upper pull
        let pullKeywords = ["row", "pull-up", "pullup", "chin-up", "lat",
                            "curl", "snatch", "clean", "face pull", "muscle-up"]
        if pullKeywords.contains(where: { name.contains($0) }) {
            return "Upper Pull"
        }

        // Core
        let coreKeywords = ["sit-up", "situp", "plank", "crunch", "ab",
                            "toes-to-bar", "l-sit", "hollow", "v-up"]
        if coreKeywords.contains(where: { name.contains($0) }) {
            return "Core"
        }

        return nil
    }
}

// MARK: - Array Extension

private extension Array where Element == Int {
    func variance() -> Double {
        guard count > 1 else { return 0 }
        let mean = Double(reduce(0, +)) / Double(count)
        let sumSquares = reduce(0.0) { $0 + pow(Double($1) - mean, 2) }
        return sumSquares / Double(count)
    }
}
