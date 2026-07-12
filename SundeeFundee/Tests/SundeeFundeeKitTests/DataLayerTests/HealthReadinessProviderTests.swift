import XCTest
import HealthKit
@testable import SundeeFundeeKit

final class HealthReadinessProviderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testFifteenDailyHRVSamplesProduceCurrentPlusFourteenBaselineDays() async throws {
        let client = MockHealthKitClient()
        let calendar = utcCalendar()
        let dates = (0..<15).map { calendar.date(byAdding: .day, value: -$0, to: now)! }
        client.setMockHeartRateVariability(dates.compactMap {
            MockHealthKitClient.createMockHeartRateVariability(date: $0, milliseconds: 50)
        })

        let result = await HealthReadinessProvider(healthClient: client).load(assessmentDate: now, calendar: calendar)

        XCTAssertEqual(result.hrvMilliseconds?.currentValue, 50)
        XCTAssertEqual(result.hrvMilliseconds?.baselineValues.count, 14)
    }

    func testRestingHeartRateUsesBeatsPerMinute() async throws {
        let client = MockHealthKitClient()
        client.setMockRestingHeartRate([
            try XCTUnwrap(MockHealthKitClient.createMockRestingHeartRate(date: now, beatsPerMinute: 61))
        ])

        let result = await HealthReadinessProvider(healthClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )

        XCTAssertEqual(result.restingHeartRateBPM?.currentValue, 61)
    }

    func testOverlappingSleepSamplesAreCountedOnce() async throws {
        let client = MockHealthKitClient()
        let eightHoursAgo = now.addingTimeInterval(-8 * 3600)
        let sevenHoursAgo = now.addingTimeInterval(-7 * 3600)
        let sleepType = try XCTUnwrap(HKObjectType.categoryType(forIdentifier: .sleepAnalysis))
        client.setMockSleepAnalysis([
            HKCategorySample(type: sleepType, value: 3, start: eightHoursAgo, end: now, metadata: nil),
            HKCategorySample(type: sleepType, value: 3, start: sevenHoursAgo, end: now, metadata: nil)
        ])

        let result = await HealthReadinessProvider(healthClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )

        XCTAssertEqual(result.sleepHours?.currentValue ?? -1, 8, accuracy: 0.001)
    }

    func testQueryFailureReturnsEmptySnapshot() async {
        let client = MockHealthKitClient()
        client.shouldFailQueries = true

        let result = await HealthReadinessProvider(healthClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )

        XCTAssertEqual(result, .empty)
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }
}
