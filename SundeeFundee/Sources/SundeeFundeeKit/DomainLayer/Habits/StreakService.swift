import Foundation

public struct WeeklyStreak: Sendable, Equatable {
    public let currentWeeklyStreak: Int
    public let longestWeeklyStreak: Int
    public let lastWorkoutDate: Date?
}

public enum StreakService {
    public static func calculate(
        workouts: [Workout],
        targetPerWeek: Int = 1,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> WeeklyStreak {
        let completedDates = workouts.compactMap(\.completedAt)
        guard !completedDates.isEmpty else {
            return WeeklyStreak(currentWeeklyStreak: 0, longestWeeklyStreak: 0, lastWorkoutDate: nil)
        }

        let grouped = Dictionary(grouping: completedDates) { date in
            calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        }
        let successfulWeeks = Set(grouped.filter { $0.value.count >= targetPerWeek }.keys)
        let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)

        var current = 0
        var cursor = currentWeek
        while successfulWeeks.contains(cursor) {
            current += 1
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = previous
        }

        let sortedWeeks = successfulWeeks.sorted()
        var longest = 0
        var running = 0
        var previous: Date?
        for week in sortedWeeks {
            if let previous,
               let expected = calendar.date(byAdding: .weekOfYear, value: 1, to: previous),
               calendar.isDate(expected, inSameDayAs: week) {
                running += 1
            } else {
                running = 1
            }
            longest = max(longest, running)
            previous = week
        }

        return WeeklyStreak(
            currentWeeklyStreak: current,
            longestWeeklyStreak: longest,
            lastWorkoutDate: completedDates.max()
        )
    }
}
