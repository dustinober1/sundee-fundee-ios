import Foundation

public struct JointPainSubstitutionPolicy: Sendable, Equatable {
    public let primaryRegionKey: String?
    public let preferredPatterns: Set<WorkoutMovementPattern>
    public let avoidedPatterns: Set<WorkoutMovementPattern>
    public let reason: String?

    public init(
        primaryRegionKey: String?,
        preferredPatterns: Set<WorkoutMovementPattern>,
        avoidedPatterns: Set<WorkoutMovementPattern>,
        reason: String?
    ) {
        self.primaryRegionKey = primaryRegionKey
        self.preferredPatterns = preferredPatterns
        self.avoidedPatterns = avoidedPatterns
        self.reason = reason
    }
}

public enum JointPainSubstitutionPolicyService {
    public static func resolve(
        currentExercise: String,
        recentPainLogs: [DailyPainLog],
        injuries: [Injury]
    ) -> JointPainSubstitutionPolicy {
        let activeRegions = Set(
            recentPainLogs
                .filter { $0.intensity >= 4 }
                .flatMap { $0.bodyRegions.map(\.engineKey) }
            + injuries
                .filter { $0.recoveryPhase != .resolved }
                .flatMap { $0.bodyRegions.map(\.engineKey) }
        )

        let currentPattern = movementPattern(for: currentExercise)

        if activeRegions.contains("knee") {
            return JointPainSubstitutionPolicy(
                primaryRegionKey: "knee",
                preferredPatterns: [.hinge, .core, .pull],
                avoidedPatterns: [.squat],
                reason: "Knee pain was logged recently. Favor lower-impact alternatives."
            )
        }

        if activeRegions.contains("back") {
            return JointPainSubstitutionPolicy(
                primaryRegionKey: "back",
                preferredPatterns: [.core, .push],
                avoidedPatterns: [.hinge],
                reason: "Back pain was logged recently. Reduce hinge and spinal loading."
            )
        }

        if activeRegions.contains("shoulder") {
            return JointPainSubstitutionPolicy(
                primaryRegionKey: "shoulder",
                preferredPatterns: [.squat, .core, .hinge],
                avoidedPatterns: [.push],
                reason: "Shoulder pain was logged recently. Favor non-pressing movements."
            )
        }

        if activeRegions.contains("wrist") || activeRegions.contains("elbow") {
            return JointPainSubstitutionPolicy(
                primaryRegionKey: activeRegions.contains("wrist") ? "wrist" : "elbow",
                preferredPatterns: [.squat, .core],
                avoidedPatterns: [.push, .pull],
                reason: "Arm-joint pain was logged recently. Favor lower-body and trunk work."
            )
        }

        if activeRegions.contains("hip") {
            return JointPainSubstitutionPolicy(
                primaryRegionKey: "hip",
                preferredPatterns: [.core, .pull],
                avoidedPatterns: [.squat, .hinge],
                reason: "Hip pain was logged recently. Reduce deep flexion and heavy lower-body loading."
            )
        }

        return JointPainSubstitutionPolicy(
            primaryRegionKey: nil,
            preferredPatterns: [currentPattern],
            avoidedPatterns: [],
            reason: nil
        )
    }

    private static func movementPattern(for exerciseName: String) -> WorkoutMovementPattern {
        let lower = exerciseName.lowercased()
        if lower.contains("squat") || lower.contains("lunge") || lower.contains("step") {
            return .squat
        }
        if lower.contains("deadlift") || lower.contains("hinge") || lower.contains("good morning") {
            return .hinge
        }
        if lower.contains("press") || lower.contains("push") {
            return .push
        }
        if lower.contains("row") || lower.contains("pull") || lower.contains("curl") {
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
}
