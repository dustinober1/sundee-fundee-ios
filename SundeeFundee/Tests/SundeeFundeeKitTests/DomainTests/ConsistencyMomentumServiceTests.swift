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

    private func record(
        _ day: String,
        level: DailyParticipationLevel,
        status: DailyPresenceStatus? = nil
    ) -> DailyPresenceRecord {
        DailyPresenceRecord(
            dayKey: day,
            timeZoneIdentifier: calendar.timeZone.identifier,
            firstOpenDate: date(day),
            participationLevel: level,
            status: status
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

    @Test func todayAfterASevenDayGapPrioritizesWelcomeBack() {
        let result = ConsistencyMomentumService().summarize(
            records: [
                record("2026-07-13", level: .acted),
                record("2026-07-20", level: .showedUp),
            ],
            referenceDate: date("2026-07-20"),
            calendar: calendar
        )

        #expect(result.daysPresentThisWeek == 1)
        #expect(result.supportiveHeadline == "Welcome back")
    }

    @Test func datelineRecordStaysInItsStoredLocalDayAndWeek() {
        let record = DailyPresenceRecord(
            dayKey: "2026-07-20",
            timeZoneIdentifier: "Pacific/Kiritimati",
            firstOpenDate: ISO8601DateFormatter().date(from: "2026-07-19T10:30:00Z")!,
            participationLevel: .acted,
            actionEvidence: [.recovered]
        )

        let result = ConsistencyMomentumService().summarize(
            records: [record],
            referenceDate: date("2026-07-20"),
            calendar: calendar
        )

        #expect(result.daysPresentThisWeek == 1)
        #expect(result.actionDaysThisWeek == 1)
    }

    @Test func daylightSavingTransitionKeepsDistinctStoredDays() {
        let records = [
            DailyPresenceRecord(
                dayKey: "2026-03-08",
                timeZoneIdentifier: "America/New_York",
                firstOpenDate: ISO8601DateFormatter().date(from: "2026-03-08T06:30:00Z")!
            ),
            DailyPresenceRecord(
                dayKey: "2026-03-09",
                timeZoneIdentifier: "America/New_York",
                firstOpenDate: ISO8601DateFormatter().date(from: "2026-03-09T04:30:00Z")!
            ),
        ]

        let result = ConsistencyMomentumService().summarize(
            records: records,
            referenceDate: ISO8601DateFormatter().date(from: "2026-03-09T16:00:00Z")!,
            calendar: calendar
        )

        #expect(result.rollingWeeks.map(\.daysPresent).reduce(0, +) == 2)
    }

    @Test func summaryRederivesAchievementsFromPresenceHistory() {
        let result = ConsistencyMomentumService().summarize(
            records: [
                record("2026-07-06", level: .showedUp),
                record("2026-07-20", level: .acted, status: .trained),
                record("2026-07-22", level: .showedUp),
                record("2026-07-24", level: .acted, status: .resting)
            ],
            referenceDate: date("2026-07-26"),
            calendar: calendar
        )

        #expect(result.achievements == Set(ConsistencyAchievement.allCases))
    }
}
