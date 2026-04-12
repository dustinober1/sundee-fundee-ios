import Foundation

// MARK: - Time Range

/// Time ranges for analytics chart filtering.
public enum TimeRange: String, CaseIterable, Sendable {
    case lastMonth
    case lastThreeMonths
    case lastSixMonths
    case lastYear
    case allTime

    /// The start date for this time range, computed relative to the current date.
    public var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .lastMonth:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .lastThreeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .lastSixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .lastYear:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .allTime:
            return Date.distantPast
        }
    }

    /// Start date computed relative to a specific reference date (useful for testing).
    public func startDate(relativeTo reference: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .lastMonth:
            return calendar.date(byAdding: .month, value: -1, to: reference) ?? reference
        case .lastThreeMonths:
            return calendar.date(byAdding: .month, value: -3, to: reference) ?? reference
        case .lastSixMonths:
            return calendar.date(byAdding: .month, value: -6, to: reference) ?? reference
        case .lastYear:
            return calendar.date(byAdding: .year, value: -1, to: reference) ?? reference
        case .allTime:
            return Date.distantPast
        }
    }
}

// MARK: - Data Points

/// A single data point for strength progression charts.
public struct StrengthDataPoint: Equatable, Sendable, Identifiable {
    public let id = UUID()
    public let date: Date
    public let exerciseName: String
    public let weight: Double
    public let unit: WeightUnit

    public init(date: Date, exerciseName: String, weight: Double, unit: WeightUnit) {
        self.date = date
        self.exerciseName = exerciseName
        self.weight = weight
        self.unit = unit
    }
}

/// A single data point for training volume charts, aggregated by week.
public struct VolumeDataPoint: Equatable, Sendable, Identifiable {
    public let id = UUID()
    public let weekStartDate: Date
    public let totalVolume: Double
    public let workoutCount: Int

    public init(weekStartDate: Date, totalVolume: Double, workoutCount: Int) {
        self.weekStartDate = weekStartDate
        self.totalVolume = totalVolume
        self.workoutCount = workoutCount
    }
}

/// A single data point for workout frequency charts, aggregated by week.
public struct FrequencyDataPoint: Equatable, Sendable, Identifiable {
    public let id = UUID()
    public let weekStartDate: Date
    public let workoutCount: Int
    public let label: String

    public init(weekStartDate: Date, workoutCount: Int, label: String) {
        self.weekStartDate = weekStartDate
        self.workoutCount = workoutCount
        self.label = label
    }
}

/// A single data point for cycle-correlated performance charts.
public struct CyclePerformancePoint: Equatable, Sendable, Identifiable {
    public var id: String { phase.rawValue }
    public let phase: CyclePhase
    public let averageVolume: Double
    public let workoutCount: Int
    public let confidence: Double

    public init(phase: CyclePhase, averageVolume: Double, workoutCount: Int, confidence: Double) {
        self.phase = phase
        self.averageVolume = averageVolume
        self.workoutCount = workoutCount
        self.confidence = confidence
    }
}

// MARK: - Aggregator

/// Pure domain service that transforms raw records into chart-ready data points.
///
/// All methods are static and side-effect free. The ViewModel layer calls these
/// with data fetched from the persistence store.
public enum ChartDataAggregator {

    // MARK: - Cached Formatters

    private static let weekLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    // MARK: Strength Progression

    /// Groups one-rep-max records by exercise, filters by time range, and sorts by date.
    ///
    /// - Parameters:
    ///   - records: Raw one-rep-max records from the persistence store.
    ///   - timeRange: The time window to filter by.
    ///   - referenceDate: Optional reference date for time range computation (defaults to now).
    /// - Returns: Sorted array of strength data points within the time range.
    public static func strengthProgression(
        from records: [OneRepMaxRecord],
        timeRange: TimeRange,
        referenceDate: Date = Date()
    ) -> [StrengthDataPoint] {
        let cutoff = timeRange.startDate(relativeTo: referenceDate)

        return records
            .filter { $0.date >= cutoff }
            .map { StrengthDataPoint(
                date: $0.date,
                exerciseName: $0.exerciseName,
                weight: $0.weight,
                unit: $0.unit
            ) }
            .sorted { $0.date < $1.date }
    }

    // MARK: Training Volume

    /// Aggregates completed workout volumes by ISO week.
    ///
    /// Only workouts with a non-nil `completedAt` are included.
    ///
    /// - Parameters:
    ///   - workouts: Raw workouts from the persistence store.
    ///   - timeRange: The time window to filter by.
    ///   - referenceDate: Optional reference date for time range computation (defaults to now).
    /// - Returns: Sorted array of weekly volume data points.
    public static func trainingVolume(
        from workouts: [Workout],
        timeRange: TimeRange,
        referenceDate: Date = Date()
    ) -> [VolumeDataPoint] {
        let cutoff = timeRange.startDate(relativeTo: referenceDate)
        let calendar = Calendar.current

        let completed = workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= cutoff
        }

        // Group by ISO week start date
        var weekMap: [Date: (volume: Double, count: Int)] = [:]

        for workout in completed {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.completedAt!))!
            if var existing = weekMap[weekStart] {
                existing.volume += workout.totalVolume
                existing.count += 1
                weekMap[weekStart] = existing
            } else {
                weekMap[weekStart] = (volume: workout.totalVolume, count: 1)
            }
        }

        return weekMap.map { key, value in
            VolumeDataPoint(weekStartDate: key, totalVolume: value.volume, workoutCount: value.count)
        }.sorted { $0.weekStartDate < $1.weekStartDate }
    }

    // MARK: Workout Frequency

    /// Counts completed workouts per ISO week.
    ///
    /// Only workouts with a non-nil `completedAt` are included.
    ///
    /// - Parameters:
    ///   - workouts: Raw workouts from the persistence store.
    ///   - timeRange: The time window to filter by.
    ///   - referenceDate: Optional reference date for time range computation (defaults to now).
    /// - Returns: Sorted array of weekly frequency data points with human-readable labels.
    public static func workoutFrequency(
        from workouts: [Workout],
        timeRange: TimeRange,
        referenceDate: Date = Date()
    ) -> [FrequencyDataPoint] {
        let cutoff = timeRange.startDate(relativeTo: referenceDate)
        let calendar = Calendar.current

        let completed = workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= cutoff
        }

        var weekMap: [Date: Int] = [:]

        for workout in completed {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.completedAt!))!
            weekMap[weekStart, default: 0] += 1
        }

        return weekMap.map { key, count in
            let label = "Week of \(weekLabelFormatter.string(from: key))"
            return FrequencyDataPoint(weekStartDate: key, workoutCount: count, label: label)
        }.sorted { $0.weekStartDate < $1.weekStartDate }
    }

    // MARK: Cycle Correlation

    /// Maps workouts to their cycle phases via date overlap and averages volume per phase.
    ///
    /// Each workout is matched to the first `CyclePhaseInfo` whose date range contains
    /// the workout's `completedAt` date. The resulting points include the average
    /// confidence of matched phases.
    ///
    /// - Parameters:
    ///   - workouts: Raw workouts from the persistence store.
    ///   - phases: Cycle phase info records with date ranges.
    ///   - timeRange: The time window to filter by.
    ///   - referenceDate: Optional reference date for time range computation (defaults to now).
    /// - Returns: Array of performance points, one per represented phase.
    public static func cycleCorrelation(
        from workouts: [Workout],
        phases: [CyclePhaseInfo],
        timeRange: TimeRange,
        referenceDate: Date = Date()
    ) -> [CyclePerformancePoint] {
        let cutoff = timeRange.startDate(relativeTo: referenceDate)
        let calendar = Calendar.current

        let completed = workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= cutoff
        }

        // Map workouts to phases
        var phaseData: [CyclePhase: (volumes: [Double], confidences: [Double])] = [:]

        for workout in completed {
            let workoutDate = workout.completedAt!
            let dayStart = calendar.startOfDay(for: workoutDate)

            // Find the first phase whose date range contains this workout
            guard let matchingPhase = phases.first(where: { phase in
                let phaseStart = calendar.startOfDay(for: phase.startDate)
                let phaseEnd = calendar.startOfDay(for: phase.endDate)
                return dayStart >= phaseStart && dayStart <= phaseEnd
            }) else {
                continue
            }

            if var existing = phaseData[matchingPhase.phase] {
                existing.volumes.append(workout.totalVolume)
                existing.confidences.append(matchingPhase.confidence)
                phaseData[matchingPhase.phase] = existing
            } else {
                phaseData[matchingPhase.phase] = (
                    volumes: [workout.totalVolume],
                    confidences: [matchingPhase.confidence]
                )
            }
        }

        return phaseData.map { phase, data in
            let avgVolume = data.volumes.reduce(0, +) / Double(data.volumes.count)
            let avgConfidence = data.confidences.reduce(0, +) / Double(data.confidences.count)
            return CyclePerformancePoint(
                phase: phase,
                averageVolume: avgVolume,
                workoutCount: data.volumes.count,
                confidence: avgConfidence
            )
        }.sorted { $0.phase.rawValue < $1.phase.rawValue }
    }

    // MARK: Exercise Picker

    /// Returns unique exercise names from one-rep-max records, sorted alphabetically.
    ///
    /// Useful for populating the exercise picker in the strength progression chart.
    ///
    /// - Parameter records: Raw one-rep-max records.
    /// - Returns: Sorted array of unique exercise names.
    public static func exercises(from records: [OneRepMaxRecord]) -> [String] {
        Array(Set(records.map(\.exerciseName))).sorted()
    }
}
