import XCTest
@testable import SundeeFundeeKit

final class ReadinessModelsTests: XCTestCase {
    func testStateBandsAreStable() {
        XCTAssertEqual(ReadinessState.from(score: 100), .ready)
        XCTAssertEqual(ReadinessState.from(score: 80), .ready)
        XCTAssertEqual(ReadinessState.from(score: 79), .maintain)
        XCTAssertEqual(ReadinessState.from(score: 60), .maintain)
        XCTAssertEqual(ReadinessState.from(score: 59), .recover)
        XCTAssertEqual(ReadinessState.from(score: 35), .recover)
        XCTAssertEqual(ReadinessState.from(score: 34), .rest)
        XCTAssertEqual(ReadinessState.from(score: 0), .rest)
    }

    func testStricterStateKeepsTheMoreCautiousValue() {
        XCTAssertEqual(ReadinessState.stricter(.ready, .recover), .recover)
        XCTAssertEqual(ReadinessState.stricter(.rest, .maintain), .rest)
    }

    func testContextCarriesCycleWithoutMakingItAScoreSignal() {
        let context = DailyTrainingContext(
            assessmentDate: Date(timeIntervalSince1970: 1_700_000_000),
            timeZoneIdentifier: "America/New_York",
            physiological: .empty,
            subjective: .empty,
            training: .empty,
            pain: nil,
            cyclePhase: .luteal,
            cycleConfidence: 0.8
        )

        XCTAssertEqual(context.cyclePhase, .luteal)
        XCTAssertFalse(ReadinessSignalID.allCases.contains(.cyclePhase))
    }
}
