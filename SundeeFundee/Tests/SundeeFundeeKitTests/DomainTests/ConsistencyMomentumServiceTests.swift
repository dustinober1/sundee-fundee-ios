import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Consistency momentum")
struct ConsistencyMomentumServiceTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: "\(value)T16:00:00Z")!
    }

    private func record(_ day: String, level: DailyParticipationLevel) -> DailyPresenceRecord {
        DailyPresenceRecord(
            dayKey: day,
            timeZoneIdentifier: calendar.timeZone.identifier,
            firstOpenDate: date(day),
            participationLevel: level
        )
    }

    @Test func summarizesDistinctParticipationLevels() {
        let records = [
            record("2026-07-20", level: .showedUp),
            record("2026-07-21", level: .checkedIn),
            record("2026-07-22", level: .acted)
        ]

        let result = ConsistencyMomentumService().summarize(
            records: records,
            referenceDate: date("2026-07-26"),
            calendar: calendar
        )

        #expect(result.daysPresentThisWeek == 3)
        #expect(result.checkInsThisWeek == 2)
        #expect(result.actionDaysThisWeek == 1)
    }

    @Test func emptyCurrentWeekDoesNotErasePriorWeeks() {
        let result = ConsistencyMomentumService().summarize(
            records: [record("2026-07-13", level: .acted)],
            referenceDate: date("2026-07-26"),
            calendar: calendar
        )

        #expect(result.daysPresentThisWeek == 0)
        #expect(result.rollingWeeks.map(\.daysPresent).contains(1))
        #expect(result.supportiveHeadline == "Welcome back")
    }
}
