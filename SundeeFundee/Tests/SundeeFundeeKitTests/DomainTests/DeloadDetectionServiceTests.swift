import XCTest
@testable import SundeeFundeeKit

final class DeloadDetectionServiceTests: XCTestCase {
    func testTwoHighPainDaysRecommendDeload() {
        let painLogs = [
            makePain(intensity: 8, dayOffset: 0),
            makePain(intensity: 7, dayOffset: 1),
            makePain(intensity: 3, dayOffset: 2),
        ]

        let recommendation = DeloadDetectionService.recommendation(
            recentPainLogs: painLogs
        )

        XCTAssertTrue(recommendation.isRecommended)
    }

    func testHighPainAndPoorSleepRecommendDeload() {
        let recommendation = DeloadDetectionService.recommendation(
            recentPainLogs: [makePain(intensity: 8, dayOffset: 0)],
            recentSleepHours: [5.0, 5.5, 7.2]
        )

        XCTAssertTrue(recommendation.isRecommended)
    }

    func testSingleHighPainDayDoesNotRecommendDeload() {
        let recommendation = DeloadDetectionService.recommendation(
            recentPainLogs: [makePain(intensity: 8, dayOffset: 0)]
        )

        XCTAssertFalse(recommendation.isRecommended)
    }

    private func makePain(intensity: Int, dayOffset: Int) -> DailyPainLog {
        let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
        return DailyPainLog(
            id: UUID().uuidString,
            locationIds: "knee_left",
            intensity: intensity,
            painType: .aching,
            date: date
        )
    }
}
