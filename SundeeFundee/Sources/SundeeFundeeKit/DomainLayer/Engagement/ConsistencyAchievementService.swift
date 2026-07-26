import Foundation

public enum ConsistencyAchievement: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case firstConsistentWeek
    case welcomeBack
    case plannedWorkoutCompleted
    case recoveryChoice
}

public struct ConsistencyAchievementService: Sendable {
    public init() {}

    public func newlyEarned(
        records: [DailyPresenceRecord],
        previouslyEarned: Set<ConsistencyAchievement>,
        referenceDate: Date,
        calendar: Calendar
    ) -> Set<ConsistencyAchievement> {
        let referenceDay = calendar.startOfDay(for: referenceDate)
        guard let referenceDayEnd = calendar.date(byAdding: .day, value: 1, to: referenceDay) else {
            return []
        }
        let recordsToDate = records.filter { $0.firstOpenDate < referenceDayEnd }
        var earned: Set<ConsistencyAchievement> = []

        if containsConsistentWeek(records: recordsToDate, calendar: calendar) {
            earned.insert(.firstConsistentWeek)
        }
        if containsWelcomeBack(records: recordsToDate, calendar: calendar) {
            earned.insert(.welcomeBack)
        }
        if recordsToDate.contains(where: {
            $0.participationLevel == .acted && $0.status == .trained
        }) {
            earned.insert(.plannedWorkoutCompleted)
        }
        if recordsToDate.contains(where: {
            $0.participationLevel == .acted && $0.status == .resting
        }) {
            earned.insert(.recoveryChoice)
        }

        return earned.subtracting(previouslyEarned)
    }

    private func containsConsistentWeek(
        records: [DailyPresenceRecord],
        calendar: Calendar
    ) -> Bool {
        var daysByWeek: [Date: Set<String>] = [:]

        for record in records {
            guard let weekStart = calendar.dateInterval(
                of: .weekOfYear,
                for: record.firstOpenDate
            )?.start else {
                continue
            }
            daysByWeek[weekStart, default: []].insert(record.dayKey)
        }

        return daysByWeek.values.contains { $0.count >= 3 }
    }

    private func containsWelcomeBack(
        records: [DailyPresenceRecord],
        calendar: Calendar
    ) -> Bool {
        let participationByDay = Dictionary(
            records.map {
                (calendar.startOfDay(for: $0.firstOpenDate), $0.participationLevel)
            },
            uniquingKeysWith: max
        )
        let orderedDays = participationByDay.keys.sorted()

        for index in orderedDays.indices.dropFirst() {
            let currentDay = orderedDays[index]
            let previousDay = orderedDays[orderedDays.index(before: index)]
            let gap = calendar.dateComponents([.day], from: previousDay, to: currentDay).day ?? 0

            if gap >= 7, participationByDay[currentDay, default: .showedUp] >= .checkedIn {
                return true
            }
        }

        return false
    }
}
