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

    /// Default percentage improvement required to count as progress.
    /// 0.01 = 1% improvement over the window.
    public static let progressThreshold = 0.01

    /// Minimum records needed for rate-of-progress analysis.
    public static let minimumProgressRecords = 5

    // MARK: - Types

    /// Whether the plateau is a strength (1RM) or volume stall.
    public enum PlateauType: String, Sendable, Equatable {
        case strength
        case volume
    }

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

        /// Whether this is a strength or volume plateau.
        public let plateauType: PlateauType

        public init(
            exerciseName: String,
            currentWeight: Double,
            unit: WeightUnit,
            bestWeight: Double,
            stallCount: Int,
            daysSinceBest: Int,
            recommendation: String,
            plateauType: PlateauType = .strength
        ) {
            self.exerciseName = exerciseName
            self.currentWeight = currentWeight
            self.unit = unit
            self.bestWeight = bestWeight
            self.stallCount = stallCount
            self.daysSinceBest = daysSinceBest
            self.recommendation = recommendation
            self.plateauType = plateauType
        }
    }

    /// An early warning that progress is slowing before a full plateau.
    public struct RateOfProgressAlert: Sendable, Equatable {
        public let exerciseName: String
        /// Weight gained per week in the recent period.
        public let currentRate: Double
        /// Weight gained per week in the earlier period.
        public let historicalRate: Double
        public let message: String
    }

    // MARK: - Exercise-Specific Thresholds

    /// Returns an exercise-category-aware progress threshold.
    /// Compound lifts move larger absolute weights and progress more slowly,
    /// so they use a tighter threshold. Isolation/press exercises use a wider one.
    public static func progressThreshold(for category: WeightliftingCategory) -> Double {
        switch category {
        case .squat, .hipHinge, .olympicWeightlifting:
            return 0.005  // 0.5% — compound lifts progress slowly
        case .press, .pull:
            return 0.015  // 1.5% — upper body lifts progress faster
        case .carry:
            return 0.01   // 1.0% — default
        }
    }

    /// Resolves the category for an exercise name from the catalog, falling back to nil.
    private static func resolveCategory(
        exerciseName: String,
        catalog: [WeightliftingEntry]
    ) -> WeightliftingCategory? {
        catalog.first { $0.id == exerciseName }?.category
    }

    // MARK: - Strength Plateau Detection

    /// Analyzes 1RM records and returns alerts for stalled lifts.
    ///
    /// - Parameters:
    ///   - records: All 1RM records for the user, across all exercises.
    ///   - catalog: The exercise catalog for category-aware thresholds. When provided,
    ///     compound lifts use a tighter threshold (0.5%) while isolation lifts use a wider one (1.5%).
    /// - Returns: An array of `PlateauAlert` for exercises that appear stalled.
    public static func detect(
        from records: [OneRepMaxRecord],
        catalog: [WeightliftingEntry] = []
    ) -> [PlateauAlert] {
        let grouped = Dictionary(grouping: records) { $0.exerciseName }

        var alerts: [PlateauAlert] = []

        for (exerciseName, exerciseRecords) in grouped {
            guard exerciseRecords.count >= minimumAttempts else { continue }

            let sorted = exerciseRecords.sorted { $0.date < $1.date }

            let recent = Array(sorted.suffix(recentWindow))
            guard recent.count >= minimumAttempts else { continue }

            guard let first = recent.first, let last = recent.last else { continue }
            let daySpan = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 0
            guard daySpan <= maxWindowDays else { continue }

            let bestWeight = recent.map { $0.weight }.max() ?? 0
            let currentWeight = last.weight

            let oldestInWindow = first.weight
            let improvement = oldestInWindow > 0
                ? (bestWeight - oldestInWindow) / oldestInWindow
                : 0

            // Use category-specific threshold when catalog is available
            let threshold: Double
            if let category = resolveCategory(exerciseName: exerciseName, catalog: catalog) {
                threshold = progressThreshold(for: category)
            } else {
                threshold = progressThreshold
            }

            if improvement < threshold {
                let peak = sorted.map { $0.weight }.max() ?? 0
                var stallCount = 0
                var seenPeak = false
                for record in sorted.reversed() {
                    if record.weight >= peak && !seenPeak {
                        seenPeak = true
                        stallCount += 1
                    } else if seenPeak && record.weight >= peak {
                        stallCount += 1
                    } else if seenPeak {
                        break
                    } else {
                        stallCount += 1
                    }
                }
                stallCount = max(stallCount, recent.count)

                let bestDate = sorted.last(where: { $0.weight == peak })?.date ?? last.date
                let daysSinceBest = Calendar.current.dateComponents(
                    [.day], from: bestDate, to: Date()
                ).day ?? 0

                let recommendation = generateRecommendation(
                    exerciseName: exerciseName,
                    stallCount: stallCount,
                    currentWeight: currentWeight,
                    bestWeight: peak,
                    plateauType: .strength
                )

                alerts.append(PlateauAlert(
                    exerciseName: exerciseName,
                    currentWeight: currentWeight,
                    unit: last.unit,
                    bestWeight: peak,
                    stallCount: stallCount,
                    daysSinceBest: daysSinceBest,
                    recommendation: recommendation,
                    plateauType: .strength
                ))
            }
        }

        return alerts.sorted { $0.stallCount > $1.stallCount }
    }

    // MARK: - Volume Plateau Detection

    /// Detects exercises whose training volume has stalled over recent weeks.
    ///
    /// Groups workouts by week, computes per-exercise weekly volume (reps x weight),
    /// and flags exercises with less than 2% volume growth across the window.
    ///
    /// - Parameters:
    ///   - workouts: All completed workouts.
    ///   - windowWeeks: Number of weeks to evaluate (default 4).
    /// - Returns: Alerts for exercises with stalled volume.
    public static func detectVolumePlateaus(
        from workouts: [Workout],
        windowWeeks: Int = 4
    ) -> [PlateauAlert] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .weekOfYear, value: -windowWeeks, to: Date()) ?? Date()
        let recentWorkouts = workouts.filter { $0.date >= cutoffDate && $0.isComplete }

        guard recentWorkouts.count >= 2 else { return [] }

        // Group workouts by week number
        var weeklyVolume: [Int: [String: Double]] = [:]
        for workout in recentWorkouts {
            let weekNumber = calendar.component(.weekOfYear, from: workout.date)
            let yearWeek = calendar.component(.year, from: workout.date) * 100 + weekNumber
            for exercise in workout.exercises {
                let volume = exercise.targetSets.reduce(0.0) { sum, set in
                    let reps = set.actualReps ?? set.reps
                    let weight = (set.completedWeight ?? 0) > 0
                        ? set.completedWeight!
                        : (set.prescribedWeight > 0 ? set.prescribedWeight : 0)
                    return sum + Double(reps) * weight
                }
                weeklyVolume[yearWeek, default: [:]][exercise.name, default: 0] += volume
            }
        }

        guard weeklyVolume.count >= 2 else { return [] }

        let sortedWeeks = weeklyVolume.keys.sorted()
        // Collect all exercises that appear in at least 2 weeks
        var allExercises = Set<String>()
        for (_, exercises) in weeklyVolume {
            allExercises.formUnion(exercises.keys)
        }

        var alerts: [PlateauAlert] = []
        let volumeGrowthThreshold = 0.02 // 2%

        for exerciseName in allExercises {
            let volumes = sortedWeeks.compactMap { weeklyVolume[$0]?[exerciseName] }
            guard volumes.count >= 2 else { continue }

            let firstVolume = volumes.first!
            let lastVolume = volumes.last!
            guard firstVolume > 0 else { continue }

            let growth = (lastVolume - firstVolume) / firstVolume
            if growth < volumeGrowthThreshold {
                let recommendation = generateRecommendation(
                    exerciseName: exerciseName,
                    stallCount: volumes.count,
                    currentWeight: lastVolume,
                    bestWeight: volumes.max() ?? lastVolume,
                    plateauType: .volume
                )
                alerts.append(PlateauAlert(
                    exerciseName: exerciseName,
                    currentWeight: lastVolume,
                    unit: .lbs,
                    bestWeight: volumes.max() ?? lastVolume,
                    stallCount: volumes.count,
                    daysSinceBest: 0,
                    recommendation: recommendation,
                    plateauType: .volume
                ))
            }
        }

        return alerts.sorted { $0.stallCount > $1.stallCount }
    }

    // MARK: - Rate of Progress Detection

    /// Detects exercises where the rate of strength progress is slowing,
    /// providing an early warning before a full plateau manifests.
    ///
    /// Splits 1RM history into two halves and compares the rate of weight
    /// gain per week. If the recent rate drops below 50% of the earlier rate,
    /// an alert is generated.
    ///
    /// - Parameters:
    ///   - records: All 1RM records for the user.
    ///   - minimumRecords: Minimum records per exercise (default 5).
    /// - Returns: Early warning alerts for slowing progress.
    public static func detectSlowingProgress(
        from records: [OneRepMaxRecord],
        minimumRecords: Int = 5
    ) -> [RateOfProgressAlert] {
        let grouped = Dictionary(grouping: records) { $0.exerciseName }
        var alerts: [RateOfProgressAlert] = []

        for (exerciseName, exerciseRecords) in grouped {
            guard exerciseRecords.count >= minimumRecords else { continue }

            let sorted = exerciseRecords.sorted { $0.date < $1.date }

            // Split into first half and second half
            let midpoint = sorted.count / 2
            let firstHalf = Array(sorted.prefix(midpoint))
            let secondHalf = Array(sorted.suffix(from: midpoint))

            guard firstHalf.count >= 2, secondHalf.count >= 2 else { continue }

            let historicalRate = ratePerWeek(records: firstHalf)
            let currentRate = ratePerWeek(records: secondHalf)

            // Only flag if historical rate was positive (they were progressing)
            // and current rate has dropped below 50% of historical
            if historicalRate > 0 && currentRate < historicalRate * 0.5 {
                let message: String
                if currentRate <= 0 {
                    message = "Your progress on \(exerciseName) has stalled — consider a variation or deload before a full plateau."
                } else {
                    message = "Your progress on \(exerciseName) is slowing — consider a variation or deload before a full plateau."
                }
                alerts.append(RateOfProgressAlert(
                    exerciseName: exerciseName,
                    currentRate: currentRate,
                    historicalRate: historicalRate,
                    message: message
                ))
            }
        }

        return alerts
    }

    /// Computes weight gained per week across a sorted slice of records.
    private static func ratePerWeek(records: [OneRepMaxRecord]) -> Double {
        guard let first = records.first, let last = records.last else { return 0 }
        let weeks = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day.map { Double($0) / 7.0 } ?? 0
        guard weeks > 0 else { return 0 }
        return (last.weight - first.weight) / weeks
    }

    // MARK: - Recommendations

    private static func generateRecommendation(
        exerciseName: String,
        stallCount: Int,
        currentWeight: Double,
        bestWeight: Double,
        plateauType: PlateauType
    ) -> String {
        switch plateauType {
        case .strength:
            if stallCount >= 6 {
                return "Consider changing your rep scheme or adding a variation of \(exerciseName) for 3-4 weeks, then re-test."
            } else if stallCount >= 4 {
                return "Try a deload week at 60% of your \(exerciseName) max, then build back with smaller jumps."
            } else {
                return "Add volume: try 3-5 extra sets of \(exerciseName) per week at 70-80% to break through."
            }
        case .volume:
            return "Your \(exerciseName) volume has plateaued. Try adding 1-2 sets per session or increase weight by 5%."
        }
    }
}
