import Foundation
import Testing
@testable import SundeeFundeeKit

// See `SharedSnapshotStoreTests` for notes on the SPM/macOS test-host limits
// around `SharedSnapshotStore.defaults`. The GetRecoveryScore cases share
// the same constraint. Disabled on SPM/macOS; the iOS test target covers
// these via `xcodebuild test`.
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

    private func withSnapshotSuite(_ body: @Sendable () async throws -> Void) async rethrows {
        // Serialize access to SharedSnapshotStore.defaults across suites.
        try await SharedSnapshotTestLock.shared.runAsync {
            let suiteName = "com.sundeefundee.tests.intents-\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suiteName) ?? .standard
            let previous = SharedSnapshotStore.defaults
            SharedSnapshotStore.defaults = defaults
            SharedSnapshotStore.clear()
            defer {
                SharedSnapshotStore.clear()
                SharedSnapshotStore.defaults = previous
                defaults.removePersistentDomain(forName: suiteName)
            }
            try await body()
        }
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

    // MARK: - GetRecoveryScoreIntent

    @Test("GetRecoveryScoreIntent runs cleanly with no snapshot")
    @MainActor
    func getRecoveryWithoutSnapshot() async throws {
        try await withSnapshotSuite {
            let intent = GetRecoveryScoreIntent()
            _ = try await intent.perform()
            #expect(SharedSnapshotStore.readRecovery() == nil)
        }
    }

    @Test("GetRecoveryScoreIntent reads the persisted snapshot")
    @MainActor
    func getRecoveryWithSnapshot() async throws {
        try await withSnapshotSuite {
            SharedSnapshotStore.writeRecovery(
                RecoverySnapshot(
                    total: 82,
                    recommendationRaw: "pushDay",
                    capturedAt: Date(),
                    presentInputCount: 5
                )
            )
            let intent = GetRecoveryScoreIntent()
            _ = try await intent.perform()
            let snapshot = try #require(SharedSnapshotStore.readRecovery())
            #expect(snapshot.total == 82)
            #expect(snapshot.recommendationRaw == "pushDay")
        }
    }
}
