import XCTest
@testable import SundeeFundeeKit

final class RecoveryExplanationServiceTests: XCTestCase {
    func testTopExplanationsPrioritizeLowestSignals() {
        let score = RecoveryScore(
            total: 46,
            recommendation: .moderate,
            subScores: [
                .sleep: 18,
                .trainingLoad: 25,
                .pain: 30,
                .hrv: 82,
                .cyclePhase: 75,
            ],
            presentInputCount: 5,
            totalInputCount: 5,
            explanations: [
                .sleep: "Sleep was short last night.",
                .trainingLoad: "Recent training load is elevated.",
                .pain: "Pain check-in is higher than normal.",
                .hrv: "HRV looks stable.",
                .cyclePhase: "Cycle context is stable.",
            ]
        )

        let explanations = RecoveryExplanationService.topExplanations(from: score)
        let texts = explanations.map(\.text).joined(separator: " | ")

        XCTAssertTrue(texts.contains("Sleep was short"))
        XCTAssertTrue(texts.contains("training load is elevated"))
        XCTAssertTrue(texts.contains("Pain check-in is higher"))
    }

    func testMissingScoreReturnsActionableFallback() {
        let explanations = RecoveryExplanationService.topExplanations(from: nil)
        XCTAssertEqual(explanations.count, 1)
        XCTAssertTrue(explanations[0].text.localizedCaseInsensitiveContains("connect sleep or hrv"))
    }

    func testExplanationsSanitizeRawInternalErrors() {
        let score = RecoveryScore(
            total: 50,
            recommendation: .moderate,
            subScores: [.sleep: 35, .hrv: 40, .pain: 55],
            presentInputCount: 3,
            totalInputCount: 5,
            explanations: [
                .sleep: "HKErrorDomain code -1",
                .hrv: "HealthKit error domain data unavailable",
                .pain: "Pain context from today is moderate.",
            ]
        )

        let explanations = RecoveryExplanationService.topExplanations(from: score)
        let combined = explanations.map(\.text).joined(separator: " ")
        XCTAssertFalse(combined.localizedCaseInsensitiveContains("hkerrordomain"))
        XCTAssertFalse(combined.localizedCaseInsensitiveContains("healthkit error"))
    }
}
