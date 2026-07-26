import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Consistency achievements")
struct ConsistencyAchievementServiceTests {
    @Test func threePresenceDaysInOneWeekEarnFirstConsistentWeek() {
        let earned = ConsistencyAchievementService().newlyEarned(
            records: makePresenceRecords(
                days: ["2026-07-20", "2026-07-22", "2026-07-24"],
                level: .showedUp
            ),
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-26"),
            calendar: makeCalendar()
        )

        #expect(earned == [.firstConsistentWeek])
    }

    @Test func presenceDaysAcrossWeeksDoNotEarnFirstConsistentWeek() {
        let earned = ConsistencyAchievementService().newlyEarned(
            records: makePresenceRecords(
                days: ["2026-07-18", "2026-07-20", "2026-07-22"],
                level: .showedUp
            ),
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-26"),
            calendar: makeCalendar()
        )

        #expect(!earned.contains(.firstConsistentWeek))
    }

    @Test func duplicatePresenceRecordsDoNotInflateAWeek() {
        let records = makePresenceRecords(
            days: ["2026-07-20", "2026-07-20", "2026-07-22"],
            level: .showedUp
        )

        let earned = ConsistencyAchievementService().newlyEarned(
            records: records,
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-26"),
            calendar: makeCalendar()
        )

        #expect(!earned.contains(.firstConsistentWeek))
    }

    @Test func priorAchievementIsNotReAwarded() {
        let earned = ConsistencyAchievementService().newlyEarned(
            records: makePresenceRecords(
                days: ["2026-07-20", "2026-07-22", "2026-07-24"],
                level: .showedUp
            ),
            previouslyEarned: [.firstConsistentWeek],
            referenceDate: makeDate("2026-07-26"),
            calendar: makeCalendar()
        )

        #expect(earned.isEmpty)
    }

    @Test func checkedInDayAfterSevenLocalDaysEarnsWelcomeBack() {
        let records = [
            makePresenceRecord(day: "2026-07-10", level: .showedUp),
            makePresenceRecord(day: "2026-07-17", level: .checkedIn)
        ]

        let earned = ConsistencyAchievementService().newlyEarned(
            records: records,
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-17"),
            calendar: makeCalendar()
        )

        #expect(earned == [.welcomeBack])
    }

    @Test func firstPresenceRecordNeverEarnsWelcomeBack() {
        let earned = ConsistencyAchievementService().newlyEarned(
            records: [makePresenceRecord(day: "2026-07-17", level: .acted)],
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-17"),
            calendar: makeCalendar()
        )

        #expect(!earned.contains(.welcomeBack))
    }

    @Test func showedUpDayAfterGapDoesNotEarnWelcomeBack() {
        let records = [
            makePresenceRecord(day: "2026-07-10", level: .checkedIn),
            makePresenceRecord(day: "2026-07-17", level: .showedUp)
        ]

        let earned = ConsistencyAchievementService().newlyEarned(
            records: records,
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-17"),
            calendar: makeCalendar()
        )

        #expect(!earned.contains(.welcomeBack))
    }

    @Test func gapShorterThanSevenLocalDaysDoesNotEarnWelcomeBack() {
        let records = [
            makePresenceRecord(day: "2026-07-11", level: .showedUp),
            makePresenceRecord(day: "2026-07-17", level: .acted)
        ]

        let earned = ConsistencyAchievementService().newlyEarned(
            records: records,
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-17"),
            calendar: makeCalendar()
        )

        #expect(!earned.contains(.welcomeBack))
    }

    @Test func actedTrainedRecordEarnsPlannedWorkoutCompleted() {
        let earned = ConsistencyAchievementService().newlyEarned(
            records: [
                makePresenceRecord(
                    day: "2026-07-20",
                    level: .acted,
                    status: .trained
                )
            ],
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-20"),
            calendar: makeCalendar()
        )

        #expect(earned == [.plannedWorkoutCompleted])
    }

    @Test func trainedStatusWithoutActedLevelDoesNotEarnWorkoutAchievement() {
        let earned = ConsistencyAchievementService().newlyEarned(
            records: [
                makePresenceRecord(
                    day: "2026-07-20",
                    level: .checkedIn,
                    status: .trained
                )
            ],
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-20"),
            calendar: makeCalendar()
        )

        #expect(!earned.contains(.plannedWorkoutCompleted))
    }

    @Test func actedRestingRecordEarnsRecoveryChoice() {
        let earned = ConsistencyAchievementService().newlyEarned(
            records: [
                makePresenceRecord(
                    day: "2026-07-20",
                    level: .acted,
                    status: .resting
                )
            ],
            previouslyEarned: [],
            referenceDate: makeDate("2026-07-20"),
            calendar: makeCalendar()
        )

        #expect(earned == [.recoveryChoice])
    }
}

private func makePresenceRecords(
    days: [String],
    level: DailyParticipationLevel
) -> [DailyPresenceRecord] {
    days.map { makePresenceRecord(day: $0, level: level) }
}

private func makePresenceRecord(
    day: String,
    level: DailyParticipationLevel,
    status: DailyPresenceStatus? = nil
) -> DailyPresenceRecord {
    DailyPresenceRecord(
        dayKey: day,
        timeZoneIdentifier: makeCalendar().timeZone.identifier,
        firstOpenDate: makeDate(day),
        participationLevel: level,
        status: status
    )
}

private func makeDate(_ day: String) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = makeCalendar()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = makeCalendar().timeZone
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.date(from: "\(day) 12:00")!
}

private func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    calendar.firstWeekday = 2
    calendar.minimumDaysInFirstWeek = 4
    return calendar
}
