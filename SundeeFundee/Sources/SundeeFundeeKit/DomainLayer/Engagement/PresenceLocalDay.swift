import Foundation

enum PresenceLocalDay {
    static func key(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func nominalDate(for dayKey: String, calendar: Calendar) -> Date? {
        let parts = dayKey.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }

        var components = DateComponents()
        components.calendar = floatingCalendar(from: calendar)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12

        guard let date = components.date else { return nil }
        let roundTrip = floatingCalendar(from: calendar).dateComponents(
            [.year, .month, .day],
            from: date
        )
        guard roundTrip.year == year, roundTrip.month == month, roundTrip.day == day else {
            return nil
        }
        return date
    }

    static func weekStart(for dayKey: String, calendar: Calendar) -> Date? {
        guard let date = nominalDate(for: dayKey, calendar: calendar) else { return nil }
        return floatingCalendar(from: calendar).dateInterval(of: .weekOfYear, for: date)?.start
    }

    static func daysBetween(
        _ earlierDayKey: String,
        _ laterDayKey: String,
        calendar: Calendar
    ) -> Int? {
        guard let earlier = nominalDate(for: earlierDayKey, calendar: calendar),
              let later = nominalDate(for: laterDayKey, calendar: calendar) else {
            return nil
        }
        return floatingCalendar(from: calendar).dateComponents(
            [.day],
            from: earlier,
            to: later
        ).day
    }

    static func floatingCalendar(from calendar: Calendar) -> Calendar {
        var result = Calendar(identifier: calendar.identifier)
        result.locale = Locale(identifier: "en_US_POSIX")
        result.timeZone = TimeZone(secondsFromGMT: 0)!
        result.firstWeekday = calendar.firstWeekday
        result.minimumDaysInFirstWeek = calendar.minimumDaysInFirstWeek
        return result
    }
}
