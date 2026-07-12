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

    func testMissingCurrentDaySampleReturnsNilInsteadOfUsingPriorDay() async throws {
        let client = MockHealthKitClient()
        let yesterday = utcCalendar().date(byAdding: .day, value: -1, to: now)!
        client.setMockHeartRateVariability([
            try XCTUnwrap(MockHealthKitClient.createMockHeartRateVariability(date: yesterday, milliseconds: 50))
        ])
        client.setMockSleepAnalysis([
            HKCategorySample(
                type: try XCTUnwrap(HKObjectType.categoryType(forIdentifier: .sleepAnalysis)),
                value: 3, start: yesterday.addingTimeInterval(-3600), end: yesterday, metadata: nil
            )
        ])

        let result = await HealthReadinessProvider(healthClient: client).load(
            assessmentDate: now, calendar: utcCalendar()
        )

        XCTAssertNil(result.hrvMilliseconds)
        XCTAssertNil(result.sleepHours)
    }

    func testCrossMidnightOverlappingSleepIsSplitAndDeduplicatedPerDay() async throws {
        let client = MockHealthKitClient()
        let calendar = utcCalendar()
        let currentDay = calendar.startOfDay(for: now)
        let firstStart = currentDay.addingTimeInterval(-3600)
        let firstEnd = currentDay.addingTimeInterval(3600)
        let secondStart = currentDay.addingTimeInterval(1800)
        let secondEnd = currentDay.addingTimeInterval(7200)
        let sleepType = try XCTUnwrap(HKObjectType.categoryType(forIdentifier: .sleepAnalysis))
        client.setMockSleepAnalysis([
            HKCategorySample(type: sleepType, value: 3, start: firstStart, end: firstEnd, metadata: nil),
            HKCategorySample(type: sleepType, value: 3, start: secondStart, end: secondEnd, metadata: nil)
        ])

        let result = await HealthReadinessProvider(healthClient: client).load(
            assessmentDate: now, calendar: calendar
        )

        XCTAssertEqual(result.sleepHours?.currentValue ?? -1, 2, accuracy: 0.001)
        XCTAssertEqual(result.sleepHours?.baselineValues.first ?? -1, 1, accuracy: 0.001)
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
