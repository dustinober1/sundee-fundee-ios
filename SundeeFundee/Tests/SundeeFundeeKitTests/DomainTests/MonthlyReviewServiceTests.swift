import XCTest
@testable import SundeeFundeeKit

final class MonthlyReviewServiceTests: XCTestCase {

    // MARK: - Helpers

    private let calendar = Calendar(identifier: .gregorian)

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components) ?? Date()
    }

    private func makeWorkout(
        on date: Date,
        duration: Int = 45,
        isComplete: Bool = true
    ) -> Workout {
        Workout(
            id: UUID().uuidString,
            date: date,
            name: "Test Workout",
            exercises: [],
            duration: duration,
            completedAt: isComplete ? date : nil
        )
    }

    private func makeEffortLog(
        on date: Date,
        rpe: Int,
        workoutID: String = UUID().uuidString
    ) -> WorkoutEffortLog {
        WorkoutEffortLog(
            workoutID: workoutID,
            exerciseName: "Squat",
            setID: nil,
            rpe: rpe,
            dateCreated: date
        )
    }

    private func makeRecoveryScore(
        on date: Date,
        total: Int
    ) -> RecoveryScoreRecord {
        let iso = ISO8601DateFormatter().string(from: date)
        return RecoveryScoreRecord(
            scoreDate: iso,
            totalScore: total,
            presentInputCount: 5,
            recommendationRaw: TrainingRecommendation.moderate.rawValue
        )
    }

    private func makePainLog(on date: Date, intensity: Int) -> DailyPainLog {
        DailyPainLog(
            id: UUID().uuidString,
            locationIds: "knee_left",
            intensity: intensity,
            painType: .aching,
            date: date
        )
    }

    // MARK: - Tests

    func testMonthWithWorkoutsAndPRsSurfacesConsistencyAndStrengthWins() {
        let jan2026 = makeDate(year: 2026, month: 1, day: 15)

        // 8 completed workouts in January 2026
        let workouts = (1...8).map { day -> Workout in
            makeWorkout(on: makeDate(year: 2026, month: 1, day: day))
        }

        // 2 high-RPE effort logs (rpe >= 8) as PR proxy
        let effortLogs = [
            makeEffortLog(on: makeDate(year: 2026, month: 1, day: 5), rpe: 9),
            makeEffortLog(on: makeDate(year: 2026, month: 1, day: 12), rpe: 8),
            makeEffortLog(on: makeDate(year: 2026, month: 1, day: 20), rpe: 6),
        ]

        let review = MonthlyReviewService.build(
            month: jan2026,
            workouts: workouts,
            recoveryScores: [],
            painLogs: [],
            effortLogs: effortLogs,
            symptomLogs: nil
        )

        // Should have a consistency win mentioning the workout count
        let hasConsistencyWin = review.topWins.contains { $0.contains("8") && $0.lowercased().contains("workout") }
        XCTAssertTrue(hasConsistencyWin, "Expected a consistency win mentioning 8 workouts, got: \(review.topWins)")

        // Should have a strength win mentioning personal records or high-RPE sessions
        let hasStrengthWin = review.topWins.contains { $0.lowercased().contains("personal record") || $0.lowercased().contains("high-effort") || $0.lowercased().contains("pr") }
        XCTAssertTrue(hasStrengthWin, "Expected a strength/personal record win, got: \(review.topWins)")
    }

    func testMissingRecoveryDataProducesConnectMoreDataSuggestion() {
        let feb2026 = makeDate(year: 2026, month: 2, day: 10)

        let workouts = [
            makeWorkout(on: makeDate(year: 2026, month: 2, day: 3)),
            makeWorkout(on: makeDate(year: 2026, month: 2, day: 7)),
        ]

        // No recovery scores, no symptom logs — should produce a "connect more data" suggestion
        let review = MonthlyReviewService.build(
            month: feb2026,
            workouts: workouts,
            recoveryScores: [],
            painLogs: [],
            effortLogs: [],
            symptomLogs: nil
        )

        let hasDataSuggestion = review.nextMonthSuggestions.contains { suggestion in
            suggestion.lowercased().contains("recovery") || suggestion.lowercased().contains("symptom")
        }
        XCTAssertTrue(hasDataSuggestion, "Expected a suggestion to connect more data (recovery or symptoms), got: \(review.nextMonthSuggestions)")
    }

    func testMonthTitleFormatsCorrectly() {
        let march2026 = makeDate(year: 2026, month: 3, day: 1)

        let review = MonthlyReviewService.build(
            month: march2026,
            workouts: [],
            recoveryScores: [],
            painLogs: [],
            effortLogs: [],
            symptomLogs: nil
        )

        XCTAssertEqual(review.monthTitle, "March 2026")
    }

    func testEmptyMonthReturnsZeroCountsAndEncouragingSuggestions() {
        let april2026 = makeDate(year: 2026, month: 4, day: 15)

        // A workout from a different month (should be filtered out)
        let workouts = [
            makeWorkout(on: makeDate(year: 2026, month: 3, day: 28)),
        ]

        let review = MonthlyReviewService.build(
            month: april2026,
            workouts: workouts,
            recoveryScores: [],
            painLogs: [],
            effortLogs: [],
            symptomLogs: nil
        )

        XCTAssertEqual(review.workoutCount, 0, "Expected 0 workouts for an empty month")
        XCTAssertEqual(review.personalRecordCount, 0, "Expected 0 PRs for an empty month")
        XCTAssertTrue(review.topWins.isEmpty, "Expected no wins for an empty month, got: \(review.topWins)")
        XCTAssertFalse(review.nextMonthSuggestions.isEmpty, "Expected encouraging suggestions for an empty month")
    }

    func testOnlyFiltersDataWithinTargetMonth() {
        let jan2026 = makeDate(year: 2026, month: 1, day: 15)

        let workouts = [
            makeWorkout(on: makeDate(year: 2025, month: 12, day: 28)),
            makeWorkout(on: makeDate(year: 2026, month: 1, day: 5)),
            makeWorkout(on: makeDate(year: 2026, month: 1, day: 20)),
            makeWorkout(on: makeDate(year: 2026, month: 2, day: 3)),
        ]

        let review = MonthlyReviewService.build(
            month: jan2026,
            workouts: workouts,
            recoveryScores: [],
            painLogs: [],
            effortLogs: [],
            symptomLogs: nil
        )

        XCTAssertEqual(review.workoutCount, 2, "Expected only 2 workouts from January 2026")
    }

    func testRichDataProducesGoalSuggestions() {
        let may2026 = makeDate(year: 2026, month: 5, day: 15)

        let workouts = (1...10).map { day -> Workout in
            makeWorkout(on: makeDate(year: 2026, month: 5, day: day * 2))
        }

        let recoveryScores = (1...10).map { day -> RecoveryScoreRecord in
            makeRecoveryScore(on: makeDate(year: 2026, month: 5, day: day * 2), total: 70)
        }

        let painLogs = (1...5).map { day -> DailyPainLog in
            makePainLog(on: makeDate(year: 2026, month: 5, day: day * 4), intensity: 3)
        }

        let effortLogs = (1...10).map { day -> WorkoutEffortLog in
            makeEffortLog(on: makeDate(year: 2026, month: 5, day: day * 2), rpe: 7)
        }

        let review = MonthlyReviewService.build(
            month: may2026,
            workouts: workouts,
            recoveryScores: recoveryScores,
            painLogs: painLogs,
            effortLogs: effortLogs,
            symptomLogs: nil
        )

        // With rich data, should have suggestions that reference consistency or goals
        let hasGoalSuggestion = review.nextMonthSuggestions.contains { suggestion in
            suggestion.lowercased().contains("consistency") || suggestion.lowercased().contains("match") || suggestion.lowercased().contains("goal")
        }
        XCTAssertTrue(hasGoalSuggestion, "Expected goal-oriented suggestions with rich data, got: \(review.nextMonthSuggestions)")
    }
}
#endif
