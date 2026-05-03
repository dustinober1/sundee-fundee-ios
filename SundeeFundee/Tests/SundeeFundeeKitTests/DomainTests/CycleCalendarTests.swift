import XCTest
@testable import SundeeFundeeKit

final class CycleCalendarTests: XCTestCase {

    let defaultSettings = CycleSettings(averageCycleLengthDays: 28, averagePeriodLengthDays: 5, lutealPhaseLengthDays: 14)

    // MARK: - getPhaseForDay

    func testPhaseForDay1_Menstrual() {
        XCTAssertEqual(getPhaseForDay(1, settings: defaultSettings), .menstrual)
    }

    func testPhaseForDay5_Menstrual() {
        XCTAssertEqual(getPhaseForDay(5, settings: defaultSettings), .menstrual)
    }

    func testPhaseForDay6_Follicular() {
        XCTAssertEqual(getPhaseForDay(6, settings: defaultSettings), .follicular)
    }

    func testPhaseForDay13_Ovulation() {
        XCTAssertEqual(getPhaseForDay(13, settings: defaultSettings), .ovulation)
    }

    func testPhaseForDay20_Luteal() {
        XCTAssertEqual(getPhaseForDay(20, settings: defaultSettings), .luteal)
    }

    func testPhaseForDay28_Luteal() {
        XCTAssertEqual(getPhaseForDay(28, settings: defaultSettings), .luteal)
    }

    func testPhaseForDay29_WrapsToMenstrual() {
        XCTAssertEqual(getPhaseForDay(29, settings: defaultSettings), .menstrual)
    }

    func testPhaseForDay0_WrapsToLuteal() {
        XCTAssertEqual(getPhaseForDay(0, settings: defaultSettings), .luteal)
    }

    // MARK: - getPhaseAdjustmentSummary

    func testAdjustmentSummary_Ovulation() {
        XCTAssertTrue(getPhaseAdjustmentSummary(.ovulation).contains("+12%"))
    }

    func testAdjustmentSummary_Menstrual() {
        XCTAssertTrue(getPhaseAdjustmentSummary(.menstrual).contains("-10%"))
    }

    func testAdjustmentSummary_Follicular() {
        XCTAssertTrue(getPhaseAdjustmentSummary(.follicular).contains("baseline"))
    }

    func testAdjustmentSummary_Luteal() {
        XCTAssertTrue(getPhaseAdjustmentSummary(.luteal).contains("-3%"))
    }

    // MARK: - getPhaseExplanation

    func testPhaseExplanation_AllPhasesNonEmpty() {
        let phases: [CyclePhase] = [.menstrual, .follicular, .ovulation, .luteal]
        for phase in phases {
            XCTAssertGreaterThan(getPhaseExplanation(phase).count, 20, "\(phase) should have a detailed explanation")
        }
    }

    // MARK: - getCycleCalendarData

    func testCalendarData_ReturnsCorrectDayCount() {
        let logs = [PeriodLog(startDate: makeDate(2026, 3, 1))]
        let data = getCycleCalendarData(periodLogs: logs, settings: defaultSettings, month: 3, year: 2026)
        XCTAssertEqual(data.count, 31) // March has 31 days
    }

    func testCalendarData_February() {
        let logs = [PeriodLog(startDate: makeDate(2026, 2, 1))]
        let data = getCycleCalendarData(periodLogs: logs, settings: defaultSettings, month: 2, year: 2026)
        XCTAssertEqual(data.count, 28)
    }

    func testCalendarData_PeriodLoggedDays() {
        let logs = [PeriodLog(startDate: makeDate(2026, 3, 1), endDate: makeDate(2026, 3, 5))]
        let data = getCycleCalendarData(periodLogs: logs, settings: defaultSettings, month: 3, year: 2026)
        let loggedDays = data.filter(\.isPeriodLogged)
        XCTAssertEqual(loggedDays.count, 5)
    }

    func testCalendarData_DayAfterShortLoggedPeriodMovesOutOfMenstrualPhase() {
        let logs = [PeriodLog(startDate: makeDate(2026, 3, 1), endDate: makeDate(2026, 3, 2))]
        let data = getCycleCalendarData(periodLogs: logs, settings: defaultSettings, month: 3, year: 2026)

        let dayAfterPeriod = data.first {
            Calendar.current.component(.day, from: $0.date) == 3
        }

        XCTAssertEqual(dayAfterPeriod?.isPeriodLogged, false)
        XCTAssertEqual(dayAfterPeriod?.phase, .follicular)
    }

    // MARK: - Helpers

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
