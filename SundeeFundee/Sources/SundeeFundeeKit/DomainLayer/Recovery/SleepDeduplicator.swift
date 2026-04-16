import Foundation

// MARK: - SleepDeduplicator

/// Pure domain function that deduplicates overlapping sleep intervals from multiple sources.
///
/// HealthKit receives sleep data from both Apple Watch and iPhone, often with overlapping
/// time ranges. This algorithm merges overlapping intervals, prioritizing Watch data,
/// and returns the total deduplicated sleep duration.
///
/// ## Algorithm
/// 1. Filter to sleep stages only (exclude .inBed and .awake)
/// 2. Sort by start date ascending
/// 3. Merge overlapping intervals within Watch and non-Watch sets separately
/// 4. Remove non-Watch intervals that overlap with any merged Watch interval
/// 5. Sum all remaining merged interval durations
public enum SleepDeduplicator {

    // MARK: - Types

    /// Represents a single sleep interval with source and stage metadata.
    public struct SleepInterval: Sendable, Equatable {
        public let start: Date
        public let end: Date
        public let source: SleepSource
        public let stage: SleepStage

        public init(start: Date, end: Date, source: SleepSource, stage: SleepStage) {
            self.start = start
            self.end = end
            self.source = source
            self.stage = stage
        }
    }

    /// The device or app that recorded the sleep sample.
    public enum SleepSource: String, Sendable, Equatable {
        case watch
        case phone
        case other
    }

    /// HealthKit sleep category values mapping to sleep stages.
    public enum SleepStage: Int, Sendable, Equatable {
        case inBed = 0
        case asleepLegacy = 1   // legacy .asleep
        case awake = 2
        case asleepCore = 3
        case asleepDeep = 4
        case asleepREM = 5

        /// Whether this stage counts as actual sleep for duration calculation.
        public var countsAsSleep: Bool {
            switch self {
            case .asleepLegacy, .asleepCore, .asleepDeep, .asleepREM: return true
            case .inBed, .awake: return false
            }
        }
    }

    // MARK: - Deduplication

    /// Returns deduplicated total sleep duration in seconds.
    ///
    /// Algorithm:
    /// 1. Filter to sleep stages only (exclude .inBed and .awake)
    /// 2. Sort by start date ascending
    /// 3. Separate into Watch and non-Watch sets
    /// 4. Merge overlapping intervals within each set (sorted sweep line, O(n log n))
    /// 5. Remove non-Watch intervals that overlap with any merged Watch interval
    /// 6. Sum all remaining merged interval durations
    ///
    /// - Parameter intervals: Array of sleep intervals from potentially multiple sources.
    /// - Returns: Total sleep duration in seconds after deduplication.
    public static func deduplicate(_ intervals: [SleepInterval]) -> TimeInterval {
        // Step 1: Filter to sleep stages only
        let sleepIntervals = intervals.filter { $0.stage.countsAsSleep }
        guard !sleepIntervals.isEmpty else { return 0 }

        // Step 2: Sort by start date ascending
        let sorted = sleepIntervals.sorted { $0.start < $1.start }

        // Step 3: Separate into Watch and non-Watch sets
        let watchIntervals = sorted.filter { $0.source == .watch }
        let otherIntervals = sorted.filter { $0.source != .watch }

        // Step 4: Merge overlapping intervals within each set
        let mergedWatch = mergeOverlapping(watchIntervals)
        let mergedOther = mergeOverlapping(otherIntervals)

        // Step 5: Subtract Watch intervals from non-Watch intervals
        // Rather than removing overlapping non-Watch intervals entirely, trim them
        // so that only the portions outside the Watch range remain.
        var trimmedOther: [SleepInterval] = []
        for other in mergedOther {
            var remaining = [other]
            for watch in mergedWatch {
                var newRemaining: [SleepInterval] = []
                for interval in remaining {
                    let trimmed = subtractInterval(interval, from: watch)
                    newRemaining.append(contentsOf: trimmed)
                }
                remaining = newRemaining
            }
            trimmedOther.append(contentsOf: remaining)
        }

        // Step 6: Sum all remaining intervals
        let allMerged = mergedWatch + trimmedOther
        return allMerged.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) }
    }

    // MARK: - Private Helpers

    /// Merges overlapping intervals using sorted sweep line algorithm.
    ///
    /// Intervals are assumed to be sorted by start date ascending.
    /// If the current interval's start is <= the previous merged interval's end,
    /// the previous is extended to max(prev.end, current.end).
    private static func mergeOverlapping(_ intervals: [SleepInterval]) -> [SleepInterval] {
        guard !intervals.isEmpty else { return [] }

        var merged: [SleepInterval] = [intervals[0]]

        for interval in intervals.dropFirst() {
            let last = merged[merged.count - 1]
            if interval.start <= last.end {
                // Overlapping — extend the end to the later of the two
                let newEnd = max(last.end, interval.end)
                merged[merged.count - 1] = SleepInterval(
                    start: last.start,
                    end: newEnd,
                    source: last.source,
                    stage: last.stage
                )
            } else {
                merged.append(interval)
            }
        }

        return merged
    }

    /// Subtracts one interval from another, returning the remaining portions.
    ///
    /// If `subtract` overlaps with `source`, the overlapping portion is removed.
    /// This may result in zero, one, or two remaining intervals (if the subtract
    /// is in the middle, both the left and right portions remain).
    private static func subtractInterval(
        _ source: SleepInterval,
        from subtract: SleepInterval
    ) -> [SleepInterval] {
        // No overlap — source remains intact
        guard source.start < subtract.end && source.end > subtract.start else {
            return [source]
        }

        var result: [SleepInterval] = []

        // Left portion (before subtract.start)
        if source.start < subtract.start {
            result.append(SleepInterval(
                start: source.start,
                end: subtract.start,
                source: source.source,
                stage: source.stage
            ))
        }

        // Right portion (after subtract.end)
        if source.end > subtract.end {
            result.append(SleepInterval(
                start: subtract.end,
                end: source.end,
                source: source.source,
                stage: source.stage
            ))
        }

        return result
    }

    // MARK: - Sample Conversion

    /// Converts raw HKCategorySample data into SleepInterval domain types.
    ///
    /// This is the bridge between HealthKit's category samples and the pure domain model.
    /// Source name is matched case-insensitively: containing "watch" maps to `.watch`,
    /// otherwise `.phone`.
    ///
    /// - Parameter values: Array of tuples with (start, end, value, sourceName).
    /// - Returns: Array of SleepInterval instances, filtering out unknown sleep stages.
    public static func convertSamples(
        values: [(start: Date, end: Date, value: Int, sourceName: String)]
    ) -> [SleepInterval] {
        values.compactMap { sample in
            guard let stage = SleepStage(rawValue: sample.value) else { return nil }
            let source: SleepSource = sample.sourceName.lowercased().contains("watch") ? .watch : .phone
            return SleepInterval(start: sample.start, end: sample.end, source: source, stage: stage)
        }
    }
}
