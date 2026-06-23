import Foundation

public struct RestGuidanceContext: Sendable, Equatable {
    public let exercise: Exercise
    public let completedSet: ExerciseSet
    public let lastRPE: Int?

    public init(
        exercise: Exercise,
        completedSet: ExerciseSet,
        lastRPE: Int?
    ) {
        self.exercise = exercise
        self.completedSet = completedSet
        self.lastRPE = lastRPE
    }
}

public struct RestGuidance: Sendable, Equatable {
    public let seconds: Int
    public let reason: String
    public let allowsSkip: Bool

    public init(seconds: Int, reason: String, allowsSkip: Bool) {
        self.seconds = seconds
        self.reason = reason
        self.allowsSkip = allowsSkip
    }
}

public enum RestGuidanceService {
    public static func guidance(context: RestGuidanceContext) -> RestGuidance {
        let isConditioning = isConditioningWork(
            exercise: context.exercise,
            completedSet: context.completedSet
        )
        let missedReps = (context.completedSet.actualReps ?? context.completedSet.reps) < context.completedSet.reps
        let hardEffort = (context.lastRPE ?? 0) >= 9
        var seconds = baseSeconds(
            exercise: context.exercise,
            completedSet: context.completedSet,
            isConditioning: isConditioning
        )
        var reasons = baseReasons(
            exercise: context.exercise,
            completedSet: context.completedSet,
            isConditioning: isConditioning
        )

        if hardEffort {
            seconds += 45
            reasons.append("last set was hard")
        }

        if missedReps {
            seconds += isConditioning ? 45 : 60
            reasons.append("you missed reps")
        }

        seconds = min(seconds, 300)
        seconds = max(30, roundedToNearest15(seconds))

        return RestGuidance(
            seconds: seconds,
            reason: reasonText(seconds: seconds, reasons: reasons),
            allowsSkip: true
        )
    }

    private static func baseSeconds(
        exercise: Exercise,
        completedSet: ExerciseSet,
        isConditioning: Bool
    ) -> Int {
        if isConditioning {
            return 60
        }

        let prescribedSeconds = Int((exercise.restMinutes * 60).rounded())
        let categorySeconds: Int
        switch exercise.category {
        case .compound:
            categorySeconds = completedSet.reps <= 6 ? 180 : 150
        case .isolation:
            categorySeconds = 75
        case .accessory:
            categorySeconds = 90
        case .warmup:
            categorySeconds = 45
        case .cooldown:
            categorySeconds = 30
        }

        return max(categorySeconds, prescribedSeconds)
    }

    private static func baseReasons(
        exercise: Exercise,
        completedSet: ExerciseSet,
        isConditioning: Bool
    ) -> [String] {
        if isConditioning {
            return ["conditioning work stays short"]
        }

        switch exercise.category {
        case .compound where completedSet.reps <= 6:
            return ["heavy compound work needs more reset time"]
        case .compound:
            return ["compound work needs a steady reset"]
        case .isolation:
            return ["isolation work recovers faster"]
        case .accessory:
            return ["accessory work needs a moderate reset"]
        case .warmup:
            return ["warm-up work stays brief"]
        case .cooldown:
            return ["cool-down work stays brief"]
        }
    }

    private static func isConditioningWork(
        exercise: Exercise,
        completedSet: ExerciseSet
    ) -> Bool {
        let name = exercise.name.lowercased()
        let conditioningTerms = [
            "bike", "rower", "rowing", "row erg", "erg", "run", "sprint", "interval", "conditioning",
            "metcon", "emom", "amrap", "burpee", "jump rope"
        ]

        return conditioningTerms.contains(where: name.contains)
            || completedSet.type == .amrap && completedSet.reps >= 20
    }

    private static func roundedToNearest15(_ seconds: Int) -> Int {
        Int((Double(seconds) / 15.0).rounded()) * 15
    }

    private static func reasonText(seconds: Int, reasons: [String]) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        let duration: String
        if remainingSeconds == 0 {
            duration = "\(minutes) min"
        } else if minutes == 0 {
            duration = "\(remainingSeconds) sec"
        } else {
            duration = "\(minutes) min \(remainingSeconds) sec"
        }

        return "\(duration): \(reasons.joined(separator: ", "))."
    }
}
