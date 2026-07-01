import Foundation

public struct WorkoutTrustBadge: Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let systemImage: String

    public init(title: String, detail: String, systemImage: String) {
        self.id = title + detail
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
    }
}

public enum WorkoutTrustBadgeBuilder {
    public static func badges(
        reasons: [String],
        cyclePhase: CyclePhase?,
        cycleConfidence: Double?,
        deloadRecommended: Bool
    ) -> [WorkoutTrustBadge] {
        var badges: [WorkoutTrustBadge] = []

        if deloadRecommended {
            badges.append(WorkoutTrustBadge(
                title: "Protected recovery",
                detail: "Active recovery is recommended today",
                systemImage: "heart.text.square"
            ))
        }

        let joined = reasons.joined(separator: " ").lowercased()
        if joined.contains("energy") {
            badges.append(WorkoutTrustBadge(
                title: "Energy",
                detail: "Adjusted for today's energy",
                systemImage: "bolt"
            ))
        }
        if joined.contains("equipment") {
            badges.append(WorkoutTrustBadge(
                title: "Equipment",
                detail: "Matched to available gear",
                systemImage: "dumbbell"
            ))
        }
        if joined.contains("recovery") || joined.contains("rest") {
            badges.append(WorkoutTrustBadge(
                title: "Recovery",
                detail: "Recovery load is accounted for",
                systemImage: "leaf"
            ))
        }
        if cyclePhase != nil {
            badges.append(WorkoutTrustBadge(
                title: "Cycle estimate",
                detail: confidenceLabel(cycleConfidence),
                systemImage: "moon.circle"
            ))
        }

        return orderedUnique(badges)
    }

    private static func confidenceLabel(_ confidence: Double?) -> String {
        guard let confidence else { return "No confidence score" }
        switch confidence {
        case 0.80...1.0:
            return "High confidence"
        case 0.50..<0.80:
            return "Medium confidence"
        default:
            return "Low confidence"
        }
    }

    private static func orderedUnique(_ badges: [WorkoutTrustBadge]) -> [WorkoutTrustBadge] {
        var seen = Set<String>()
        return badges.filter { badge in
            if seen.contains(badge.title) { return false }
            seen.insert(badge.title)
            return true
        }
    }
}
