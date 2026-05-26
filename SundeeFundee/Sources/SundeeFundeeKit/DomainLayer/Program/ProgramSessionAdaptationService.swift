import Foundation

public struct ProgramSessionAdaptationContext: Sendable {
    public let cyclePhase: CyclePhase?
    public let injuries: [Injury]
    public let recoveryScore: Int?
    public let painIntensity: Int?
    public let equipment: EquipmentAccess?
    public let cycleConfidence: Double?
    public let deloadRecommended: Bool
    public let recentEffortRPE: Int?

    public init(
        cyclePhase: CyclePhase? = nil,
        injuries: [Injury] = [],
        recoveryScore: Int? = nil,
        painIntensity: Int? = nil,
        equipment: EquipmentAccess? = nil,
        cycleConfidence: Double? = nil,
        deloadRecommended: Bool = false,
        recentEffortRPE: Int? = nil
    ) {
        self.cyclePhase = cyclePhase
        self.injuries = injuries
        self.recoveryScore = recoveryScore
        self.painIntensity = painIntensity
        self.equipment = equipment
        self.cycleConfidence = cycleConfidence
        self.deloadRecommended = deloadRecommended
        self.recentEffortRPE = recentEffortRPE
    }
}

public enum ProgramSessionAdaptationService {
    public static func adapt(
        _ exercises: [GeneratedProgramExercise],
        context: ProgramSessionAdaptationContext
    ) -> [GeneratedProgramExercise] {
        adaptWithSummary(exercises, context: context).exercises
    }

    public static func adaptWithSummary(
        _ exercises: [GeneratedProgramExercise],
        context: ProgramSessionAdaptationContext
    ) -> ProgramAdaptationResult {
        var changes: [ProgramAdaptationChange] = []

        let adapted = exercises.map { original -> GeneratedProgramExercise in
            var exercise = original

            if let equipment = context.equipment {
                let converted = EquipmentConversionService.convertProgramExercise(exercise, to: equipment)
                if let change = converted.change {
                    changes.append(
                        ProgramAdaptationChange(
                            reasonCode: .equipmentConversion,
                            exerciseName: change.toExercise,
                            detail: change.reason
                        )
                    )
                }
                exercise = converted.exercise
            }

            let injuryAdjusted = adaptForInjuries(exercise, injuries: context.injuries)
            if injuryAdjusted.exercise != exercise.exercise {
                changes.append(
                    ProgramAdaptationChange(
                        reasonCode: .injurySwap,
                        exerciseName: injuryAdjusted.exercise,
                        detail: "Exercise swapped to reduce contraindication risk."
                    )
                )
            }
            exercise = injuryAdjusted

            if let pain = context.painIntensity, pain >= 6 {
                let painAdjusted = applyPainAdjustment(exercise)
                if !isSameExercise(exercise, painAdjusted) {
                    changes.append(
                        ProgramAdaptationChange(
                            reasonCode: .painAdjustment,
                            exerciseName: painAdjusted.exercise,
                            detail: "Volume and loading reduced for recent pain."
                        )
                    )
                }
                exercise = painAdjusted
            }

            let readinessAdjusted = applyReadinessAdjustments(exercise, context: context)
            if !isSameExercise(exercise, readinessAdjusted) {
                let reason: ProgramAdaptationReasonCode = context.deloadRecommended ? .deloadAdjustment : .recoveryAdjustment
                changes.append(
                    ProgramAdaptationChange(
                        reasonCode: reason,
                        exerciseName: readinessAdjusted.exercise,
                        detail: context.deloadRecommended
                            ? "Deload recommendation reduced volume and intensity."
                            : "Recovery context reduced volume and intensity."
                    )
                )
            }
            exercise = readinessAdjusted

            let cycleAdjusted = adaptForCycle(
                exercise,
                phase: context.cyclePhase,
                confidence: context.cycleConfidence
            )
            if !isSameExercise(exercise, cycleAdjusted) {
                changes.append(
                    ProgramAdaptationChange(
                        reasonCode: .cycleAdjustment,
                        exerciseName: cycleAdjusted.exercise,
                        detail: "Cycle phase adjusted load, reps, or rest."
                    )
                )
            }
            return cycleAdjusted
        }

        let headline: String
        if changes.isEmpty {
            headline = "Session matches your base program."
        } else if context.deloadRecommended {
            headline = "Session adapted for active recovery and fatigue management."
        } else if context.recoveryScore != nil || context.painIntensity != nil {
            headline = "Session adapted to your current readiness and pain context."
        } else {
            headline = "Session adapted around cycle phase, injuries, and equipment."
        }

        return ProgramAdaptationResult(
            exercises: adapted,
            summary: ProgramAdaptationSummary(
                headline: headline,
                changes: changes
            )
        )
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

    private static func applyPainAdjustment(
        _ exercise: GeneratedProgramExercise
    ) -> GeneratedProgramExercise {
        GeneratedProgramExercise(
            exercise: exercise.exercise,
            sets: scaleSets(exercise.sets, multiplier: 0.90),
            reps: scaleReps(exercise.reps, multiplier: 0.90),
            percent1RM: exercise.percent1RM.map { $0 * 0.90 },
            restMinutes: exercise.restMinutes * 1.10,
            bodyweightOnly: exercise.bodyweightOnly
        )
    }

    private static func applyReadinessAdjustments(
        _ exercise: GeneratedProgramExercise,
        context: ProgramSessionAdaptationContext
    ) -> GeneratedProgramExercise {
        if context.deloadRecommended {
            return GeneratedProgramExercise(
                exercise: exercise.exercise,
                sets: scaleSets(exercise.sets, multiplier: 0.75),
                reps: scaleReps(exercise.reps, multiplier: 0.85),
                percent1RM: exercise.percent1RM.map { $0 * 0.80 },
                restMinutes: exercise.restMinutes * 1.20,
                bodyweightOnly: exercise.bodyweightOnly
            )
        }

        guard let recoveryScore = context.recoveryScore else { return exercise }
        if recoveryScore < 40 {
            return GeneratedProgramExercise(
                exercise: exercise.exercise,
                sets: scaleSets(exercise.sets, multiplier: 0.80),
                reps: scaleReps(exercise.reps, multiplier: 0.90),
                percent1RM: exercise.percent1RM.map { $0 * 0.85 },
                restMinutes: exercise.restMinutes * 1.15,
                bodyweightOnly: exercise.bodyweightOnly
            )
        }

        if recoveryScore < 70 {
            return GeneratedProgramExercise(
                exercise: exercise.exercise,
                sets: scaleSets(exercise.sets, multiplier: 0.92),
                reps: exercise.reps,
                percent1RM: exercise.percent1RM.map { $0 * 0.95 },
                restMinutes: exercise.restMinutes * 1.08,
                bodyweightOnly: exercise.bodyweightOnly
            )
        }

        return exercise
    }

    private static func adaptForCycle(
        _ exercise: GeneratedProgramExercise,
        phase: CyclePhase?,
        confidence: Double?
    ) -> GeneratedProgramExercise {
        guard let phase else { return exercise }

        let region = classifyExerciseRegion(exercise.exercise)
        let multipliers = resolvePhaseMultipliers(phase: phase, region: region)
        let confidenceScale = max(0.0, min(1.0, confidence ?? 1.0))
        let blend = 1.0 - ((1.0 - confidenceScale) * 0.5)

        return GeneratedProgramExercise(
            exercise: exercise.exercise,
            sets: scaleSets(exercise.sets, multiplier: lerp(1.0, multipliers.sets, blend)),
            reps: scaleReps(exercise.reps, multiplier: lerp(1.0, multipliers.reps, blend)),
            percent1RM: exercise.percent1RM.map { $0 * lerp(1.0, multipliers.load, blend) },
            restMinutes: exercise.restMinutes * lerp(1.0, restMultiplier(for: phase), blend),
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

    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    private static func isSameExercise(
        _ lhs: GeneratedProgramExercise,
        _ rhs: GeneratedProgramExercise
    ) -> Bool {
        lhs.exercise == rhs.exercise
            && lhs.sets == rhs.sets
            && lhs.reps == rhs.reps
            && lhs.percent1RM == rhs.percent1RM
            && abs(lhs.restMinutes - rhs.restMinutes) < 0.0001
            && lhs.bodyweightOnly == rhs.bodyweightOnly
    }
}
