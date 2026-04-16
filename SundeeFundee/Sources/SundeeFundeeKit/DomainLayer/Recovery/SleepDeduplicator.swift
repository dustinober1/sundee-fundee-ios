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
    /// - Parameter intervals: Array of sleep intervals from potentially multiple sources.
    /// - Returns: Total sleep duration in seconds after deduplication.
    public static func deduplicate(_ intervals: [SleepInterval]) -> TimeInterval {
        return 0 // stub -- tests will fail
    }
}
