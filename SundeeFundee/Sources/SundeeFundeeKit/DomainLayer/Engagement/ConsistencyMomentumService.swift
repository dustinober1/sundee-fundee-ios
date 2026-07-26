import Foundation

public struct WeeklyPresenceSummary: Sendable, Equatable {
    public let weekStart: Date
    public let daysPresent: Int
    public let checkInDays: Int
    public let actionDays: Int
}

public struct ConsistencyMomentumSummary: Sendable, Equatable {
    public let daysPresentThisWeek: Int
    public let checkInsThisWeek: Int
    public let actionDaysThisWeek: Int
    public let rollingWeeks: [WeeklyPresenceSummary]
    public let supportiveHeadline: String
    public let achievements: Set<ConsistencyAchievement>

    public init(
        daysPresentThisWeek: Int,
        checkInsThisWeek: Int,
        actionDaysThisWeek: Int,
        rollingWeeks: [WeeklyPresenceSummary],
        supportiveHeadline: String,
        achievements: Set<ConsistencyAchievement> = []
    ) {
        self.daysPresentThisWeek = daysPresentThisWeek
        self.checkInsThisWeek = checkInsThisWeek
        self.actionDaysThisWeek = actionDaysThisWeek
        self.rollingWeeks = rollingWeeks
        self.supportiveHeadline = supportiveHeadline
        self.achievements = achievements
    }
}

public struct ConsistencyMomentumService: Sendable {
    private let achievementService: ConsistencyAchievementService

    public init(
        achievementService: ConsistencyAchievementService = ConsistencyAchievementService()
    ) {
        self.achievementService = achievementService
    }

    public func summarize(
        records: [DailyPresenceRecord],
        referenceDate: Date,
        calendar: Calendar
    ) -> ConsistencyMomentumSummary {
        let records = mergedByLocalDay(records)
        let referenceDayKey = PresenceLocalDay.key(for: referenceDate, calendar: calendar)
        let floatingCalendar = PresenceLocalDay.floatingCalendar(from: calendar)
        let referenceDay = PresenceLocalDay.nominalDate(
            for: referenceDayKey,
            calendar: calendar
        ) ?? referenceDate
        let currentWeekStart =
            floatingCalendar.dateInterval(of: .weekOfYear, for: referenceDay)?.start
            ?? floatingCalendar.startOfDay(for: referenceDay)
        let starts = (0..<4).compactMap {
            floatingCalendar.date(byAdding: .weekOfYear, value: -$0, to: currentWeekStart)
        }.reversed()

        let weeks = starts.map { start in
            let end = floatingCalendar.date(
                byAdding: .weekOfYear,
                value: 1,
                to: start
            ) ?? start
            let matches = records.filter { record in
                guard let localDay = PresenceLocalDay.nominalDate(
                    for: record.dayKey,
                    calendar: calendar
                ) else {
                    return false
                }
                return localDay >= start && localDay < end
            }
            return WeeklyPresenceSummary(
                weekStart: start,
                daysPresent: Set(matches.map(\.dayKey)).count,
                checkInDays: Set(matches.filter { $0.participationLevel >= .checkedIn }.map(\.dayKey)).count,
                actionDays: Set(matches.filter { $0.participationLevel >= .acted }.map(\.dayKey)).count
            )
        }
        let current = weeks.last ?? WeeklyPresenceSummary(
            weekStart: currentWeekStart,
            daysPresent: 0,
            checkInDays: 0,
            actionDays: 0
        )
        let hasEarlierPresence = records.contains { $0.dayKey < referenceDayKey }
        let headline = isReturningOnReferenceDay(
            records: records,
            referenceDayKey: referenceDayKey,
            calendar: calendar
        )
            ? ConsistencyMomentumCopy.welcomeBack
            : current.daysPresent > 0
            ? "\(current.daysPresent) \(current.daysPresent == 1 ? "day" : "days") present this week"
            : (hasEarlierPresence ? ConsistencyMomentumCopy.welcomeBack : "Start by showing up today")

        return ConsistencyMomentumSummary(
            daysPresentThisWeek: current.daysPresent,
            checkInsThisWeek: current.checkInDays,
            actionDaysThisWeek: current.actionDays,
            rollingWeeks: weeks,
            supportiveHeadline: headline,
            achievements: achievementService.newlyEarned(
                records: records,
                previouslyEarned: [],
                referenceDate: referenceDate,
                calendar: calendar
            )
        )
    }

    private func mergedByLocalDay(
        _ records: [DailyPresenceRecord]
    ) -> [DailyPresenceRecord] {
        Dictionary(records.map { ($0.dayKey, $0) }) { existing, incoming in
            existing.merging(with: incoming)
        }.values.sorted { $0.dayKey < $1.dayKey }
    }

    private func isReturningOnReferenceDay(
        records: [DailyPresenceRecord],
        referenceDayKey: String,
        calendar: Calendar
    ) -> Bool {
        let dayKeys = Set(records.map(\.dayKey)).sorted()
        guard let currentIndex = dayKeys.firstIndex(of: referenceDayKey),
              currentIndex > dayKeys.startIndex else {
            return false
        }
        let previousIndex = dayKeys.index(before: currentIndex)
        return (PresenceLocalDay.daysBetween(
            dayKeys[previousIndex],
            referenceDayKey,
            calendar: calendar
        ) ?? 0) >= 7
    }
}
