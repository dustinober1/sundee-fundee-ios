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
}

public struct ConsistencyMomentumService: Sendable {
    public init() {}

    public func summarize(
        records: [DailyPresenceRecord],
        referenceDate: Date,
        calendar: Calendar
    ) -> ConsistencyMomentumSummary {
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)!.start
        let starts = (0..<4).compactMap {
            calendar.date(byAdding: .weekOfYear, value: -$0, to: currentWeekStart)
        }.reversed()

        let weeks = starts.map { start in
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            let matches = records.filter { $0.firstOpenDate >= start && $0.firstOpenDate < end }
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
        let hasEarlierPresence = weeks.dropLast().contains { $0.daysPresent > 0 }
        let headline = current.daysPresent > 0
            ? "\(current.daysPresent) \(current.daysPresent == 1 ? "day" : "days") present this week"
            : (hasEarlierPresence ? "Welcome back" : "Start by showing up today")

        return ConsistencyMomentumSummary(
            daysPresentThisWeek: current.daysPresent,
            checkInsThisWeek: current.checkInDays,
            actionDaysThisWeek: current.actionDays,
            rollingWeeks: weeks,
            supportiveHeadline: headline
        )
    }
}
