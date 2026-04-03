import XCTest
@testable import SundeeFundeeKit

final class CycleCalculationsTests: XCTestCase {

    let defaultSettings = CycleSettings(
        averageCycleLengthDays: 28,
        averagePeriodLengthDays: 5,
        lutealPhaseLengthDays: 14
    )

    // MARK: - getPhaseBoundaries

    func testPhaseBoundaries_28DayCycle() {
        let b = getPhaseBoundaries(settings: defaultSettings)
        XCTAssertEqual(b[.menstrual]?.start, 1)
        XCTAssertEqual(b[.menstrual]?.end, 5)
        XCTAssertEqual(b[.follicular]?.start, 6)
        XCTAssertEqual(b[.luteal]?.end, 28)
    }

    func testPhaseBoundaries_OvulationBeforeLuteal() {
        let b = getPhaseBoundaries(settings: defaultSettings)
        XCTAssertLessThan(b[.ovulation]!.end, b[.luteal]!.start)
    }

    func testPhaseBoundaries_FollicularStartsAfterMenstrual() {
        let b = getPhaseBoundaries(settings: defaultSettings)
        XCTAssertEqual(b[.follicular]!.start, b[.menstrual]!.end + 1)
    }

    func testPhaseBoundaries_LutealEndsAtCycleLength() {
        let b = getPhaseBoundaries(settings: defaultSettings)
        XCTAssertEqual(b[.luteal]!.end, defaultSettings.averageCycleLengthDays)
    }

    // MARK: - calculateCycleStatus

    func testCycleStatus_EmptyLogs_ReturnsNil() {
        let result = calculateCycleStatus(periodLogs: [], settings: defaultSettings)
        XCTAssertNil(result)
    }

    func testCycleStatus_Day2_Menstrual() {
        let start = makeDate(2024, 1, 1)
        let ref = makeDate(2024, 1, 2)
        let logs = [PeriodLog(startDate: start)]
        let result = calculateCycleStatus(periodLogs: logs, settings: defaultSettings, referenceDate: ref)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.currentPhase, .menstrual)
        XCTAssertEqual(result!.cycleDay, 2)
    }

    func testCycleStatus_Day10_Follicular() {
        let start = makeDate(2024, 1, 1)
        let ref = makeDate(2024, 1, 10)
        let logs = [PeriodLog(startDate: start)]
        let result = calculateCycleStatus(periodLogs: logs, settings: defaultSettings, referenceDate: ref)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.currentPhase, .follicular)
    }

    func testCycleStatus_Day20_Luteal() {
        let start = makeDate(2024, 1, 1)
        let ref = makeDate(2024, 1, 20)
        let logs = [PeriodLog(startDate: start)]
        let result = calculateCycleStatus(periodLogs: logs, settings: defaultSettings, referenceDate: ref)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.currentPhase, .luteal)
    }

    func testCycleStatus_Day13_Ovulation() {
        // ovulationDay = 28 - 14 = 14; ovStart = max(7, 12) = 12
        let start = makeDate(2024, 1, 1)
        let ref = makeDate(2024, 1, 13)
        let logs = [PeriodLog(startDate: start)]
        let result = calculateCycleStatus(periodLogs: logs, settings: defaultSettings, referenceDate: ref)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.currentPhase, .ovulation)
    }

    func testCycleStatus_DaysUntilNextPhase_NonNegative() {
        let start = makeDate(2024, 1, 1)
        let ref = makeDate(2024, 1, 15)
        let logs = [PeriodLog(startDate: start)]
        let result = calculateCycleStatus(periodLogs: logs, settings: defaultSettings, referenceDate: ref)
        XCTAssertGreaterThanOrEqual(result!.daysUntilNextPhase, 0)
    }

    func testCycleStatus_PredictedNextPeriod_28DaysAfterStart() {
        let start = makeDate(2024, 1, 1)
        let ref = makeDate(2024, 1, 5)
        let logs = [PeriodLog(startDate: start)]
        let result = calculateCycleStatus(periodLogs: logs, settings: defaultSettings, referenceDate: ref)
        let expected = makeDate(2024, 1, 29)
        XCTAssertEqual(Calendar.current.startOfDay(for: result!.predictedNextPeriod),
                       Calendar.current.startOfDay(for: expected))
    }

    func testCycleStatus_MultipleLogs_PicksMostRecentRelevant() {
        let logs = [
            PeriodLog(startDate: makeDate(2024, 2, 1)),
            PeriodLog(startDate: makeDate(2024, 1, 4)),
        ]
        let ref = makeDate(2024, 2, 3)
        let result = calculateCycleStatus(periodLogs: logs, settings: defaultSettings, referenceDate: ref)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.cycleDay, 3)
    }

    // MARK: - getPhaseRecommendation

    func testRecommendation_Menstrual() {
        let rec = getPhaseRecommendation(phase: .menstrual)
        XCTAssertEqual(rec.phase, .menstrual)
        XCTAssertEqual(rec.title, "Shark Week")
        XCTAssertEqual(rec.intensityRecommendation, "low")
        XCTAssertFalse(rec.exercisesToEmphasize.isEmpty)
        XCTAssertFalse(rec.exercisesToAvoid.isEmpty)
    }

    func testRecommendation_Follicular() {
        let rec = getPhaseRecommendation(phase: .follicular)
        XCTAssertEqual(rec.intensityRecommendation, "moderate")
        XCTAssertTrue(rec.exercisesToAvoid.isEmpty)
    }

    func testRecommendation_Ovulation() {
        let rec = getPhaseRecommendation(phase: .ovulation)
        XCTAssertEqual(rec.intensityRecommendation, "peak")
        XCTAssertTrue(rec.trainingFocus.contains("PR"))
    }

    func testRecommendation_Luteal() {
        let rec = getPhaseRecommendation(phase: .luteal)
        XCTAssertEqual(rec.intensityRecommendation, "moderate")
        XCTAssertFalse(rec.exercisesToAvoid.isEmpty)
    }

    func testRecommendation_AllPhasesHaveTitle() {
        let phases: [CyclePhase] = [.menstrual, .follicular, .ovulation, .luteal]
        for phase in phases {
            let rec = getPhaseRecommendation(phase: phase)
            XCTAssertFalse(rec.title.isEmpty, "\(phase) should have a title")
        }
    }

    // MARK: - Helpers

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}
