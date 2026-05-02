import Foundation

public struct ProgramSessionAdaptationContext: Sendable {
    public let cyclePhase: CyclePhase?
    public let injuries: [Injury]

    public init(cyclePhase: CyclePhase? = nil, injuries: [Injury] = []) {
        self.cyclePhase = cyclePhase
        self.injuries = injuries
    }
}

public enum ProgramSessionAdaptationService {
    public static func adapt(
        _ exercises: [GeneratedProgramExercise],
        context: ProgramSessionAdaptationContext
    ) -> [GeneratedProgramExercise] {
        exercises.map { exercise in
            let injuryAdjusted = adaptForInjuries(exercise, injuries: context.injuries)
            return adaptForCycle(injuryAdjusted, phase: context.cyclePhase)
        }
    }

    private static func adaptForInjuries(
        _ exercise: GeneratedProgramExercise,
        injuries: [Injury]
    ) -> GeneratedProgramExercise {
        guard InjuryAdaptationEngine.isContraindicated(
            exerciseName: exercise.exercise,
            exerciseCategory: nil,
            injuries: injuries
        ) else {
            return exercise
        }

        let replacement = InjuryAdaptationEngine.getRegressions(
            exerciseName: exercise.exercise,
            injuries: injuries
        )
        .first { candidate in
            !InjuryAdaptationEngine.isContraindicated(
                exerciseName: candidate,
                exerciseCategory: nil,
                injuries: injuries
            )
        } ?? injuries
            .flatMap(InjuryAdaptationEngine.getRecommendedExercises)
            .first { candidate in
                !InjuryAdaptationEngine.isContraindicated(
                    exerciseName: candidate,
                    exerciseCategory: nil,
                    injuries: injuries
                )
            } ?? exercise.exercise

        return GeneratedProgramExercise(
            exercise: replacement,
            sets: exercise.sets,
            reps: exercise.reps,
            percent1RM: nil,
            restMinutes: exercise.restMinutes,
            bodyweightOnly: isBodyweightSafe(replacement)
        )
    }

    private static func adaptForCycle(
        _ exercise: GeneratedProgramExercise,
        phase: CyclePhase?
    ) -> GeneratedProgramExercise {
        guard let phase else { return exercise }

        let region = classifyExerciseRegion(exercise.exercise)
        let multipliers = resolvePhaseMultipliers(phase: phase, region: region)

        return GeneratedProgramExercise(
            exercise: exercise.exercise,
            sets: scaleSets(exercise.sets, multiplier: multipliers.sets),
            reps: scaleReps(exercise.reps, multiplier: multipliers.reps),
            percent1RM: exercise.percent1RM.map { $0 * multipliers.load },
            restMinutes: exercise.restMinutes * restMultiplier(for: phase),
            bodyweightOnly: exercise.bodyweightOnly
        )
    }

    private static func scaleSets(_ value: ExerciseValue, multiplier: Double) -> ExerciseValue {
        switch value {
        case .fixed(let count):
            return .fixed(value: clampedInt(Double(count) * multiplier, min: 1, max: 8))
        case .range(let low, let high):
            return .range(
                low: clampedInt(Double(low) * multiplier, min: 1, max: 8),
                high: clampedInt(Double(high) * multiplier, min: 1, max: 10)
            )
        case .amrap, .text:
            return value
        }
    }

    private static func scaleReps(_ value: ExerciseValue, multiplier: Double) -> ExerciseValue {
        switch value {
        case .fixed(let count):
            return .fixed(value: clampedInt(Double(count) * multiplier, min: 1, max: 50))
        case .range(let low, let high):
            return .range(
                low: clampedInt(Double(low) * multiplier, min: 1, max: 50),
                high: clampedInt(Double(high) * multiplier, min: 1, max: 60)
            )
        case .amrap, .text:
            return value
        }
    }

    private static func restMultiplier(for phase: CyclePhase) -> Double {
        switch phase {
        case .menstrual:
            return 1.20
        case .luteal:
            return 1.15
        case .ovulation:
            return 1.05
        case .follicular:
            return 1.0
        }
    }

    private static func clampedInt(_ value: Double, min: Int, max: Int) -> Int {
        Swift.max(min, Swift.min(max, Int(value.rounded())))
    }

    private static func isBodyweightSafe(_ exerciseName: String) -> Bool {
        let lower = exerciseName.lowercased()
        return lower.contains("air squat")
            || lower.contains("push-up")
            || lower.contains("plank")
            || lower.contains("bird dog")
            || lower.contains("cat-cow")
            || lower.contains("step-up")
            || lower.contains("glute bridge")
            || lower.contains("lateral raise")
            || lower.contains("band")
    }
}
