import XCTest
@testable import SundeeFundeeKit

// MARK: - SleepDeduplicatorTests

/// Tests for the SleepDeduplicator pure domain function.
///
/// Sleep data from HealthKit often contains overlapping samples from Apple Watch
/// and iPhone. These tests verify that the deduplication algorithm correctly
/// merges overlapping intervals and returns accurate total sleep duration.
final class SleepDeduplicatorTests: XCTestCase {

    // MARK: - Factory Helpers

    /// Creates a sleep interval relative to now using hours-ago offsets.
    ///
    /// - Parameters:
    ///   - hoursAgoStart: Hours ago when the interval started.
    ///   - hoursAgoEnd: Hours ago when the interval ended.
    ///   - source: The device source (default: .watch).
    ///   - stage: The sleep stage (default: .asleepCore).
    /// - Returns: A SleepInterval instance.
    private func makeInterval(
        hoursAgoStart: Double,
        hoursAgoEnd: Double,
        source: SleepDeduplicator.SleepSource = .watch,
        stage: SleepDeduplicator.SleepStage = .asleepCore
    ) -> SleepDeduplicator.SleepInterval {
        let now = Date()
        let start = now.addingTimeInterval(-hoursAgoStart * 3600)
        let end = now.addingTimeInterval(-hoursAgoEnd * 3600)
        return SleepDeduplicator.SleepInterval(start: start, end: end, source: source, stage: stage)
    }

    // MARK: - Empty Input

    func testEmptyInput_ReturnsZero() {
        let result = SleepDeduplicator.deduplicate([])
        XCTAssertEqual(result, 0, "Empty input should return 0 duration")
    }

    // MARK: - Single Source

    func testSingleWatchSample_ReturnsCorrectDuration() {
        // 8 hours of asleepCore from Watch
        let intervals = [
            makeInterval(hoursAgoStart: 8, hoursAgoEnd: 0, source: .watch, stage: .asleepCore)
        ]
        let result = SleepDeduplicator.deduplicate(intervals)
        let expected: TimeInterval = 8 * 3600 // 28800 seconds
        XCTAssertEqual(result, expected, accuracy: 1.0, "Single Watch sample should return ~8h duration")
    }

    // MARK: - Watch + Phone Duplicate

    func testWatchAndPhoneIdenticalInterval_ReturnsSingleDuration() {
        // Watch and Phone both record the same 8h interval
        let intervals = [
            makeInterval(hoursAgoStart: 8, hoursAgoEnd: 0, source: .watch, stage: .asleepCore),
            makeInterval(hoursAgoStart: 8, hoursAgoEnd: 0, source: .phone, stage: .asleepCore)
        ]
        let result = SleepDeduplicator.deduplicate(intervals)
        let expected: TimeInterval = 8 * 3600
        XCTAssertEqual(result, expected, accuracy: 1.0, "Identical Watch+Phone intervals should return ~8h, not ~16h")
    }

    // MARK: - Watch + Phone Partial Overlap

    func testWatchAndPhonePartialOverlap_ReturnsMergedDuration() {
        // Watch: 11pm-5am (8h ago to 2h ago = 6 hours)
        // Phone: 10pm-6am (9h ago to 1h ago = 8 hours, overlapping)
        let intervals = [
            makeInterval(hoursAgoStart: 8, hoursAgoEnd: 2, source: .watch, stage: .asleepCore),
            makeInterval(hoursAgoStart: 9, hoursAgoEnd: 1, source: .phone, stage: .asleepCore)
        ]
        let result = SleepDeduplicator.deduplicate(intervals)
        // Watch covers 11pm-5am. Phone covers 10pm-6am. After dedup with Watch priority:
        // Watch 11pm-5am is kept, Phone 10pm-11pm and 5am-6am might remain if not overlapping Watch.
        // Total should be ~8h (the full span covered: 10pm to 6am)
        let expected: TimeInterval = 8 * 3600
        XCTAssertEqual(result, expected, accuracy: 1.0, "Partially overlapping Watch+Phone should return ~8h")
    }

    // MARK: - Non-Sleep Stages Excluded

    func testInBedAndAwakeStages_ExcludedFromDuration() {
        let intervals = [
            makeInterval(hoursAgoStart: 9, hoursAgoEnd: 0, source: .watch, stage: .inBed),
            makeInterval(hoursAgoStart: 8, hoursAgoEnd: 1, source: .watch, stage: .awake),
            makeInterval(hoursAgoStart: 8, hoursAgoEnd: 1, source: .watch, stage: .asleepCore)
        ]
        let result = SleepDeduplicator.deduplicate(intervals)
        let expected: TimeInterval = 7 * 3600 // only asleepCore counts
        XCTAssertEqual(result, expected, accuracy: 1.0, "inBed and awake should be excluded from duration")
    }

    // MARK: - Mixed Sleep Stages

    func testMixedSleepStages_AllCountedAsSleep() {
        // asleepLegacy (1), asleepCore (3), asleepDeep (4), asleepREM (5) all count
        let intervals = [
            makeInterval(hoursAgoStart: 8, hoursAgoEnd: 6, source: .watch, stage: .asleepLegacy),
            makeInterval(hoursAgoStart: 6, hoursAgoEnd: 4, source: .watch, stage: .asleepCore),
            makeInterval(hoursAgoStart: 4, hoursAgoEnd: 2, source: .watch, stage: .asleepDeep),
            makeInterval(hoursAgoStart: 2, hoursAgoEnd: 0, source: .watch, stage: .asleepREM)
        ]
        let result = SleepDeduplicator.deduplicate(intervals)
        let expected: TimeInterval = 8 * 3600 // all 4 stages are 2h each, all count
        XCTAssertEqual(result, expected, accuracy: 1.0, "All sleep stages (legacy, core, deep, REM) should be counted")
    }

    // MARK: - Non-Overlapping Segments

    func testNonOverlappingSegments_SumCorrectly() {
        // Two Watch segments: 11pm-2am and 3am-6am = 3h + 3h = 6h
        let intervals = [
            makeInterval(hoursAgoStart: 8, hoursAgoEnd: 5, source: .watch, stage: .asleepCore),
            makeInterval(hoursAgoStart: 3, hoursAgoEnd: 0, source: .watch, stage: .asleepCore)
        ]
        let result = SleepDeduplicator.deduplicate(intervals)
        let expected: TimeInterval = 6 * 3600
        XCTAssertEqual(result, expected, accuracy: 1.0, "Non-overlapping segments should sum to ~6h")
    }
}
