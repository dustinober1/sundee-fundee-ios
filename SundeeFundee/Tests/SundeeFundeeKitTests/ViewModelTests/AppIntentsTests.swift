import Foundation
import Testing
@testable import SundeeFundeeKit

// Disabled on SPM/macOS; the iOS test target covers these via `xcodebuild test`.
@Suite("App Intents", .serialized, .disabled("Flakes on macOS SPM test host (no bundle identity for UserDefaults suites)."))
struct AppIntentsTests {

    // MARK: - Helpers

    private func withMockClient(_ body: @Sendable (MockCloudKitClient) async throws -> Void) async rethrows {
        let mock = MockCloudKitClient()
        let previous = DataClientFactory.shared.client
        DataClientFactory.shared.client = mock
        defer { DataClientFactory.shared.client = previous }
        try await body(mock)
    }

    // MARK: - LogWorkoutSetIntent

    @Test("LogWorkoutSetIntent creates a Quick Log workout when none exists today")
    @MainActor
    func logSetCreatesQuickLog() async throws {
        try await withMockClient { mock in
            let intent = LogWorkoutSetIntent(
                exercise: ExerciseCatalogEntity(id: "Back Squat", categoryRaw: "Squat"),
                weight: 315,
                reps: 5
            )
            _ = try await intent.perform()

            let workouts: [Workout] = try await mock.fetchAll(recordType: "Workout")
            #expect(workouts.count == 1)
            let workout = try #require(workouts.first)
            #expect(workout.name == "Quick Log")
            #expect(workout.exercises.first?.name == "Back Squat")
            #expect(workout.exercises.first?.targetSets.first?.actualReps == 5)
            #expect(workout.exercises.first?.targetSets.first?.completedWeight == 315)
        }
    }

    @Test("LogWorkoutSetIntent appends to an existing incomplete workout today")
    @MainActor
    func logSetAppendsToExisting() async throws {
        try await withMockClient { mock in
            let existing = Workout(
                date: Calendar.current.startOfDay(for: Date()),
                name: "Morning Lift",
                exercises: []
            )
            try await mock.save(existing, recordType: "Workout")

            let intent = LogWorkoutSetIntent(
                exercise: ExerciseCatalogEntity(id: "Flat Barbell Bench Press", categoryRaw: "Press"),
                weight: 225,
                reps: 3
            )
            _ = try await intent.perform()

            let workouts: [Workout] = try await mock.fetchAll(recordType: "Workout")
            #expect(workouts.count == 1)
            let workout = try #require(workouts.first)
            #expect(workout.name == "Morning Lift")
            #expect(workout.exercises.count == 1)
            #expect(workout.exercises.first?.name == "Flat Barbell Bench Press")
        }
    }
}
