import Foundation

public struct PainAwareSubstitutionCandidate: Sendable, Equatable {
    public let substitution: SubstitutionRanker.RankedSubstitution
    public let reason: String
    public let confidence: Double

    public init(
        substitution: SubstitutionRanker.RankedSubstitution,
        reason: String,
        confidence: Double
    ) {
        self.substitution = substitution
        self.reason = reason
        self.confidence = confidence
    }
}

public enum PainAwareSubstitutionService {
    public static func rank(
        currentExercise: String,
        recentPainLogs: [DailyPainLog],
        injuries: [Injury],
        equipment: EquipmentAccess,
        limit: Int = 5
    ) -> [PainAwareSubstitutionCandidate] {
        let equipmentContext = equipmentContext(for: equipment)
        let generic = SubstitutionRanker.rank(
            substitutesFor: currentExercise,
            equipment: equipmentContext,
            limit: limit
        )
        guard !generic.isEmpty else { return [] }

        let affectedRegions = Set(
            recentPainLogs
                .filter { $0.intensity >= 4 }
                .flatMap { $0.bodyRegions.map(\.displayName) }
                + injuries.flatMap { $0.bodyRegions.map(\.displayName) }
        )

        return generic.map { candidate in
            let painReason = reason(
                currentExercise: currentExercise,
                affectedRegions: affectedRegions,
                painLogs: recentPainLogs
            )
            let boost = painReason == nil ? 0.0 : 0.15
            let adjusted = SubstitutionRanker.RankedSubstitution(
                exerciseName: candidate.exerciseName,
                category: candidate.category,
                score: min(1.0, candidate.score + boost),
                reason: painReason ?? candidate.reason
            )
            return PainAwareSubstitutionCandidate(
                substitution: adjusted,
                reason: painReason ?? candidate.reason,
                confidence: min(1.0, adjusted.score)
            )
        }
        .sorted { lhs, rhs in
            if lhs.reason.contains("logged recently") != rhs.reason.contains("logged recently") {
                return lhs.reason.contains("logged recently")
            }
            return lhs.confidence > rhs.confidence
        }
    }

    private static func reason(
        currentExercise: String,
        affectedRegions: Set<String>,
        painLogs: [DailyPainLog]
    ) -> String? {
        guard !affectedRegions.isEmpty || !painLogs.isEmpty else { return nil }
        let lower = currentExercise.lowercased()
        if lower.contains("squat") || lower.contains("lunge") || lower.contains("leg") {
            return "Knee or lower-body pain logged recently - this option keeps the session moving with less irritation risk."
        }
        if lower.contains("deadlift") || lower.contains("row") || lower.contains("hinge") {
            return "Back tightness or pain logged recently - consider reducing hinge stress today."
        }
        if lower.contains("press") || lower.contains("bench") || lower.contains("push") {
            return "Shoulder or upper-body pain logged recently - this is a more controlled alternative."
        }
        return "Pain logged recently - this alternative may be easier to manage today."
    }

    private static func equipmentContext(for equipment: EquipmentAccess) -> SubstitutionRanker.EquipmentContext {
        switch equipment {
        case .fullGym:
            return .fullGym
        case .homeDumbbells:
            return .homeDumbbells
        case .bodyweightOnly, .outdoor:
            return .bodyweightOnly
        case .kettlebellOnly:
            return SubstitutionRanker.EquipmentContext(
                hasBarbell: false,
                hasDumbbells: false,
                hasPullUpBar: false,
                hasMachines: false
            )
        }
    }
}
