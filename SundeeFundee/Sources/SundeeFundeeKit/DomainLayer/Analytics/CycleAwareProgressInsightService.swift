import Foundation

public struct CycleAwareProgressInsight: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let value: String
    public let subtitle: String

    public init(id: String, title: String, value: String, subtitle: String) {
        self.id = id
        self.title = title
        self.value = value
        self.subtitle = subtitle
    }
}

public enum CycleAwareProgressInsightService {
    public static func build(
        cycleData: [CyclePerformancePoint],
        workouts: [Workout],
        maxRecords: [OneRepMaxRecord]
    ) -> [CycleAwareProgressInsight] {
        let confidentPhases = cycleData.filter { $0.confidence >= 0.4 && $0.workoutCount >= 2 }
        guard !confidentPhases.isEmpty else {
            return [
                CycleAwareProgressInsight(
                    id: "needs-more-data",
                    title: "Cycle Insight Needs More Data",
                    value: "Log 2+ workouts per phase",
                    subtitle: "More phase-linked workouts are needed before trend guidance is reliable."
                )
            ]
        }

        let strongest = confidentPhases.max { $0.averageVolume < $1.averageVolume }
        let weakest = confidentPhases.min { $0.averageVolume < $1.averageVolume }

        var insights: [CycleAwareProgressInsight] = []
        if let strongest {
            insights.append(
                CycleAwareProgressInsight(
                    id: "strongest-phase",
                    title: "Strongest Phase",
                    value: phaseLabel(strongest.phase),
                    subtitle: "Highest average volume with \(strongest.workoutCount) tracked workouts."
                )
            )
        }

        if let weakest, weakest.phase != strongest?.phase {
            insights.append(
                CycleAwareProgressInsight(
                    id: "lowest-phase",
                    title: "Most Challenging Phase",
                    value: phaseLabel(weakest.phase),
                    subtitle: "Lowest average volume; consider pre-planned modifications in this window."
                )
            )
        }

        if let latestPR = maxRecords.max(by: { $0.date < $1.date }) {
            insights.append(
                CycleAwareProgressInsight(
                    id: "latest-pr",
                    title: "Latest PR Context",
                    value: latestPR.exerciseName,
                    subtitle: "Most recent max log: \(formatWeight(latestPR.weight)) \(latestPR.unit.rawValue)."
                )
            )
        } else {
            let completedCount = workouts.filter(\.isComplete).count
            insights.append(
                CycleAwareProgressInsight(
                    id: "consistency",
                    title: "Consistency Signal",
                    value: "\(completedCount) completed workouts",
                    subtitle: "Continue logging sessions to strengthen cycle-aware trend detection."
                )
            )
        }

        return Array(insights.prefix(3))
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
        if weight.rounded() == weight {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }
}
