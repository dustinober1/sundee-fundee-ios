import Foundation

public struct CycleAwareAdjustment: Sendable, Equatable {
    public let volumeMultiplier: Double
    public let restMultiplier: Double
    public let rationale: WorkoutRationale

    public init(volumeMultiplier: Double, restMultiplier: Double, rationale: WorkoutRationale) {
        self.volumeMultiplier = volumeMultiplier
        self.restMultiplier = restMultiplier
        self.rationale = rationale
    }
}

public enum CycleAwareAdjustmentService {
    public static func adjustment(
        phase: CyclePhase?,
        energyLevel: EnergyLevel,
        goal: String?,
        equipment: EquipmentAccess
    ) -> CycleAwareAdjustment {
        let phaseName = phase.map(displayName) ?? "No cycle phase selected"
        var reasons = [
            "Selected energy: \(energyLevel.rawValue.capitalized)",
            "Current phase: \(phaseName)",
            "Equipment: \(equipment.rawValue.replacingOccurrences(of: "_", with: " "))"
        ]
        if let goal, !goal.isEmpty {
            reasons.append("Goal: \(goal)")
        }

        switch phase {
        case .menstrual:
            return CycleAwareAdjustment(
                volumeMultiplier: energyLevel == .low ? 0.70 : 0.80,
                restMultiplier: 1.20,
                rationale: WorkoutRationale(
                    headline: "Lower intensity with more recovery room",
                    reasons: reasons + ["Adjustment: lower volume and longer rest"],
                    cautions: ["Override anytime if you feel ready for more."]
                )
            )
        case .follicular:
            return CycleAwareAdjustment(
                volumeMultiplier: energyLevel == .high ? 1.10 : 1.0,
                restMultiplier: 1.0,
                rationale: WorkoutRationale(
                    headline: "Strength emphasis with room to progress",
                    reasons: reasons + ["Adjustment: progressive overload focus"]
                )
            )
        case .ovulation:
            return CycleAwareAdjustment(
                volumeMultiplier: 1.05,
                restMultiplier: 1.05,
                rationale: WorkoutRationale(
                    headline: "PR-friendly session without chasing extra volume",
                    reasons: reasons + ["Adjustment: heavier focus with controlled volume"],
                    cautions: ["Keep form sharp and stop short of grinding reps."]
                )
            )
        case .luteal:
            return CycleAwareAdjustment(
                volumeMultiplier: energyLevel == .low ? 0.80 : 0.90,
                restMultiplier: 1.15,
                rationale: WorkoutRationale(
                    headline: "Moderate intensity with longer rest",
                    reasons: reasons + ["Adjustment: avoid aggressive overload today"]
                )
            )
        case nil:
            return CycleAwareAdjustment(
                volumeMultiplier: energyLevel == .low ? 0.85 : 1.0,
                restMultiplier: energyLevel == .low ? 1.10 : 1.0,
                rationale: WorkoutRationale(
                    headline: "Workout matched to your selected energy",
                    reasons: reasons + ["Adjustment: energy-based volume and rest"]
                )
            )
        }
    }

    public static func apply(_ adjustment: CycleAwareAdjustment, to workout: GeneratedWorkout) -> GeneratedWorkout {
        let exercises = workout.exercises.map { exercise in
            let adjustedSets = max(1, min(6, Int((Double(exercise.sets) * adjustment.volumeMultiplier).rounded())))
            let adjustedRest = (exercise.restMinutes ?? 1.5) * adjustment.restMultiplier
            return GeneratedExercise(
                id: exercise.id,
                name: exercise.name,
                sets: adjustedSets,
                reps: exercise.reps,
                weightKg: exercise.weightKg,
                restMinutes: adjustedRest,
                notes: exercise.notes,
                reasoning: exercise.reasoning,
                bodyweightOnly: exercise.bodyweightOnly,
                percentageOfMax: exercise.percentageOfMax
            )
        }
        return GeneratedWorkout(
            id: workout.id,
            createdAt: workout.createdAt,
            isFavorite: workout.isFavorite,
            coachingSummary: workout.coachingSummary,
            exercises: exercises,
            questionnaire: workout.questionnaire
        )
    }

    private static func displayName(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        }
    }
}
