import Foundation

public struct StartingWeightSuggestion: Sendable, Equatable, Identifiable {
    public let id: String
    public let exerciseName: String
    public let suggestedWeight: Double?
    public let unit: WeightUnit
    public let confidence: Double
    public let reason: String
    public let canIncreaseAfterFirstSet: Bool
    public let repsGuidance: String?

    public init(
        exerciseName: String,
        suggestedWeight: Double?,
        unit: WeightUnit,
        confidence: Double,
        reason: String,
        canIncreaseAfterFirstSet: Bool,
        repsGuidance: String? = nil
    ) {
        self.id = exerciseName
        self.exerciseName = exerciseName
        self.suggestedWeight = suggestedWeight
        self.unit = unit
        self.confidence = confidence
        self.reason = reason
        self.canIncreaseAfterFirstSet = canIncreaseAfterFirstSet
        self.repsGuidance = repsGuidance
    }
}

public enum StartingWeightCalibrationService {
    public static func suggestions(
        for workout: Workout,
        maxRecords: [OneRepMaxRecord],
        experienceLevel: ExperienceLevel,
        unit: WeightUnit = .lbs,
        recentWorkouts: [Workout] = [],
        effortLogs: [WorkoutEffortLog] = []
    ) -> [StartingWeightSuggestion] {
        workout.exercises.map {
            suggestion(
                for: $0,
                maxRecords: maxRecords,
                experienceLevel: experienceLevel,
                unit: unit,
                recentWorkouts: recentWorkouts,
                effortLogs: effortLogs
            )
        }
    }

    public static func suggestion(
        for exercise: Exercise,
        maxRecords: [OneRepMaxRecord],
        experienceLevel: ExperienceLevel,
        unit: WeightUnit = .lbs,
        recentWorkouts: [Workout] = [],
        effortLogs: [WorkoutEffortLog] = []
    ) -> StartingWeightSuggestion {
        if exercise.bodyweight > 0 || isBodyweightExercise(exercise.name) {
            return StartingWeightSuggestion(
                exerciseName: exercise.name,
                suggestedWeight: nil,
                unit: unit,
                confidence: 0.95,
                reason: "Bodyweight movement. Start controlled and stop 2-3 reps before failure.",
                canIncreaseAfterFirstSet: true,
                repsGuidance: "If the first set feels easy, add reps slowly across sets."
            )
        }

        let overloadResult = ProgressiveOverloadEngine.evaluate(
            exerciseName: exercise.name,
            workouts: recentWorkouts,
            effortLogs: effortLogs,
            unit: unit
        )

        let base: Double
        let baseConfidence: Double
        let reason: String
        let isOverload: Bool

        if let overloadResult {
            base = overloadResult.recommendedWeight
            baseConfidence = 0.90
            reason = overloadResult.reason
            isOverload = true
        } else {
            let maybeMax = maxRecords
                .filter { $0.exerciseName.caseInsensitiveCompare(exercise.name) == .orderedSame }
                .max(by: { $0.date < $1.date })

            if let maybeMax {
                let reps = exercise.targetSets.first?.reps ?? 5
                let percentage = recommendedPercentage(for: reps, experienceLevel: experienceLevel)
                base = maybeMax.weight * percentage
                baseConfidence = 0.85
                reason = "Based on your latest \(exercise.name) max and target reps."
            } else {
                base = defaultStarterWeight(for: experienceLevel, category: exercise.category)
                baseConfidence = 0.45
                reason = "No max found. Starting with a conservative entry weight."
            }
            isOverload = false
        }

        return StartingWeightSuggestion(
            exerciseName: exercise.name,
            suggestedWeight: isOverload ? base : roundToNearestFive(base),
            unit: unit,
            confidence: baseConfidence,
            reason: reason,
            canIncreaseAfterFirstSet: true,
            repsGuidance: nil
        )
    }

    private static func recommendedPercentage(
        for reps: Int,
        experienceLevel: ExperienceLevel
    ) -> Double {
        let base: Double
        switch reps {
        case ...5:
            base = 0.80
        case 6...8:
            base = 0.72
        case 9...12:
            base = 0.65
        default:
            base = 0.55
        }
        switch experienceLevel {
        case .beginner:
            return base - 0.08
        case .intermediate:
            return base - 0.03
        case .advanced:
            return base
        }
    }

    private static func defaultStarterWeight(
        for experienceLevel: ExperienceLevel,
        category: ExerciseCategory
    ) -> Double {
        switch (experienceLevel, category) {
        case (.beginner, .compound):
            return 45
        case (.beginner, .isolation), (.beginner, .accessory):
            return 10
        case (.beginner, .warmup), (.beginner, .cooldown):
            return 0
        case (.intermediate, .compound):
            return 65
        case (.intermediate, .isolation), (.intermediate, .accessory):
            return 20
        case (.intermediate, .warmup), (.intermediate, .cooldown):
            return 0
        case (.advanced, .compound):
            return 95
        case (.advanced, .isolation), (.advanced, .accessory):
            return 30
        case (.advanced, .warmup), (.advanced, .cooldown):
            return 0
        }
    }

    private static func roundToNearestFive(_ value: Double) -> Double {
        (value / 5.0).rounded() * 5.0
    }

    private static func isBodyweightExercise(_ exerciseName: String) -> Bool {
        if let entry = lookupExerciseCatalogEntry(exerciseName) {
            return entry.bodyweightOnly || (entry.equipmentTags.contains(.bodyweight) && entry.equipmentTags.count == 1)
        }
        let lower = exerciseName.lowercased()
        return lower.contains("push-up")
            || lower.contains("air squat")
            || lower.contains("plank")
            || lower.contains("sit-up")
            || lower.contains("walking")
            || lower.contains("bird dog")
    }
}
