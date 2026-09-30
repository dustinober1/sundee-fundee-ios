import Foundation

// MARK: - OverloadAction

public enum OverloadAction: String, Sendable, Codable, Equatable {
    case increaseWeight
    case increaseReps
    case maintain
    case deloadOrReset
}

// MARK: - ProgressiveOverloadResult

public struct ProgressiveOverloadResult: Sendable, Codable, Equatable, Identifiable {
    public var id: String { exerciseName }
    public let exerciseName: String
    public let action: OverloadAction
    public let previousWeight: Double
    public let recommendedWeight: Double
    public let previousReps: Int
    public let recommendedReps: Int
    public let weightIncrement: Double
    public let unit: WeightUnit
    public let reason: String
    public let consecutiveSuccesses: Int
    public let consecutiveFailures: Int
    public let averageRPE: Double?

    public init(
        exerciseName: String,
        action: OverloadAction,
        previousWeight: Double,
        recommendedWeight: Double,
        previousReps: Int,
        recommendedReps: Int,
        weightIncrement: Double,
        unit: WeightUnit,
        reason: String,
        consecutiveSuccesses: Int,
        consecutiveFailures: Int,
        averageRPE: Double? = nil
    ) {
        self.exerciseName = exerciseName
        self.action = action
        self.previousWeight = previousWeight
        self.recommendedWeight = recommendedWeight
        self.previousReps = previousReps
        self.recommendedReps = recommendedReps
        self.weightIncrement = weightIncrement
        self.unit = unit
        self.reason = reason
        self.consecutiveSuccesses = consecutiveSuccesses
        self.consecutiveFailures = consecutiveFailures
        self.averageRPE = averageRPE
    }
}

// MARK: - ProgressiveOverloadEngine

/// Pure domain service that analyzes completed workout history and set RPE logs
/// to provide progressive overload recommendations.
public enum ProgressiveOverloadEngine {

    // MARK: - Public API

    /// Evaluates workout history for a single exercise and generates a progressive overload recommendation.
    public static func evaluate(
        exerciseName: String,
        workouts: [Workout],
        effortLogs: [WorkoutEffortLog] = [],
        unit: WeightUnit = .lbs,
        primaryGoal: String? = nil
    ) -> ProgressiveOverloadResult? {
        let matchingWorkouts = workouts
            .filter { workout in
                workout.isComplete && workout.exercises.contains {
                    $0.name.caseInsensitiveCompare(exerciseName) == .orderedSame
                }
            }
            .sorted { $0.date > $1.date }

        guard !matchingWorkouts.isEmpty else { return nil }

        let recentSessions = Array(matchingWorkouts.prefix(5))

        struct SessionEvaluation {
            let exercise: Exercise
            let hitAllReps: Bool
            let averageRPE: Double?
            let isFailure: Bool
            let isSuccess: Bool
            let workingWeight: Double
            let workingReps: Int
        }

        let evaluations: [SessionEvaluation] = recentSessions.compactMap { session in
            guard let exercise = session.exercises.first(where: {
                $0.name.caseInsensitiveCompare(exerciseName) == .orderedSame
            }) else { return nil }

            let sets = exercise.targetSets
            let hitAllReps: Bool
            if sets.isEmpty {
                hitAllReps = false
            } else {
                hitAllReps = sets.allSatisfy { set in
                    let actualReps = set.actualReps ?? (set.isComplete ? set.reps : 0)
                    return actualReps >= set.reps && set.reps > 0
                }
            }

            let setIDs = Set(sets.map(\.id))
            var sessionLogs = effortLogs.filter { log in
                log.workoutID == session.id && (
                    (log.exerciseName.map { $0.caseInsensitiveCompare(exerciseName) == .orderedSame } ?? false) ||
                    (log.setID.map { setIDs.contains($0) } ?? false)
                )
            }
            if sessionLogs.isEmpty {
                sessionLogs = effortLogs.filter { log in
                    log.workoutID == session.id && log.exerciseName == nil && log.setID == nil
                }
            }

            let avgRPE: Double? = sessionLogs.isEmpty
                ? nil
                : Double(sessionLogs.map(\.rpe).reduce(0, +)) / Double(sessionLogs.count)

            let isFailure = !hitAllReps || (avgRPE != nil && avgRPE! >= 9.5)
            let isSuccess = hitAllReps && (avgRPE == nil || avgRPE! < 9.5)

            let completedWeights = sets.compactMap { $0.completedWeight }.filter { $0 > 0 }
            let workingWeight: Double
            if let maxCompleted = completedWeights.max() {
                workingWeight = maxCompleted
            } else {
                let prescribedWeights = sets.map(\.prescribedWeight).filter { $0 > 0 }
                workingWeight = prescribedWeights.max() ?? 0
            }

            let workingReps = sets.first(where: { $0.reps > 0 })?.reps
                ?? sets.first?.actualReps
                ?? 0

            return SessionEvaluation(
                exercise: exercise,
                hitAllReps: hitAllReps,
                averageRPE: avgRPE,
                isFailure: isFailure,
                isSuccess: isSuccess,
                workingWeight: workingWeight,
                workingReps: workingReps
            )
        }

        guard let latest = evaluations.first else { return nil }

        var consecutiveSuccesses = 0
        var consecutiveFailures = 0

        if latest.isSuccess {
            for eval in evaluations {
                if eval.isSuccess {
                    consecutiveSuccesses += 1
                } else {
                    break
                }
            }
        } else {
            for eval in evaluations {
                if eval.isFailure {
                    consecutiveFailures += 1
                } else {
                    break
                }
            }
        }

        let previousWeight = latest.workingWeight
        let previousReps = latest.workingReps
        let latestAvgRPE = latest.averageRPE
        let increment = weightIncrement(
            for: latest.exercise.name,
            category: latest.exercise.category,
            unit: unit,
            averageRPE: latestAvgRPE
        )

        // Decision Rules
        if consecutiveFailures >= 3 {
            let rawDeload = previousWeight * 0.90
            let recommendedWeight = roundToNearest(rawDeload, increment: increment)
            let reason = "Stalled for 3 consecutive sessions on \(exerciseName). A 10% reset to \(formatWeight(recommendedWeight)) \(unit.rawValue) will help rebuild momentum with clean form."
            return ProgressiveOverloadResult(
                exerciseName: exerciseName,
                action: .deloadOrReset,
                previousWeight: previousWeight,
                recommendedWeight: recommendedWeight,
                previousReps: previousReps,
                recommendedReps: previousReps,
                weightIncrement: increment,
                unit: unit,
                reason: reason,
                consecutiveSuccesses: 0,
                consecutiveFailures: consecutiveFailures,
                averageRPE: latestAvgRPE
            )
        } else if latest.isFailure {
            let reason = "Missed target reps or high strain on last session. Hold at \(formatWeight(previousWeight)) \(unit.rawValue) to solidify technique."
            return ProgressiveOverloadResult(
                exerciseName: exerciseName,
                action: .maintain,
                previousWeight: previousWeight,
                recommendedWeight: previousWeight,
                previousReps: previousReps,
                recommendedReps: previousReps,
                weightIncrement: increment,
                unit: unit,
                reason: reason,
                consecutiveSuccesses: 0,
                consecutiveFailures: consecutiveFailures,
                averageRPE: latestAvgRPE
            )
        } else {
            let isBodyweight = latest.exercise.bodyweight > 0 || previousWeight == 0
            if isBodyweight {
                let recommendedReps = previousReps + 1
                let reason = "Completed all sets of \(exerciseName). Add 1 rep per set for progressive overload."
                return ProgressiveOverloadResult(
                    exerciseName: exerciseName,
                    action: .increaseReps,
                    previousWeight: 0,
                    recommendedWeight: 0,
                    previousReps: previousReps,
                    recommendedReps: recommendedReps,
                    weightIncrement: increment,
                    unit: unit,
                    reason: reason,
                    consecutiveSuccesses: consecutiveSuccesses,
                    consecutiveFailures: 0,
                    averageRPE: latestAvgRPE
                )
            } else {
                let recommendedWeight = previousWeight + increment
                let avgRPENote: String
                if let rpe = latestAvgRPE {
                    let rounded = (rpe * 10).rounded() / 10
                    avgRPENote = " (RPE \(formatWeight(rounded)))"
                } else {
                    avgRPENote = ""
                }
                let reason = "Completed all \(previousReps) reps at \(formatWeight(previousWeight)) \(unit.rawValue)\(avgRPENote). Ready for +\(formatWeight(increment)) \(unit.rawValue) progressive overload."
                return ProgressiveOverloadResult(
                    exerciseName: exerciseName,
                    action: .increaseWeight,
                    previousWeight: previousWeight,
                    recommendedWeight: recommendedWeight,
                    previousReps: previousReps,
                    recommendedReps: previousReps,
                    weightIncrement: increment,
                    unit: unit,
                    reason: reason,
                    consecutiveSuccesses: consecutiveSuccesses,
                    consecutiveFailures: 0,
                    averageRPE: latestAvgRPE
                )
            }
        }
    }

    /// Evaluates progressive overload recommendations for all unique exercises across completed workouts.
    public static func evaluateAll(
        workouts: [Workout],
        effortLogs: [WorkoutEffortLog] = [],
        unit: WeightUnit = .lbs,
        primaryGoal: String? = nil
    ) -> [ProgressiveOverloadResult] {
        var seen = Set<String>()
        var uniqueNames: [String] = []

        for workout in workouts where workout.isComplete {
            for exercise in workout.exercises {
                let key = exercise.name.lowercased()
                if !seen.contains(key) {
                    seen.insert(key)
                    uniqueNames.append(exercise.name)
                }
            }
        }

        return uniqueNames.sorted().compactMap { name in
            evaluate(
                exerciseName: name,
                workouts: workouts,
                effortLogs: effortLogs,
                unit: unit,
                primaryGoal: primaryGoal
            )
        }
    }

    /// Determines the progressive overload weight increment for an exercise based on its movement type, category, unit, and RPE.
    public static func weightIncrement(
        for exerciseName: String,
        category: ExerciseCategory? = nil,
        unit: WeightUnit = .lbs,
        averageRPE: Double? = nil
    ) -> Double {
        let lower = exerciseName.lowercased()

        // Lower body compound (contains "squat", "deadlift", "hip thrust"):
        // 5 lbs (or 10 lbs if avg RPE <= 7.0); in kg: 2.5 kg (or 5.0 kg if avg RPE <= 7.0).
        if lower.contains("squat") || lower.contains("deadlift") || lower.contains("hip thrust") {
            let isLowRPE = averageRPE.map { $0 <= 7.0 } ?? false
            if unit == .kg {
                return isLowRPE ? 5.0 : 2.5
            } else {
                return isLowRPE ? 10.0 : 5.0
            }
        }

        // Isolation / Accessory (curls, extensions, lateral raises, flys, calves): 2.5 lbs / 1.25 kg.
        if category == .isolation || category == .accessory
            || lower.contains("curl")
            || lower.contains("extension")
            || lower.contains("lateral raise")
            || lower.contains("fly")
            || lower.contains("calf")
            || lower.contains("calves") {
            return unit == .kg ? 1.25 : 2.5
        }

        // Upper body compound (contains "bench", "press", "row", "pull-up", "chin-up"): 5 lbs / 2.5 kg.
        // Default: 5 lbs / 2.5 kg.
        return unit == .kg ? 2.5 : 5.0
    }

    /// Returns the recommended next working weight for an exercise, falling back to a default if no history exists.
    public static func nextWorkingWeight(
        for exerciseName: String,
        fallbackWeight: Double,
        workouts: [Workout],
        effortLogs: [WorkoutEffortLog] = [],
        unit: WeightUnit = .lbs
    ) -> Double {
        if let result = evaluate(
            exerciseName: exerciseName,
            workouts: workouts,
            effortLogs: effortLogs,
            unit: unit
        ) {
            return result.recommendedWeight
        }
        return fallbackWeight
    }

    // MARK: - Private Helpers

    private static func roundToNearest(_ value: Double, increment: Double) -> Double {
        guard increment > 0 else { return value.rounded() }
        let steps = (value / increment).rounded()
        let result = steps * increment
        return (result * 1000).rounded() / 1000
    }

    private static func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        } else {
            return "\(weight)"
        }
    }
}
