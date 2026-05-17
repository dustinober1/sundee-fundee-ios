import Foundation

public struct ProgressSnapshotItem: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let value: String
    public let subtitle: String
    public let systemImage: String

    public init(
        id: String,
        title: String,
        value: String,
        subtitle: String,
        systemImage: String
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

public struct ProgressSnapshot: Equatable, Sendable {
    public let items: [ProgressSnapshotItem]

    public init(items: [ProgressSnapshotItem]) {
        self.items = items
    }
}

public enum ProgressSnapshotService {
    public static func build(
        maxRecords: [OneRepMaxRecord],
        workouts: [Workout],
        challenges: [Challenge],
        cycleData: [CyclePerformancePoint],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ProgressSnapshot {
        var items: [ProgressSnapshotItem] = []

        items.append(strongestLiftTrend(from: maxRecords))
        items.append(weeklyConsistency(from: workouts, now: now, calendar: calendar))

        if let pr = recentPR(from: maxRecords) {
            items.append(pr)
        }

        if let challenge = activeChallenge(from: challenges) {
            items.append(challenge)
        }

        if let cycleInsight = cycleInsight(from: cycleData) {
            items.append(cycleInsight)
        }

        return ProgressSnapshot(items: items)
    }

    private static func strongestLiftTrend(from records: [OneRepMaxRecord]) -> ProgressSnapshotItem {
        let grouped = Dictionary(grouping: records, by: \.exerciseName)
        let bestTrend = grouped.compactMap { exercise, records -> (exercise: String, delta: Double, unit: WeightUnit)? in
            let sorted = records.sorted { $0.date > $1.date }
            guard sorted.count >= 2 else { return nil }
            return (exercise, sorted[0].weight - sorted[1].weight, sorted[0].unit)
        }
        .max { lhs, rhs in lhs.delta < rhs.delta }

        if let bestTrend, bestTrend.delta > 0 {
            return ProgressSnapshotItem(
                id: "strongest-trend",
                title: "Strongest Trend",
                value: bestTrend.exercise,
                subtitle: "+\(formatWeight(bestTrend.delta)) \(bestTrend.unit.rawValue) since last log",
                systemImage: "chart.line.uptrend.xyaxis"
            )
        }

        if let best = records.max(by: { $0.weight < $1.weight }) {
            return ProgressSnapshotItem(
                id: "strongest-trend",
                title: "Strongest Lift",
                value: best.exerciseName,
                subtitle: "\(formatWeight(best.weight)) \(best.unit.rawValue) best recorded",
                systemImage: "scalemass"
            )
        }

        return ProgressSnapshotItem(
            id: "strongest-trend",
            title: "Strongest Trend",
            value: "Log a max",
            subtitle: "Two entries for one lift unlock trend insight.",
            systemImage: "chart.line.uptrend.xyaxis"
        )
    }

    private static func weeklyConsistency(
        from workouts: [Workout],
        now: Date,
        calendar: Calendar
    ) -> ProgressSnapshotItem {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        let completedThisWeek = workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= weekStart && completedAt <= now
        }.count

        return ProgressSnapshotItem(
            id: "weekly-consistency",
            title: "Weekly Consistency",
            value: "\(completedThisWeek)",
            subtitle: completedThisWeek == 1 ? "workout completed this week" : "workouts completed this week",
            systemImage: "calendar"
        )
    }

    private static func recentPR(from records: [OneRepMaxRecord]) -> ProgressSnapshotItem? {
        guard let latest = records.max(by: { $0.date < $1.date }) else { return nil }
        return ProgressSnapshotItem(
            id: "recent-pr",
            title: "Recent PR",
            value: latest.exerciseName,
            subtitle: "\(formatWeight(latest.weight)) \(latest.unit.rawValue)",
            systemImage: "sparkles"
        )
    }

    private static func activeChallenge(from challenges: [Challenge]) -> ProgressSnapshotItem? {
        guard let challenge = challenges.first(where: { $0.status == .active }) else { return nil }
        let progress = ChallengeEngine.computeProgress(challenge: challenge)
        return ProgressSnapshotItem(
            id: "active-challenge",
            title: "Active Challenge",
            value: challenge.title,
            subtitle: "\(Int(progress.percentComplete * 100))% toward \(progress.currentTierName)",
            systemImage: "flag.fill"
        )
    }

    private static func cycleInsight(from data: [CyclePerformancePoint]) -> ProgressSnapshotItem? {
        guard let strongest = data.max(by: { $0.averageVolume < $1.averageVolume }) else { return nil }
        return ProgressSnapshotItem(
            id: "cycle-insight",
            title: "Cycle Insight",
            value: phaseLabel(strongest.phase),
            subtitle: "Highest average volume from \(strongest.workoutCount) logged workout(s)",
            systemImage: "arrow.triangle.2.circlepath"
        )
    }

    private static func phaseLabel(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        }
    }

    private static func formatWeight(_ weight: Double) -> String {
        weight.rounded() == weight ? "\(Int(weight))" : String(format: "%.1f", weight)
    }
}
