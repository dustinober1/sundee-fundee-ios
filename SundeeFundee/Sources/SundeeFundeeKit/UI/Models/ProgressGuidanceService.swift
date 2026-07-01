import Foundation

public struct ProgressGuidanceItem: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let systemImage: String

    public init(title: String, subtitle: String, systemImage: String) {
        self.id = title
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

public enum ProgressGuidanceService {
    public static func guidance(
        input: ProgressDestinationInput,
        completedWorkoutCount: Int
    ) -> [ProgressGuidanceItem] {
        var items: [ProgressGuidanceItem] = []
        if !input.hasAnalytics {
            let remaining = max(0, 2 - completedWorkoutCount)
            items.append(ProgressGuidanceItem(
                title: remaining == 0 ? "Analytics are ready" : "Complete 2 workouts to unlock analytics",
                subtitle: remaining == 0
                    ? "Open analytics to review your training patterns."
                    : "\(remaining) more workout\(remaining == 1 ? "" : "s") to start trends.",
                systemImage: "chart.xyaxis.line"
            ))
        }
        if !input.hasMaxes {
            items.append(ProgressGuidanceItem(
                title: "Log your first max",
                subtitle: "Start strength trends with one lift.",
                systemImage: "scalemass"
            ))
        }
        if !input.hasBenchmarks {
            items.append(ProgressGuidanceItem(
                title: "Try a benchmark",
                subtitle: "Benchmarks make conditioning progress easier to compare.",
                systemImage: "trophy"
            ))
        }
        return items
    }
}
