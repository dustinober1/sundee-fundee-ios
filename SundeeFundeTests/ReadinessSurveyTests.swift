import XCTest
@testable import SundeeFundee

final class ReadinessSurveyTests: XCTestCase {

    // MARK: - Survey-only scoring

    func testSurveyOnlyScoreWeightedAverage() {
        let result = ReadinessSurvey.score(
            sleepQuality: 8, stressLevel: 4, sorenessLevel: 3
        )
        // (8*0.4) + ((10-4)*0.3) + ((10-3)*0.3) = 3.2 + 1.8 + 2.1 = 7.1
        XCTAssertEqual(result.score, 7.1, accuracy: 0.01)
    }

    func testSurveyAllOnesGivesLowScore() {
        let result = ReadinessSurvey.score(
            sleepQuality: 1, stressLevel: 10, sorenessLevel: 10
        )
        XCTAssertEqual(result.score, 0.4, accuracy: 0.01)
        XCTAssertEqual(result.tier, .low)
    }

    func testSurveyAllTensGivesHighScore() {
        let result = ReadinessSurvey.score(
            sleepQuality: 10, stressLevel: 1, sorenessLevel: 1
        )
        XCTAssertEqual(result.score, 9.4, accuracy: 0.01)
        XCTAssertEqual(result.tier, .high)
    }

    func testMidRangeGivesNeutralTier() {
        let result = ReadinessSurvey.score(
            sleepQuality: 5, stressLevel: 5, sorenessLevel: 5
        )
        XCTAssertEqual(result.score, 5.0, accuracy: 0.01)
        XCTAssertEqual(result.tier, .neutral)
    }

    // MARK: - HealthKit blending

    func testBlendedScoreWithHealthKit() {
        let surveyResult = ReadinessSurvey.score(
            sleepQuality: 8, stressLevel: 4, sorenessLevel: 3
        )
        let blended = ReadinessSurvey.blendWithHealthKit(
            surveyScore: surveyResult.score, healthKitScore: 5.0
        )
        // 7.1 * 0.7 + 5.0 * 0.3 = 6.47
        XCTAssertEqual(blended.score, 6.47, accuracy: 0.01)
    }

    func testBlendedWithNilHealthKitReturnsSurveyOnly() {
        let surveyResult = ReadinessSurvey.score(
            sleepQuality: 8, stressLevel: 4, sorenessLevel: 3
        )
        let blended = ReadinessSurvey.blendWithHealthKit(
            surveyScore: surveyResult.score, healthKitScore: nil
        )
        XCTAssertEqual(blended.score, surveyResult.score, accuracy: 0.01)
    }

    // MARK: - Tier thresholds

    func testTierFromScoreBoundaries() {
        XCTAssertEqual(ReadinessSurvey.tierFromScore(3.0), .low)
        XCTAssertEqual(ReadinessSurvey.tierFromScore(3.1), .neutral)
        XCTAssertEqual(ReadinessSurvey.tierFromScore(7.9), .neutral)
        XCTAssertEqual(ReadinessSurvey.tierFromScore(8.0), .high)
    }

    // MARK: - Tier display

    func testTierDisplayName() {
        XCTAssertEqual(ReadinessSurvey.tierDisplayName(.low), "Fatigued")
        XCTAssertEqual(ReadinessSurvey.tierDisplayName(.neutral), "Normal")
        XCTAssertEqual(ReadinessSurvey.tierDisplayName(.high), "Prime")
    }

    // MARK: - Persistence

    func testSaveAndLoadTodayScore() {
        let defaults = UserDefaults(suiteName: "test-readiness")!
        defaults.removePersistentDomain(forName: "test-readiness")
        let result = ReadinessResult(score: 7.5, tier: .neutral)
        ReadinessSurvey.saveTodayResult(result, defaults: defaults)
        let loaded = ReadinessSurvey.loadTodayResult(defaults: defaults)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded!.score, 7.5, accuracy: 0.01)
        XCTAssertEqual(loaded?.tier, .neutral)
    }

    func testLoadReturnsNilForDifferentDay() {
        let defaults = UserDefaults(suiteName: "test-readiness-2")!
        defaults.removePersistentDomain(forName: "test-readiness-2")
        defaults.set(7.5, forKey: "readiness-score-2020-01-01")
        defaults.set("neutral", forKey: "readiness-tier-2020-01-01")
        let loaded = ReadinessSurvey.loadTodayResult(defaults: defaults)
        XCTAssertNil(loaded)
    }

    // MARK: - Adjustment banner text

    func testBannerTextLow() {
        let text = ReadinessSurvey.adjustmentBannerText(for: .low)
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("reduced"))
    }

    func testBannerTextHigh() {
        let text = ReadinessSurvey.adjustmentBannerText(for: .high)
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("boosted"))
    }

    func testBannerTextNeutralIsNil() {
        XCTAssertNil(ReadinessSurvey.adjustmentBannerText(for: .neutral))
    }
}
