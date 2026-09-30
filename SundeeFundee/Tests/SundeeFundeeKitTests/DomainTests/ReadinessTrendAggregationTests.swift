import Testing
import Foundation
@testable import SundeeFundeeKit

// MARK: - Test Helpers

private let calendar = Calendar.current

private func makeReadinessRecord(
    date: Date,
    score: Int = 72,
    state: ReadinessState = .maintain,
    confidence: ReadinessConfidence = .medium
) -> DailyReadinessRecord {
    let assessment = ReadinessAssessment(
        assessmentDate: date, state: state,
        totalScore: score, confidence: confidence,
        subScores: [.physiological: score], availableSignals: [.sleep], missingSignals: [.hrv], staleSignals: [],
        positiveReasons: [], cautionReasons: [], modelVersion: "readiness-v1"
    )
    return DailyReadinessRecord(assessment: assessment, timeZone: .gmt)
}

/// A record whose stateRaw is not a valid ReadinessState case, forcing
/// `assessment()` to throw — simulates a corrupted or future-format record.
private func makeUndecodableReadinessRecord(date: Date) throws -> DailyReadinessRecord {
    let valid = makeReadinessRecord(date: date)
    var payload = try JSONSerialization.jsonObject(with: JSONEncoder().encode(valid)) as! [String: Any]
    payload["stateRaw"] = "not-a-real-state"
    let data = try JSONSerialization.data(withJSONObject: payload)
    return try JSONDecoder().decode(DailyReadinessRecord.self, from: data)
}

// MARK: - Readiness Trend Tests

@Suite("Readiness Trend")
struct ReadinessTrendAggregationTests {

    let refDate = makeDate(year: 2026, month: 4, day: 6)

    @Test("empty input returns empty array")
    func emptyInput() {
        let result = ChartDataAggregator.readinessTrend(
            from: [], timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.isEmpty)
    }

    @Test("records are sorted by date ascending")
    func sortedByDate() {
        let records = [
            makeReadinessRecord(date: makeDate(year: 2026, month: 3, day: 1), score: 60),
            makeReadinessRecord(date: makeDate(year: 2026, month: 1, day: 1), score: 80),
            makeReadinessRecord(date: makeDate(year: 2026, month: 2, day: 1), score: 70),
        ]
        let result = ChartDataAggregator.readinessTrend(
            from: records, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.map(\.totalScore) == [80, 70, 60])
    }

    @Test("time range filtering excludes old records")
    func timeRangeFiltering() {
        let records = [
            makeReadinessRecord(date: makeDate(year: 2025, month: 1, day: 1), score: 50),
            makeReadinessRecord(date: makeDate(year: 2026, month: 3, day: 1), score: 75),
            makeReadinessRecord(date: makeDate(year: 2026, month: 4, day: 1), score: 85),
        ]
        let result = ChartDataAggregator.readinessTrend(
            from: records, timeRange: .lastSixMonths, referenceDate: refDate
        )
        // Jan 2025 is more than 6 months before April 2026, so should be filtered out
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.totalScore > 60 })
    }

    @Test("preserves state and confidence")
    func preservesStateAndConfidence() {
        let records = [
            makeReadinessRecord(date: makeDate(year: 2026, month: 3, day: 1), score: 30, state: .rest, confidence: .low),
        ]
        let result = ChartDataAggregator.readinessTrend(
            from: records, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].state == .rest)
        #expect(result[0].confidence == .low)
    }

    @Test("records that fail to decode into an assessment are skipped, not thrown")
    func skipsUndecodableRecords() throws {
        let good = makeReadinessRecord(date: makeDate(year: 2026, month: 3, day: 1), score: 65)
        let bad = try makeUndecodableReadinessRecord(date: makeDate(year: 2026, month: 3, day: 2))

        let result = ChartDataAggregator.readinessTrend(
            from: [good, bad], timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].totalScore == 65)
    }
}
