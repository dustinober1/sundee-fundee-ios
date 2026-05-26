import XCTest
@testable import SundeeFundeeKit

final class DeloadDetectionServiceTests: XCTestCase {
    func testThreeLowRecoveryDaysRecommendDeload() {
        let records = [
            makeRecovery(total: 38, dayOffset: 0),
            makeRecovery(total: 41, dayOffset: 1),
            makeRecovery(total: 33, dayOffset: 2),
            makeRecovery(total: 70, dayOffset: 3),
        ]

        let recommendation = DeloadDetectionService.recommendation(
            recentScores: records,
            recentPainLogs: []
        )

        XCTAssertTrue(recommendation.isRecommended)
    }

    func testHighPainAndPoorSleepRecommendDeload() {
        let recommendation = DeloadDetectionService.recommendation(
            recentScores: [makeRecovery(total: 65, dayOffset: 0)],
            recentPainLogs: [makePain(intensity: 8, dayOffset: 0)],
            recentSleepHours: [5.0, 5.5, 7.2]
        )

        XCTAssertTrue(recommendation.isRecommended)
    }

    func testSingleLowDayAfterStrongScoresDoesNotRecommendDeload() {
        let records = [
            makeRecovery(total: 38, dayOffset: 0),
            makeRecovery(total: 76, dayOffset: 1),
            makeRecovery(total: 81, dayOffset: 2),
            makeRecovery(total: 74, dayOffset: 3),
        ]

        let recommendation = DeloadDetectionService.recommendation(
            recentScores: records,
            recentPainLogs: []
        )

        XCTAssertFalse(recommendation.isRecommended)
    }

    private func makeRecovery(total: Int, dayOffset: Int) -> RecoveryScoreRecord {
        let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
        let iso = ISO8601DateFormatter().string(from: date)
        return RecoveryScoreRecord(
            scoreDate: iso,
            totalScore: total,
            presentInputCount: 5,
            recommendationRaw: TrainingRecommendation.moderate.rawValue
        )
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
