import Foundation

public struct EquipmentConversionChange: Sendable, Equatable, Identifiable {
    public let id: String
    public let fromExercise: String
    public let toExercise: String
    public let reason: String

    public init(fromExercise: String, toExercise: String, reason: String) {
        self.id = fromExercise + "->" + toExercise
        self.fromExercise = fromExercise
        self.toExercise = toExercise
        self.reason = reason
    }
}

public struct EquipmentConvertedWorkout: Sendable, Equatable {
    public let workout: Workout
    public let changes: [EquipmentConversionChange]

    public init(workout: Workout, changes: [EquipmentConversionChange]) {
        self.workout = workout
        self.changes = changes
    }
}

public enum EquipmentConversionService {
    public static func convert(
        workout: Workout,
        to equipment: EquipmentAccess
    ) -> EquipmentConvertedWorkout {
        var changes: [EquipmentConversionChange] = []
        var updated = workout
        updated.exercises = workout.exercises.map { exercise in
            let converted = convertExerciseName(exercise.name, to: equipment)
            guard let converted, converted != exercise.name else {
                return exercise
            }
            changes.append(
                EquipmentConversionChange(
                    fromExercise: exercise.name,
                    toExercise: converted,
                    reason: "Converted for \(equipment.displayName.lowercased()) access."
                )
            )
            var copied = exercise
            copied.name = converted
            copied.bodyweight = isBodyweightExercise(converted) ? 1.0 : copied.bodyweight
            return copied
        }
        return EquipmentConvertedWorkout(workout: updated, changes: changes)
    }

    public static func convertProgramExercise(
        _ exercise: GeneratedProgramExercise,
        to equipment: EquipmentAccess
    ) -> (exercise: GeneratedProgramExercise, change: EquipmentConversionChange?) {
        let convertedName = convertExerciseName(exercise.exercise, to: equipment)
        guard let convertedName, convertedName != exercise.exercise else {
            return (exercise, nil)
        }

        let converted = GeneratedProgramExercise(
            exercise: convertedName,
            sets: exercise.sets,
            reps: exercise.reps,
            percent1RM: isBodyweightExercise(convertedName) ? nil : exercise.percent1RM,
            restMinutes: exercise.restMinutes,
            bodyweightOnly: isBodyweightExercise(convertedName)
        )
        let change = EquipmentConversionChange(
            fromExercise: exercise.exercise,
            toExercise: convertedName,
            reason: "Converted for \(equipment.displayName.lowercased()) access."
        )
        return (converted, change)
    }

    public static func matchesEquipment(
        exerciseName: String,
        equipment: EquipmentAccess
    ) -> Bool {
        guard let definition = definition(for: exerciseName) else {
            return heuristicMatches(exerciseName: exerciseName, equipment: equipment)
        }
        let allowed = allowedTags(for: equipment)
        return !Set(definition.equipmentTags).isDisjoint(with: allowed)
    }

    public static func convertExerciseName(
        _ exerciseName: String,
        to equipment: EquipmentAccess
    ) -> String? {
        if matchesEquipment(exerciseName: exerciseName, equipment: equipment) {
            return exerciseName
        }

        let rankContext = substitutionContext(for: equipment)
        if let ranked = SubstitutionRanker.rank(
            substitutesFor: exerciseName,
            equipment: rankContext,
            limit: 8
        ).first(where: { matchesEquipment(exerciseName: $0.exerciseName, equipment: equipment) }) {
            return ranked.exerciseName
        }

        let pattern = definition(for: exerciseName)?.movementPattern ?? inferredMovementPattern(for: exerciseName)
        let allowed = allowedTags(for: equipment)
        if let fallback = trainingExerciseCatalog.first(where: {
            $0.movementPattern == pattern && !Set($0.equipmentTags).isDisjoint(with: allowed)
        }) {
            return fallback.id
        }

        return nil
    }

    // MARK: - Helpers

    private static func definition(for exerciseName: String) -> TrainingExerciseDefinition? {
        trainingExerciseCatalog.first {
            $0.id.compare(exerciseName, options: [.caseInsensitive]) == .orderedSame
        }
    }

    private static func allowedTags(for equipment: EquipmentAccess) -> Set<TrainingEquipmentTag> {
        switch equipment {
        case .fullGym:
            return Set(TrainingEquipmentTag.allCases)
        case .homeDumbbells:
            return [.dumbbells, .bodyweight, .bands]
        case .resistanceBands:
            return [.bands, .bodyweight]
        case .bodyweightOnly:
            return [.bodyweight]
        case .kettlebellOnly:
            return [.kettlebell, .bodyweight]
        case .outdoor:
            return [.bodyweight, .cardio, .box]
        }
    }

    private static func substitutionContext(for equipment: EquipmentAccess) -> SubstitutionRanker.EquipmentContext {
        switch equipment {
        case .fullGym:
            return .fullGym
        case .homeDumbbells:
            return .homeDumbbells
        case .resistanceBands:
            return .resistanceBands
        case .bodyweightOnly, .outdoor:
            return .bodyweightOnly
        case .kettlebellOnly:
            return .kettlebellOnly
        }
    }

    private static func heuristicMatches(
        exerciseName: String,
        equipment: EquipmentAccess
    ) -> Bool {
        let lower = exerciseName.lowercased()
        switch equipment {
        case .fullGym:
            return true
        case .homeDumbbells:
            return lower.contains("dumbbell") || lower.contains("bodyweight") || lower.contains("push-up")
        case .resistanceBands:
            return lower.contains("band") || lower.contains("bodyweight") || lower.contains("push-up")
        case .bodyweightOnly:
            return lower.contains("push-up") || lower.contains("air squat") || lower.contains("plank") || lower.contains("bodyweight") || lower.contains("walking")
        case .kettlebellOnly:
            return lower.contains("kettlebell") || lower.contains("bodyweight")
        case .outdoor:
            return lower.contains("run") || lower.contains("walk") || lower.contains("bodyweight")
        }
    }

    private static func inferredMovementPattern(for exerciseName: String) -> WorkoutMovementPattern {
        let lower = exerciseName.lowercased()
        if lower.contains("squat") || lower.contains("lunge") || lower.contains("step") {
            return .squat
        }
        if lower.contains("deadlift") || lower.contains("hinge") || lower.contains("good morning") || lower.contains("swing") {
            return .hinge
        }
        if lower.contains("press") || lower.contains("push") || lower.contains("dip") {
            return .push
        }
        if lower.contains("row") || lower.contains("pull") || lower.contains("curl") {
            return .pull
        }
        if lower.contains("carry") {
            return .carry
        }
        if lower.contains("plank") || lower.contains("dead bug") || lower.contains("core") {
            return .core
        }
        return .conditioning
    }

    private static func isBodyweightExercise(_ exerciseName: String) -> Bool {
        let lower = exerciseName.lowercased()
        return lower.contains("push-up")
            || lower.contains("air squat")
            || lower.contains("plank")
            || lower.contains("walking")
            || lower.contains("bird dog")
            || lower.contains("cat-cow")
            || lower.contains("bodyweight")
    }
}
