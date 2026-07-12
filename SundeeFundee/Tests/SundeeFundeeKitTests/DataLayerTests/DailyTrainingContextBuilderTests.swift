import XCTest
@testable import SundeeFundeeKit

final class DailyTrainingContextBuilderTests: XCTestCase {
    func testBuilderCallsBothProvidersAndCombinesTheirValues() async {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let health = StubHealthProvider(value: PhysiologicalReadinessSnapshot(
            sleepHours: ReadinessMetricSnapshot(currentValue: 8, baselineValues: [], observedAt: date)
        ))
        let history = StubHistoryProvider(value: HistoryReadinessSnapshot(
            subjective: SubjectiveReadinessSnapshot(energy: 8),
            training: TrainingReadinessSnapshot(weeklyLoadRatio: 1),
            pain: nil
        ))
        let builder = DailyTrainingContextBuilder(healthProvider: health, historyProvider: history)
        let result = await builder.build(
            assessmentDate: date,
            timeZone: TimeZone(identifier: "America/New_York")!,
            cyclePhase: .luteal,
            cycleConfidence: 0.8
        )

        let healthCalls = await health.calls()
        let historyCalls = await history.calls()
        XCTAssertEqual(healthCalls, 1)
        XCTAssertEqual(historyCalls, 1)
        XCTAssertEqual(result.physiological.sleepHours?.currentValue, 8)
        XCTAssertEqual(result.subjective.energy, 8)
        XCTAssertEqual(result.training.weeklyLoadRatio, 1)
        XCTAssertEqual(result.cyclePhase, .luteal)
        XCTAssertEqual(result.cycleConfidence, 0.8)
        XCTAssertEqual(result.assessmentDate, date)
        XCTAssertEqual(result.timeZoneIdentifier, "America/New_York")
    }
}

private actor StubHealthProvider: HealthReadinessProviding {
    private let value: PhysiologicalReadinessSnapshot
    private var callCount = 0

    init(value: PhysiologicalReadinessSnapshot) { self.value = value }

    func load(assessmentDate: Date, calendar: Calendar) async -> PhysiologicalReadinessSnapshot {
        callCount += 1
        return value
    }

    func calls() -> Int { callCount }
}

private actor StubHistoryProvider: HistoryReadinessProviding {
    private let value: HistoryReadinessSnapshot
    private var callCount = 0

    init(value: HistoryReadinessSnapshot) { self.value = value }

    func load(assessmentDate: Date, calendar: Calendar) async -> HistoryReadinessSnapshot {
        callCount += 1
        return value
    }

    func calls() -> Int { callCount }
}
