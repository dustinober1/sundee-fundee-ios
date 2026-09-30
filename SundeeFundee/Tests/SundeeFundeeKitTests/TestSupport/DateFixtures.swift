import Foundation

// MARK: - Shared Date Fixtures
//
// Pinned-date helpers for tests whose outcomes must not drift with the wall
// clock (streaks, consistency windows, analytics bucketing, challenge
// deadlines). Prefer these over `Date()` whenever a date feeds comparisons;
// `Date()` is acceptable only as an inert timestamp nothing asserts on.
//
// Dates are constructed at fixed noon UTC so bucketing is stable regardless
// of the runner's local time zone or daylight-saving transitions.

/// The calendar used by `makeDate` — fixed UTC, Gregorian, Monday-free
/// conventions irrelevant since callers assert on explicit dates.
public enum DateFixtures {
    /// Fixed test calendar: UTC, en_US_POSIX, so every runner sees the same
    /// day boundaries.
    public static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    /// A pinned "now" for suites that need a deterministic reference date:
    /// 2026-06-15 12:00 UTC (a Monday).
    public static let fixedNow: Date = makeDate(year: 2026, month: 6, day: 15, hour: 12)
}

/// Builds a date at noon UTC on the given calendar day.
public func makeDate(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) -> Date {
    DateFixtures.utcCalendar.date(
        from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
    )!
}

/// Builds a date N whole days before `DateFixtures.fixedNow`, at the same
/// time of day. Convenient for "days ago" fixtures in streak/window tests.
public func makeDate(daysAgo days: Int) -> Date {
    DateFixtures.utcCalendar.date(byAdding: .day, value: -days, to: DateFixtures.fixedNow)!
}
