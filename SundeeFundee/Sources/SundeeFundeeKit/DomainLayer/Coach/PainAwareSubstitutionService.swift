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

        let policy = JointPainSubstitutionPolicyService.resolve(
            currentExercise: currentExercise,
            recentPainLogs: recentPainLogs,
            injuries: injuries
        )

        return generic.map { candidate in
            let pattern = movementPattern(for: candidate.exerciseName)
            var boost = 0.0
            if policy.primaryRegionKey != nil, policy.preferredPatterns.contains(pattern) {
                boost += 0.15
            }
            if policy.primaryRegionKey != nil, policy.avoidedPatterns.contains(pattern) {
                boost -= 0.30
            }
            let adjusted = SubstitutionRanker.RankedSubstitution(
                exerciseName: candidate.exerciseName,
                category: candidate.category,
                score: min(1.0, candidate.score + boost),
                reason: resolvedReason(
                    policy: policy,
                    pattern: pattern,
                    fallback: candidate.reason
                )
            )
            return PainAwareSubstitutionCandidate(
                substitution: adjusted,
                reason: adjusted.reason,
                confidence: min(1.0, adjusted.score)
            )
        }
        .sorted { lhs, rhs in
            if lhs.confidence == rhs.confidence {
                return lhs.reason < rhs.reason
            }
            return lhs.confidence > rhs.confidence
        }
    }

    private static func resolvedReason(
        policy: JointPainSubstitutionPolicy,
        pattern: WorkoutMovementPattern,
        fallback: String
    ) -> String {
        guard let policyReason = policy.reason else {
            return fallback
        }

        if policy.avoidedPatterns.contains(pattern) {
            return "\(policyReason) This choice may still stress the irritated region, so keep it light."
        }
        if policy.preferredPatterns.contains(pattern) {
            return "\(policyReason) This pattern is a better fit for today's pain log."
        }
        return policyReason
    }

    private static func movementPattern(for exerciseName: String) -> WorkoutMovementPattern {
        if let definition = trainingExerciseCatalog.first(where: {
            $0.id.compare(exerciseName, options: [.caseInsensitive]) == .orderedSame
        }) {
            return definition.movementPattern
        }

        let lower = exerciseName.lowercased()
        if lower.contains("squat") || lower.contains("lunge") || lower.contains("step") {
            return .squat
        }
        if lower.contains("deadlift") || lower.contains("hinge") || lower.contains("good morning") || lower.contains("swing") {
            return .hinge
        }
        if lower.contains("press") || lower.contains("push") {
            return .push
        }
        if lower.contains("pull") || lower.contains("row") || lower.contains("curl") {
            return .pull
        }
        if lower.contains("plank") || lower.contains("core") || lower.contains("dead bug") {
            return .core
        }
        if lower.contains("carry") {
            return .carry
        }
        return .conditioning
    }

    private static func equipmentContext(for equipment: EquipmentAccess) -> SubstitutionRanker.EquipmentContext {
        switch equipment {
        case .fullGym:
            return .fullGym
        case .homeDumbbells:
            return .homeDumbbells
        case .bodyweightOnly, .outdoor:
            return .bodyweightOnly
        case .resistanceBands:
            return .resistanceBands
        case .kettlebellOnly:
            return .kettlebellOnly
        }
    }
}
