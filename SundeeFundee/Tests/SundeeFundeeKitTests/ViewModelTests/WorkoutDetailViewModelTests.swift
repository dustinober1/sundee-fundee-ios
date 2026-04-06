import Testing
import Foundation
import CloudKit
@testable import SundeeFundeeKit

// MARK: - Test Helpers

private let calendar = Calendar.current

private func makeDate(year: Int, month: Int, day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
}

private func makeWorkout(
    id: String = UUID().uuidString,
    exercises: [Exercise],
    completedAt: Date? = nil
) -> Workout {
    Workout(
        id: id,
        date: makeDate(year: 2026, month: 3, day: 1),
        name: "Test Workout",
        exercises: exercises,
        completedAt: completedAt
    )
}

private func makeExercise(
    name: String,
    completedWeights: [Double?]
) -> Exercise {
    Exercise(
        id: UUID().uuidString,
        name: name,
        category: .compound,
        bodyweight: 0,
        targetSets: completedWeights.map { weight in
            ExerciseSet(
                reps: 5,
                prescribedWeight: weight ?? 0,
                type: .fixed,
                completedWeight: weight,
                isComplete: weight != nil
            )
        }
    )
}

private func makeORM(
    exerciseName: String,
    weight: Double,
    date: Date
) -> OneRepMaxRecord {
    OneRepMaxRecord(
        id: UUID().uuidString,
        exerciseName: exerciseName,
        weight: weight,
        unit: .lbs,
        date: date
    )
}

// MARK: - Throwing Data Client for Error Tests

private final class ThrowingDataClient: DataClientProtocol, @unchecked Sendable {
    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        throw DataError.networkError(underlying: nil)
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        throw DataError.networkError(underlying: nil)
    }

    func delete(
        recordIDs: [CKRecord.ID],
        recordType: String
    ) async throws {
        throw DataError.networkError(underlying: nil)
    }

    func deleteAllData() async throws {
        throw DataError.networkError(underlying: nil)
    }
}

// MARK: - WorkoutDetailViewModel Tests

@Suite("WorkoutDetailViewModel.detectPersonalRecords")
@MainActor
struct WorkoutDetailViewModelTests {

    // MARK: - Happy Path

    @Test("Exercise exceeding previous ORM record is detected as PR")
    func testHappyPathPRDetected() async throws {
        let mockClient = MockCloudKitClient()

        // Seed a previous ORM record for Squat at 200 lbs
        let previousORM = makeORM(
            exerciseName: "Squat",
            weight: 200,
            date: makeDate(year: 2026, month: 2, day: 1)
        )
        try await mockClient.save([previousORM], recordType: "OneRepMaxRecord")

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-1",
            dataClient: mockClient
        )

        // Workout with Squat at 225 lbs (exceeds previous 200)
        vm.workout = makeWorkout(
            exercises: [
                makeExercise(name: "Squat", completedWeights: [225.0])
            ],
            completedAt: makeDate(year: 2026, month: 3, day: 1)
        )

        await vm.detectPersonalRecords()

        #expect(vm.personalRecords == ["Squat"])
    }

    // MARK: - No PR

    @Test("Exercise not exceeding previous ORM is not a PR")
    func testNoPR() async throws {
        let mockClient = MockCloudKitClient()

        let previousORM = makeORM(
            exerciseName: "Squat",
            weight: 250,
            date: makeDate(year: 2026, month: 2, day: 1)
        )
        try await mockClient.save([previousORM], recordType: "OneRepMaxRecord")

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-2",
            dataClient: mockClient
        )

        vm.workout = makeWorkout(
            exercises: [
                makeExercise(name: "Squat", completedWeights: [200.0])
            ],
            completedAt: makeDate(year: 2026, month: 3, day: 1)
        )

        await vm.detectPersonalRecords()

        #expect(vm.personalRecords.isEmpty)
    }

    @Test("Exercise matching previous ORM exactly is not a PR")
    func testMatchingRecordNotPR() async throws {
        let mockClient = MockCloudKitClient()

        let previousORM = makeORM(
            exerciseName: "Bench Press",
            weight: 185,
            date: makeDate(year: 2026, month: 2, day: 1)
        )
        try await mockClient.save([previousORM], recordType: "OneRepMaxRecord")

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-3",
            dataClient: mockClient
        )

        vm.workout = makeWorkout(
            exercises: [
                makeExercise(name: "Bench Press", completedWeights: [185.0])
            ],
            completedAt: makeDate(year: 2026, month: 3, day: 1)
        )

        await vm.detectPersonalRecords()

        #expect(vm.personalRecords.isEmpty)
    }

    // MARK: - Empty ORM History

    @Test("No previous ORM records results in empty personalRecords")
    func testEmptyORMHistory() async throws {
        let mockClient = MockCloudKitClient()
        // No ORM records seeded

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-4",
            dataClient: mockClient
        )

        vm.workout = makeWorkout(
            exercises: [
                makeExercise(name: "Squat", completedWeights: [225.0])
            ],
            completedAt: makeDate(year: 2026, month: 3, day: 1)
        )

        await vm.detectPersonalRecords()

        // First-time lifts are not PRs per design
        #expect(vm.personalRecords.isEmpty)
    }

    // MARK: - Error Fallback

    @Test("DataClient throwing results in empty personalRecords")
    func testErrorFallback() async throws {
        let throwingClient = ThrowingDataClient()

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-5",
            dataClient: throwingClient
        )

        vm.workout = makeWorkout(
            exercises: [
                makeExercise(name: "Squat", completedWeights: [300.0])
            ],
            completedAt: makeDate(year: 2026, month: 3, day: 1)
        )

        await vm.detectPersonalRecords()

        // Non-critical — PR highlights are best-effort
        #expect(vm.personalRecords.isEmpty)
    }

    // MARK: - Multiple Exercises

    @Test("Mix of PR and non-PR exercises only includes PR exercises")
    func testMultipleExercises() async throws {
        let mockClient = MockCloudKitClient()

        let squatORM = makeORM(
            exerciseName: "Squat",
            weight: 200,
            date: makeDate(year: 2026, month: 2, day: 1)
        )
        let benchORM = makeORM(
            exerciseName: "Bench Press",
            weight: 185,
            date: makeDate(year: 2026, month: 2, day: 1)
        )
        let deadliftORM = makeORM(
            exerciseName: "Deadlift",
            weight: 300,
            date: makeDate(year: 2026, month: 2, day: 1)
        )
        try await mockClient.save([squatORM, benchORM, deadliftORM], recordType: "OneRepMaxRecord")

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-6",
            dataClient: mockClient
        )

        vm.workout = makeWorkout(
            exercises: [
                // PR: 225 > 200
                makeExercise(name: "Squat", completedWeights: [225.0]),
                // NOT a PR: 175 < 185
                makeExercise(name: "Bench Press", completedWeights: [175.0]),
                // PR: 315 > 300
                makeExercise(name: "Deadlift", completedWeights: [315.0]),
            ],
            completedAt: makeDate(year: 2026, month: 3, day: 1)
        )

        await vm.detectPersonalRecords()

        #expect(vm.personalRecords == ["Squat", "Deadlift"])
        #expect(vm.personalRecords.count == 2)
    }

    // MARK: - Zero Completed Weight

    @Test("Exercise with no completed sets is not included in PRs")
    func testZeroCompletedWeight() async throws {
        let mockClient = MockCloudKitClient()

        let squatORM = makeORM(
            exerciseName: "Squat",
            weight: 200,
            date: makeDate(year: 2026, month: 2, day: 1)
        )
        try await mockClient.save([squatORM], recordType: "OneRepMaxRecord")

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-7",
            dataClient: mockClient
        )

        vm.workout = makeWorkout(
            exercises: [
                // No completed sets (all nil weights)
                makeExercise(name: "Squat", completedWeights: [nil, nil, nil]),
            ],
            completedAt: makeDate(year: 2026, month: 3, day: 1)
        )

        await vm.detectPersonalRecords()

        #expect(vm.personalRecords.isEmpty)
    }

    @Test("Exercise with zero weight completed sets is not included in PRs")
    func testExplicitZeroWeight() async throws {
        let mockClient = MockCloudKitClient()

        let pushupORM = makeORM(
            exerciseName: "Push-ups",
            weight: 0,
            date: makeDate(year: 2026, month: 2, day: 1)
        )
        try await mockClient.save([pushupORM], recordType: "OneRepMaxRecord")

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-8",
            dataClient: mockClient
        )

        // completedWeight of 0 — maxCompletedWeight will be 0, which is excluded by guard
        vm.workout = makeWorkout(
            exercises: [
                makeExercise(name: "Push-ups", completedWeights: [0.0]),
            ],
            completedAt: makeDate(year: 2026, month: 3, day: 1)
        )

        await vm.detectPersonalRecords()

        #expect(vm.personalRecords.isEmpty)
    }

    // MARK: - No Workout Set

    @Test("detectPersonalRecords does nothing when workout is nil")
    func testNoWorkoutSet() async throws {
        let mockClient = MockCloudKitClient()

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-9",
            dataClient: mockClient
        )

        // workout is nil by default
        await vm.detectPersonalRecords()

        #expect(vm.personalRecords.isEmpty)
    }

    // MARK: - Uses Max Weight Across Sets

    @Test("PR detection uses maximum completed weight across all sets")
    func testMaxWeightAcrossSets() async throws {
        let mockClient = MockCloudKitClient()

        let squatORM = makeORM(
            exerciseName: "Squat",
            weight: 200,
            date: makeDate(year: 2026, month: 2, day: 1)
        )
        try await mockClient.save([squatORM], recordType: "OneRepMaxRecord")

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-10",
            dataClient: mockClient
        )

        // First two sets below PR, but third set exceeds it
        vm.workout = makeWorkout(
            exercises: [
                makeExercise(name: "Squat", completedWeights: [135.0, 185.0, 225.0]),
            ],
            completedAt: makeDate(year: 2026, month: 3, day: 1)
        )

        await vm.detectPersonalRecords()

        #expect(vm.personalRecords == ["Squat"])
    }

    // MARK: - Multiple ORM Records for Same Exercise

    @Test("Compares against highest previous ORM for same exercise")
    func testMultipleORMRecordsForSameExercise() async throws {
        let mockClient = MockCloudKitClient()

        let orm1 = makeORM(
            exerciseName: "Squat",
            weight: 180,
            date: makeDate(year: 2026, month: 1, day: 1)
        )
        let orm2 = makeORM(
            exerciseName: "Squat",
            weight: 220,
            date: makeDate(year: 2026, month: 2, day: 1)
        )
        try await mockClient.save([orm1, orm2], recordType: "OneRepMaxRecord")

        let vm = WorkoutDetailViewModel(
            workoutId: "test-workout-11",
            dataClient: mockClient
        )

        // 210 > 180 (orm1) but NOT > 220 (orm2, the highest)
        vm.workout = makeWorkout(
            exercises: [
                makeExercise(name: "Squat", completedWeights: [210.0]),
            ],
            completedAt: makeDate(year: 2026, month: 3, day: 1)
        )

        await vm.detectPersonalRecords()

        #expect(vm.personalRecords.isEmpty)
    }
}
