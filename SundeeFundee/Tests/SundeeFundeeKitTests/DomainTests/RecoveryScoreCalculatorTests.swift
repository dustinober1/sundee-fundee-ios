import XCTest
@testable import SundeeFundeeKit

final class RecoveryScoreCalculatorTests: XCTestCase {

    // MARK: - Helpers

    private func makeInputs(
        hrvMilliseconds: Double? = nil,
        sleepDurationHours: Double? = nil,
        weeklySummaries: [WeeklyLoadAnalyzer.WeeklySummary]? = nil,
        cyclePhase: CyclePhase? = nil,
        painIntensity: Int? = nil
    ) -> RecoveryScoreInputs {
        RecoveryScoreInputs(
            hrvMilliseconds: hrvMilliseconds,
            sleepDurationHours: sleepDurationHours,
            weeklySummaries: weeklySummaries,
            cyclePhase: cyclePhase,
            painIntensity: painIntensity
        )
    }

    private func makeWeeklySummary(
        workoutCount: Int,
        weeksAgo: Int
    ) -> WeeklyLoadAnalyzer.WeeklySummary {
        WeeklyLoadAnalyzer.WeeklySummary(
            weekStartDate: Calendar.current.date(
                byAdding: .weekOfYear, value: -weeksAgo, to: Date()
            )!,
            workoutCount: workoutCount,
            totalMinutes: workoutCount * 60,
            muscleGroupsHit: ["Lower", "Upper Push", "Upper Pull"],
            exerciseNames: []
        )
    }

    // MARK: - All Inputs Present

    func testCalculate_AllInputsPresent_ReturnsScoreInValidRange() {
        let summaries = [
            makeWeeklySummary(workoutCount: 4, weeksAgo: 0),
            makeWeeklySummary(workoutCount: 3, weeksAgo: 1),
            makeWeeklySummary(workoutCount: 4, weeksAgo: 2),
            makeWeeklySummary(workoutCount: 3, weeksAgo: 3)
        ]
        let inputs = makeInputs(
            hrvMilliseconds: 55.0,
            sleepDurationHours: 7.5,
            weeklySummaries: summaries,
            cyclePhase: .follicular,
            painIntensity: 2
        )

        let result = RecoveryScoreCalculator.calculate(inputs: inputs)

        XCTAssertNotNil(result, "Should return non-nil score when all inputs present")
        if let score = result {
            XCTAssertGreaterThanOrEqual(score.total, 0, "Total should be >= 0")
            XCTAssertLessThanOrEqual(score.total, 100, "Total should be <= 100")
            XCTAssertEqual(score.presentInputCount, 5, "Should have 5 present inputs")
            XCTAssertEqual(score.totalInputCount, 5, "Total input count should be 5")
        }
    }

    // MARK: - All Nil Inputs

    func testCalculate_AllNilInputs_ReturnsNil() {
        let inputs = makeInputs()

        let result = RecoveryScoreCalculator.calculate(inputs: inputs)

        XCTAssertNil(result, "Should return nil when all inputs are nil")
    }

    // MARK: - Single Input: HRV Only

    func testCalculate_HRVOnly_ReturnsNonNilScore() {
        let inputs = makeInputs(hrvMilliseconds: 50.0)

        let result = RecoveryScoreCalculator.calculate(inputs: inputs)

        XCTAssertNotNil(result, "Should return non-nil score with HRV only")
        if let score = result {
            XCTAssertEqual(score.presentInputCount, 1)
            XCTAssertNotNil(score.subScores[.hrv], "Should have HRV sub-score")
            XCTAssertGreaterThanOrEqual(score.total, 0)
            XCTAssertLessThanOrEqual(score.total, 100)
        }
    }

    // MARK: - Single Input: Sleep Only

    func testCalculate_SleepOnly_ReturnsNonNilScore() {
        let inputs = makeInputs(sleepDurationHours: 7.0)

        let result = RecoveryScoreCalculator.calculate(inputs: inputs)

        XCTAssertNotNil(result, "Should return non-nil score with sleep only")
        if let score = result {
            XCTAssertEqual(score.presentInputCount, 1)
            XCTAssertNotNil(score.subScores[.sleep], "Should have sleep sub-score")
        }
    }

    // MARK: - HRV Phase Normalization

    func testCalculate_LutealHRV_NormalizesHigherThanFollicular() {
        // Luteal phase suppresses HRV 10-20%; normalizer should compensate
        // so 42ms in luteal should score higher than 42ms in follicular
        let lutealInputs = makeInputs(
            hrvMilliseconds: 42.0,
            cyclePhase: .luteal
        )
        let follicularInputs = makeInputs(
            hrvMilliseconds: 42.0,
            cyclePhase: .follicular
        )

        let lutealScore = RecoveryScoreCalculator.calculate(inputs: lutealInputs)
        let follicularScore = RecoveryScoreCalculator.calculate(inputs: follicularInputs)

        XCTAssertNotNil(lutealScore, "Luteal score should not be nil")
        XCTAssertNotNil(follicularScore, "Follicular score should not be nil")

        if let luteal = lutealScore, let follicular = follicularScore {
            XCTAssertGreaterThan(
                luteal.subScores[.hrv] ?? 0,
                follicular.subScores[.hrv] ?? 0,
                "Luteal 42ms should normalize higher than follicular 42ms"
            )
        }
    }

    // MARK: - Partial Inputs: 2 of 5

    func testCalculate_TwoInputs_ReturnsPartialScoreWithCorrectCount() {
        let inputs = makeInputs(
            hrvMilliseconds: 50.0,
            sleepDurationHours: 7.0
        )

        let result = RecoveryScoreCalculator.calculate(inputs: inputs)

        XCTAssertNotNil(result, "Should return non-nil score with 2 inputs")
        if let score = result {
            XCTAssertEqual(score.presentInputCount, 2, "Should report 2 present inputs")
            XCTAssertEqual(score.totalInputCount, 5, "Total should still be 5")
            XCTAssertGreaterThanOrEqual(score.total, 0)
            XCTAssertLessThanOrEqual(score.total, 100)
        }
    }

    // MARK: - Recommendation Thresholds

    func testCalculate_HighScore_ReturnsPushDay() {
        // All good inputs: high HRV, good sleep, moderate load, follicular, low pain
        let summaries = [
            makeWeeklySummary(workoutCount: 3, weeksAgo: 0),
            makeWeeklySummary(workoutCount: 3, weeksAgo: 1),
            makeWeeklySummary(workoutCount: 3, weeksAgo: 2),
            makeWeeklySummary(workoutCount: 3, weeksAgo: 3)
        ]
        let inputs = makeInputs(
            hrvMilliseconds: 80.0,
            sleepDurationHours: 8.5,
            weeklySummaries: summaries,
            cyclePhase: .follicular,
            painIntensity: 1
        )

        let result = RecoveryScoreCalculator.calculate(inputs: inputs)

        XCTAssertNotNil(result)
        if let score = result {
            XCTAssertGreaterThanOrEqual(score.total, 70, "Good inputs should score >= 70")
            XCTAssertEqual(score.recommendation, .pushDay, "Score >= 70 should be pushDay")
        }
    }

    func testCalculate_LowScore_ReturnsRestDay() {
        // Bad inputs: low HRV, poor sleep, high load, menstrual, high pain
        let summaries = [
            makeWeeklySummary(workoutCount: 7, weeksAgo: 0),
            makeWeeklySummary(workoutCount: 3, weeksAgo: 1),
            makeWeeklySummary(workoutCount: 3, weeksAgo: 2),
            makeWeeklySummary(workoutCount: 3, weeksAgo: 3)
        ]
        let inputs = makeInputs(
            hrvMilliseconds: 15.0,
            sleepDurationHours: 4.0,
            weeklySummaries: summaries,
            cyclePhase: .menstrual,
            painIntensity: 9
        )

        let result = RecoveryScoreCalculator.calculate(inputs: inputs)

        XCTAssertNotNil(result)
        if let score = result {
            XCTAssertLessThan(score.total, 40, "Bad inputs should score < 40")
            XCTAssertEqual(score.recommendation, .restDay, "Score < 40 should be restDay")
        }
    }

    // MARK: - Pain Scoring

    func testCalculate_PainIntensity1_ScoresHigherThan10() {
        let lowPainInputs = makeInputs(painIntensity: 1)
        let highPainInputs = makeInputs(painIntensity: 10)

        let lowPainScore = RecoveryScoreCalculator.calculate(inputs: lowPainInputs)
        let highPainScore = RecoveryScoreCalculator.calculate(inputs: highPainInputs)

        XCTAssertNotNil(lowPainScore)
        XCTAssertNotNil(highPainScore)

        if let low = lowPainScore, let high = highPainScore {
            XCTAssertGreaterThan(
                low.subScores[.pain] ?? 0,
                high.subScores[.pain] ?? 0,
                "Pain intensity 1 should score higher than intensity 10"
            )
            XCTAssertEqual(low.subScores[.pain], 100, "Pain intensity 1 should score 100")
            XCTAssertLessThanOrEqual(high.subScores[.pain] ?? 0, 10, "Pain intensity 10 should score very low")
        }
    }

    // MARK: - Sleep Scoring

    func testCalculate_Sleep8Hours_ScoresHigherThan5Hours() {
        let goodSleepInputs = makeInputs(sleepDurationHours: 8.0)
        let poorSleepInputs = makeInputs(sleepDurationHours: 5.0)

        let goodScore = RecoveryScoreCalculator.calculate(inputs: goodSleepInputs)
        let poorScore = RecoveryScoreCalculator.calculate(inputs: poorSleepInputs)

        XCTAssertNotNil(goodScore)
        XCTAssertNotNil(poorScore)

        if let good = goodScore, let poor = poorScore {
            XCTAssertGreaterThan(
                good.subScores[.sleep] ?? 0,
                poor.subScores[.sleep] ?? 0,
                "8h sleep should score higher than 5h sleep"
            )
        }
    }

    // MARK: - Training Load Scoring (ACWR)

    func testCalculate_HighACWR_ScoresLowerThanBalanced() {
        // ACWR > 1.5 (overreaching): current week 7 workouts, prior avg 4
        let overreachingSummaries = [
            makeWeeklySummary(workoutCount: 7, weeksAgo: 0),
            makeWeeklySummary(workoutCount: 4, weeksAgo: 1),
            makeWeeklySummary(workoutCount: 4, weeksAgo: 2),
            makeWeeklySummary(workoutCount: 4, weeksAgo: 3)
        ]
        // ACWR ~1.0 (balanced): current week 4 workouts, prior avg 4
        let balancedSummaries = [
            makeWeeklySummary(workoutCount: 4, weeksAgo: 0),
            makeWeeklySummary(workoutCount: 4, weeksAgo: 1),
            makeWeeklySummary(workoutCount: 4, weeksAgo: 2),
            makeWeeklySummary(workoutCount: 4, weeksAgo: 3)
        ]

        let overreachingInputs = makeInputs(weeklySummaries: overreachingSummaries)
        let balancedInputs = makeInputs(weeklySummaries: balancedSummaries)

        let overreachingScore = RecoveryScoreCalculator.calculate(inputs: overreachingInputs)
        let balancedScore = RecoveryScoreCalculator.calculate(inputs: balancedInputs)

        XCTAssertNotNil(overreachingScore)
        XCTAssertNotNil(balancedScore)

        if let overreaching = overreachingScore, let balanced = balancedScore {
            XCTAssertLessThan(
                overreaching.subScores[.trainingLoad] ?? 0,
                balanced.subScores[.trainingLoad] ?? 0,
                "ACWR > 1.5 should score lower than ACWR ~1.0"
            )
        }
    }
}
