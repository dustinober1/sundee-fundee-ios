import AppIntents
import Foundation
import os.log

private let intentLogger = Logger(subsystem: "com.sundeefundee.app", category: "Intents")

// MARK: - LogWorkoutSetIntent
//
// Siri/Shortcut for quickly logging a single set. Creates a "Quick Log"
// workout for today if none exists, or appends the exercise/set to the
// first incomplete workout from today.

@available(iOS 18.0, *)
public struct LogWorkoutSetIntent: AppIntent {
    public static let title: LocalizedStringResource = "Log a set"
    public static let description = IntentDescription("Log a set for today's workout.")

    @Parameter(title: "Exercise")
    public var exercise: ExerciseCatalogEntity

    @Parameter(title: "Weight")
    public var weight: Double

    @Parameter(title: "Reps")
    public var reps: Int

    public init() {}

    public init(exercise: ExerciseCatalogEntity, weight: Double, reps: Int) {
        self.exercise = exercise
        self.weight = weight
        self.reps = reps
    }

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let client = DataClientFactory.shared.client

        let todayStart = Calendar.current.startOfDay(for: Date())
        var workouts: [Workout] = []
        do {
            workouts = try await client.fetchAll(recordType: "Workout") as [Workout]
        } catch {
            intentLogger.error("LogWorkoutSetIntent: fetch failed: \(error.localizedDescription)")
        }

        let newSet = ExerciseSet(
            reps: reps,
            prescribedWeight: weight,
            type: .fixed,
            completedWeight: weight,
            actualReps: reps,
            isComplete: true
        )
        let newExercise = Exercise(
            id: UUID().uuidString,
            name: exercise.id,
            category: .compound,
            bodyweight: 0,
            targetSets: [newSet]
        )

        if let idx = workouts.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: todayStart) && $0.completedAt == nil
        }) {
            var updated = workouts[idx]
            updated.exercises.append(newExercise)
            try await client.save(updated, recordType: "Workout")
        } else {
            let quickLog = Workout(
                date: todayStart,
                name: "Quick Log",
                exercises: [newExercise]
            )
            try await client.save(quickLog, recordType: "Workout")
        }

        return .result(
            dialog: "Logged \(reps) × \(Int(weight)) on \(exercise.id)."
        )
    }
}
