import XCTest
@testable import SundeeFundeeKit

final class ReadinessScenarioTests: XCTestCase {
    func testHighSleepAndEnergyProducePositiveReasonsWhileHighPainAddsCaution() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let context = DailyTrainingContext(
            assessmentDate: now,
            timeZoneIdentifier: "America/New_York",
            physiological: PhysiologicalReadinessSnapshot(
                sleepHours: ReadinessMetricSnapshot(currentValue: 8, baselineValues: Array(repeating: 8, count: 14), observedAt: now)
            ),
            subjective: SubjectiveReadinessSnapshot(energy: 9),
            training: .empty,
            pain: PainReadinessSnapshot(intensity: 8, painType: .sharp, locationIDs: ["knee"], observedAt: now),
            cyclePhase: nil,
            cycleConfidence: nil
        )

        let result = try XCTUnwrap(ReadinessAssessmentService.assess(context))
        XCTAssertTrue(result.positiveReasons.contains(.goodSleep))
        XCTAssertTrue(result.positiveReasons.contains(.highEnergy))
        XCTAssertTrue(result.cautionReasons.contains(.highPain))
        XCTAssertEqual(result.state, .recover)
    }
}
