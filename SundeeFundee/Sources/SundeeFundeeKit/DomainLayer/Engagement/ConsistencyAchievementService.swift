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
        let referenceDayKey = PresenceLocalDay.key(for: referenceDate, calendar: calendar)
        let recordsToDate = mergedByLocalDay(
            records.filter { $0.dayKey <= referenceDayKey }
        )
        var earned: Set<ConsistencyAchievement> = []

        if containsConsistentWeek(records: recordsToDate, calendar: calendar) {
            earned.insert(.firstConsistentWeek)
        }
        if containsWelcomeBack(records: recordsToDate, calendar: calendar) {
            earned.insert(.welcomeBack)
        }
        if recordsToDate.contains(where: { $0.actionEvidence.contains(.trained) }) {
            earned.insert(.plannedWorkoutCompleted)
        }
        if recordsToDate.contains(where: {
            !$0.actionEvidence.intersection([.recovered, .rested]).isEmpty
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
            guard let weekStart = PresenceLocalDay.weekStart(
                for: record.dayKey,
                calendar: calendar
            ) else {
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
            records.map { ($0.dayKey, $0.participationLevel) },
            uniquingKeysWith: max
        )
        let orderedDays = participationByDay.keys.sorted()

        for index in orderedDays.indices.dropFirst() {
            let currentDay = orderedDays[index]
            let previousDay = orderedDays[orderedDays.index(before: index)]
            let gap = PresenceLocalDay.daysBetween(
                previousDay,
                currentDay,
                calendar: calendar
            ) ?? 0

            if gap >= 7, participationByDay[currentDay, default: .showedUp] >= .checkedIn {
                return true
            }
        }

        return false
    }

    private func mergedByLocalDay(
        _ records: [DailyPresenceRecord]
    ) -> [DailyPresenceRecord] {
        Dictionary(records.map { ($0.dayKey, $0) }) { existing, incoming in
            existing.merging(with: incoming)
        }.values.sorted { $0.dayKey < $1.dayKey }
    }
}
