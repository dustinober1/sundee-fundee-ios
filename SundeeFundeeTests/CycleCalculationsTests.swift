import XCTest
@testable import SundeeFundee

final class CycleCalculationsTests: XCTestCase {

    private func makeSettings(
        cycleLength: Int = 28,
        periodLength: Int = 5,
        lutealLength: Int = 14
    ) -> CycleSettings {
        CycleSettings(
            userId: "test-user",
            averageCycleLength: cycleLength,
            averagePeriodLength: periodLength,
            lutealPhaseLength: lutealLength
        )
    }

    // MARK: - getPhaseBoundaries

    func testGetPhaseBoundaries_default28DayCycle() {
        let settings = makeSettings()
        let boundaries = CycleCalculations.getPhaseBoundaries(settings: settings)

        XCTAssertEqual(boundaries[.menstrual]?.start, 1)
        XCTAssertEqual(boundaries[.menstrual]?.end, 5)
        XCTAssertEqual(boundaries[.follicular]?.start, 6)
        XCTAssertNotNil(boundaries[.ovulation])
        XCTAssertNotNil(boundaries[.luteal])
        XCTAssertEqual(boundaries[.luteal]?.end, 28)
    }

    func testGetPhaseBoundaries_allPhasesContiguous() {
        let settings = makeSettings()
        let boundaries = CycleCalculations.getPhaseBoundaries(settings: settings)

        let phases: [CyclePhase] = [.menstrual, .follicular, .ovulation, .luteal]
        for i in 0..<(phases.count - 1) {
            let current = boundaries[phases[i]]!
            let next = boundaries[phases[i + 1]]!
            XCTAssertEqual(current.end + 1, next.start,
                           "\(phases[i]) end + 1 should equal \(phases[i + 1]) start")
        }
    }

    // MARK: - getPhaseRecommendation

    func testGetPhaseRecommendation_menstrual() {
        let rec = CycleCalculations.getPhaseRecommendation(phase: .menstrual)
        XCTAssertEqual(rec.intensityRecommendation, "low")
        XCTAssertFalse(rec.exercisesToAvoid.isEmpty)
    }

    func testGetPhaseRecommendation_ovulation() {
        let rec = CycleCalculations.getPhaseRecommendation(phase: .ovulation)
        XCTAssertEqual(rec.intensityRecommendation, "peak")
        XCTAssertTrue(rec.exercisesToAvoid.isEmpty)
    }

    func testGetPhaseRecommendation_follicular() {
        let rec = CycleCalculations.getPhaseRecommendation(phase: .follicular)
        XCTAssertEqual(rec.intensityRecommendation, "moderate")
    }

    func testGetPhaseRecommendation_luteal() {
        let rec = CycleCalculations.getPhaseRecommendation(phase: .luteal)
        XCTAssertEqual(rec.intensityRecommendation, "moderate")
        XCTAssertFalse(rec.exercisesToAvoid.isEmpty)
    }

    // MARK: - calculateCycleStatus

    func testCalculateCycleStatus_emptyLogs() {
        let settings = makeSettings()
        let result = CycleCalculations.calculateCycleStatus(
            periodLogs: [], settings: settings
        )
        XCTAssertNil(result)
    }

    func testCalculateCycleStatus_duringPeriod() {
        let settings = makeSettings()
        let today = Date.now
        let periodStart = Calendar.current.date(byAdding: .day, value: -2, to: today)!

        let log = PeriodLog(userId: "test", startDate: periodStart)
        let result = CycleCalculations.calculateCycleStatus(
            periodLogs: [log], settings: settings, referenceDate: today
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.currentPhase, .menstrual)
        XCTAssertEqual(result?.cycleDay, 3)
    }

    // MARK: - All phases have recommendations

    func testAllPhasesHaveRecommendations() {
        for phase in CyclePhase.allCases {
            let rec = CycleCalculations.getPhaseRecommendation(phase: phase)
            XCTAssertFalse(rec.title.isEmpty, "\(phase) should have a title")
            XCTAssertFalse(rec.description.isEmpty, "\(phase) should have a description")
            XCTAssertFalse(rec.trainingFocus.isEmpty, "\(phase) should have training focus")
        }
    }
}
