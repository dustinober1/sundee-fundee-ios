import Foundation

enum WorkoutPostProcessor {

    static func process(
        raw: AIWorkoutOutput,
        context: WorkoutGenerationContext
    ) -> GeneratedWorkout {
        let questionnaire = QuestionnaireAnswers(
            timeMinutes: context.timeMinutes,
            focus: context.focus,
            energyLevel: context.energyLevel,
            equipment: context.equipment
        )

        let exercises = raw.exercises.map { aiExercise in
            var weightKg = calculateWeight(
                exerciseName: aiExercise.name,
                reps: aiExercise.reps,
                bodyweightOnly: aiExercise.bodyweightOnly,
                maxes: context.maxes
            )

            if let w = weightKg {
                weightKg = applyEnergyMultiplier(w, energy: context.energyLevel)
                weightKg = applyCyclePhaseMultiplier(weightKg!, phase: context.cyclePhase, readiness: context.readinessTier)
                weightKg = WeightCalculations.roundToNearestFive(weightKg!)
            }

            let restMinutes = assignRestMinutes(reps: aiExercise.reps, bodyweight: aiExercise.bodyweightOnly)

            return GeneratedExercise(
                name: aiExercise.name,
                sets: aiExercise.sets,
                reps: aiExercise.reps,
                weightKg: weightKg,
                restMinutes: restMinutes,
                notes: aiExercise.notes,
                reasoning: nil,
                bodyweightOnly: aiExercise.bodyweightOnly
            )
        }

        let enrichedSummary = enrichCoachingSummary(
            base: raw.coachingSummary,
            energy: context.energyLevel,
            cyclePhase: context.cyclePhase
        )

        return GeneratedWorkout(
            createdAt: Date(),
            coachingSummary: enrichedSummary,
            exercises: exercises,
            questionnaire: questionnaire
        )
    }

    // MARK: - Weight Calculation

    private static func calculateWeight(
        exerciseName: String,
        reps: String,
        bodyweightOnly: Bool,
        maxes: [ExerciseMax]
    ) -> Double? {
        guard !bodyweightOnly else { return nil }
        guard let matched = findMatchingMax(exerciseName: exerciseName, maxes: maxes) else { return nil }
        let percentage = defaultPercentage(for: reps)
        return matched.weightKg * percentage
    }

    static func findMatchingMax(exerciseName: String, maxes: [ExerciseMax]) -> ExerciseMax? {
        let lower = exerciseName.lowercased()
        if let exact = maxes.first(where: { $0.name.lowercased() == lower }) {
            return exact
        }
        return maxes.first(where: {
            $0.name.lowercased().contains(lower) || lower.contains($0.name.lowercased())
        })
    }

    static func defaultPercentage(for reps: String) -> Double {
        let repCount = Int(reps.split(separator: "-").first ?? "") ?? 10
        switch repCount {
        case 1...3: return 0.85
        case 4...5: return 0.80
        case 6...8: return 0.70
        case 9...12: return 0.65
        default: return 0.60
        }
    }

    // MARK: - Rest Periods

    static func assignRestMinutes(reps: String, bodyweight: Bool) -> Double {
        if bodyweight { return 1.0 }
        let repCount = Int(reps.split(separator: "-").first ?? "") ?? 10
        switch repCount {
        case 1...5: return 2.5
        case 6...8: return 2.0
        case 9...12: return 1.5
        default: return 1.0
        }
    }

    // MARK: - Energy Multiplier

    static func applyEnergyMultiplier(_ weight: Double, energy: EnergyLevel) -> Double {
        let multiplier: Double = switch energy {
        case .low: 0.85
        case .medium: 1.0
        case .high: 1.05
        }
        return weight * multiplier
    }

    // MARK: - Cycle Phase Multiplier

    static func applyCyclePhaseMultiplier(_ weight: Double, phase: String?, readiness: String?) -> Double {
        guard let phase else { return weight }
        let phaseMultiplier: Double = switch phase.lowercased() {
        case "menstrual": 0.90
        case "follicular": 1.00
        case "ovulation": 1.12
        case "luteal": 0.97
        default: 1.00
        }
        let readinessMultiplier: Double = switch readiness?.lowercased() {
        case "low": 0.85
        case "high": 1.10
        default: 1.0
        }
        return weight * phaseMultiplier * readinessMultiplier
    }

    // MARK: - Coaching Summary

    static func enrichCoachingSummary(base: String, energy: EnergyLevel, cyclePhase: String?) -> String {
        var parts = [base]
        switch energy {
        case .low:
            parts.append("Weights adjusted for low energy today.")
        case .high:
            parts.append("Weights pushed slightly for high energy.")
        case .medium:
            break
        }
        if let phase = cyclePhase, phase.lowercased() != "follicular" {
            parts.append("Adjusted for \(phase.lowercased()) phase.")
        }
        return parts.joined(separator: " ")
    }
}
