import Testing
import Foundation
@testable import SundeeFundeeKit

@Suite("CycleForecastService")
struct CycleForecastServiceTests {

    private func makeCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func makeDate(year: Int = 2026, month: Int = 9, day: Int = 30) -> Date {
        let cal = makeCalendar()
        let comps = DateComponents(year: year, month: month, day: day, hour: 12)
        return cal.date(from: comps)!
    }

    @Test("Forecast generates exactly 7 continuous days")
    func testSevenContinuousDays() {
        let cal = makeCalendar()
        let refDate = makeDate(year: 2026, month: 9, day: 30)
        let periodStart = makeDate(year: 2026, month: 9, day: 15) // Day 16 of 28
        let logs = [PeriodLog(startDate: periodStart)]
        let settings = CycleSettings(averageCycleLengthDays: 28, averagePeriodLengthDays: 5)

        let forecast = CycleForecastService.generateSevenDayForecast(
            periodLogs: logs,
            settings: settings,
            mode: .standard,
            referenceDate: refDate,
            calendar: cal
        )

        #expect(forecast.count == 7)
        #expect(forecast[0].isToday == true)
        #expect(forecast[0].dayOffset == 0)
        #expect(forecast[6].isToday == false)
        #expect(forecast[6].dayOffset == 6)

        // Day offsets are sequential 0...6
        for (idx, item) in forecast.enumerated() {
            #expect(item.dayOffset == idx)
        }
    }

    @Test("Contraceptive mode suppresses ovulatory phases and shows steady baseline when not bleeding")
    func testContraceptiveModeSuppressesPhases() {
        let cal = makeCalendar()
        let refDate = makeDate(year: 2026, month: 9, day: 30)
        let periodStart = makeDate(year: 2026, month: 9, day: 1) // 29 days ago, ended long ago
        let logs = [PeriodLog(startDate: periodStart, endDate: makeDate(year: 2026, month: 9, day: 5))]
        let settings = CycleSettings(averageCycleLengthDays: 28)

        let forecast = CycleForecastService.generateSevenDayForecast(
            periodLogs: logs,
            settings: settings,
            mode: .contraceptive,
            referenceDate: refDate,
            calendar: cal
        )

        #expect(forecast.count == 7)
        for day in forecast {
            #expect(day.phase == nil)
            #expect(day.energyTier == .steady)
            #expect(day.headline == "Steady Baseline")
            #expect(day.suggestedIntensity == "Autoregulated")
        }
    }

    @Test("Contraceptive mode marks active withdrawal bleed as recovery")
    func testContraceptiveModeActiveBleed() {
        let cal = makeCalendar()
        let refDate = makeDate(year: 2026, month: 9, day: 30)
        // Active bleed started yesterday, ongoing (no endDate)
        let bleedStart = makeDate(year: 2026, month: 9, day: 29)
        let logs = [PeriodLog(startDate: bleedStart, endDate: nil)]
        let settings = CycleSettings(averageCycleLengthDays: 28, averagePeriodLengthDays: 5)

        let forecast = CycleForecastService.generateSevenDayForecast(
            periodLogs: logs,
            settings: settings,
            mode: .contraceptive,
            referenceDate: refDate,
            calendar: cal
        )

        // Today and upcoming bleed days should show recovery focus
        #expect(forecast[0].phase == .menstrual)
        #expect(forecast[0].energyTier == .recovering)
        #expect(forecast[0].headline.contains("Withdrawal Bleed"))
    }

    @Test("Irregular mode adapts for extended cycles exceeding 38 days")
    func testIrregularModeExtendedCycle() {
        let cal = makeCalendar()
        let refDate = makeDate(year: 2026, month: 9, day: 30)
        // Period was 45 days ago
        let periodStart = cal.date(byAdding: .day, value: -45, to: refDate)!
        let logs = [PeriodLog(startDate: periodStart, endDate: cal.date(byAdding: .day, value: 5, to: periodStart))]
        let settings = CycleSettings(averageCycleLengthDays: 28)

        let forecast = CycleForecastService.generateSevenDayForecast(
            periodLogs: logs,
            settings: settings,
            mode: .irregular,
            referenceDate: refDate,
            calendar: cal
        )

        #expect(forecast[0].phase == nil)
        #expect(forecast[0].energyTier == .steady)
        #expect(forecast[0].headline.contains("Extended Cycle"))
        #expect(forecast[0].suggestedIntensity == "By Feel")
    }

    @Test("Perimenopause mode emphasizes joint prep and warmup focus")
    func testPerimenopauseModeGuidance() {
        let cal = makeCalendar()
        let refDate = makeDate(year: 2026, month: 9, day: 30)
        let periodStart = makeDate(year: 2026, month: 9, day: 20)
        let logs = [PeriodLog(startDate: periodStart)]
        let settings = CycleSettings(averageCycleLengthDays: 28)

        let forecast = CycleForecastService.generateSevenDayForecast(
            periodLogs: logs,
            settings: settings,
            mode: .perimenopause,
            referenceDate: refDate,
            calendar: cal
        )

        #expect(forecast[0].headline.contains("Perimenopause"))
        #expect(forecast[0].trainingFocus.contains("warmup"))
    }

    @Test("Standard natural cycle mode predicts peak capacity during ovulation")
    func testStandardNaturalOvulation() {
        let cal = makeCalendar()
        let refDate = makeDate(year: 2026, month: 9, day: 30)
        // Set period start so day 14 falls right on day offset 2
        let periodStart = cal.date(byAdding: .day, value: -12, to: refDate)!
        let logs = [PeriodLog(startDate: periodStart)]
        let settings = CycleSettings(averageCycleLengthDays: 28, averagePeriodLengthDays: 5, lutealPhaseLengthDays: 14)

        let forecast = CycleForecastService.generateSevenDayForecast(
            periodLogs: logs,
            settings: settings,
            mode: .standard,
            referenceDate: refDate,
            calendar: cal
        )

        // Day offset 2 is Day 15 of cycle (Ovulation window)
        let ovDay = forecast[2]
        #expect(ovDay.phase == .ovulation)
        #expect(ovDay.energyTier == .peak)
        #expect(ovDay.suggestedIntensity == "Peak")
    }
}
