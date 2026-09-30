import Foundation

// MARK: - SocialSnapshotBuilder

/// Builds a sanitized, peer-shareable `SocialMemberSnapshot`.
///
/// Ensures strict redaction: only completed workout counts, streak days, and
/// safe display names are included. No cycle or health data ever crosses this boundary.
public enum SocialSnapshotBuilder {
    public static func build(
        userID: String,
        displayName: String,
        workouts: [Workout],
        presenceRecords: [DailyPresenceRecord],
        weeklyGoalTarget: Int = 4,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> SocialMemberSnapshot {
        // 1. Calculate workouts completed in current week
        let currentWeekWorkouts = workouts.filter { workout in
            guard workout.completedAt != nil else { return false }
            return calendar.isDate(workout.date, equalTo: referenceDate, toGranularity: .weekOfYear)
        }

        // 2. Calculate consecutive presence streak ending today or yesterday
        let streak = calculateStreak(presenceRecords: presenceRecords, referenceDate: referenceDate, calendar: calendar)

        // 3. Last active timestamp
        let lastActive = presenceRecords.map(\.mostRecentOpenDate).max()
            ?? workouts.compactMap(\.completedAt).max()
            ?? referenceDate

        let sanitizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Lifter"
            : displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        return SocialMemberSnapshot(
            id: userID,
            displayName: sanitizedName,
            weeklyCompletedWorkouts: currentWeekWorkouts.count,
            currentStreakDays: streak,
            weeklyGoalTarget: weeklyGoalTarget,
            lastActiveDate: lastActive,
            dateCreated: referenceDate
        )
    }

    private static func calculateStreak(
        presenceRecords: [DailyPresenceRecord],
        referenceDate: Date,
        calendar: Calendar
    ) -> Int {
        guard !presenceRecords.isEmpty else { return 0 }

        // Map records by start of day
        let daysWithPresence = Set(presenceRecords.map { calendar.startOfDay(for: $0.firstOpenDate) })
        let today = calendar.startOfDay(for: referenceDate)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        var currentDay = daysWithPresence.contains(today) ? today : (daysWithPresence.contains(yesterday) ? yesterday : nil)
        guard let startDay = currentDay else { return 0 }

        var streak = 0
        var checkDay: Date? = startDay

        while let day = checkDay, daysWithPresence.contains(day) {
            streak += 1
            checkDay = calendar.date(byAdding: .day, value: -1, to: day)
        }

        return streak
    }
}
