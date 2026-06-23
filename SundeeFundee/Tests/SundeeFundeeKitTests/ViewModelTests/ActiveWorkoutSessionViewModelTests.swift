import XCTest
@testable import SundeeFundeeKit

@MainActor
final class ActiveWorkoutSessionViewModelTests: XCTestCase {
    func testBeginSessionUsesPainLogForWarmupContext() async throws {
        let dataClient = MockCloudKitClient()
        try await dataClient.save(
            DailyPainLog(
                id: UUID().uuidString,
                locationIds: "knee_left",
                intensity: 6,
                painType: .aching,
                date: Date()
            ),
            recordType: "DailyPainLog"
        )
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: squatWorkout(),
            dataClient: dataClient,
            healthClient: MockHealthKitClient()
        )

        viewModel.beginSession()
        let block = try await waitForWarmupBlock(in: viewModel)

        XCTAssertTrue(block.reasons.contains(where: { $0.localizedCaseInsensitiveContains("knee pain") }))

        await viewModel.abandonWorkout()
    }

    func testRestSnapshotKeepsCompletedSetAsRestSourceAfterAdvancing() async throws {
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: multiSetWorkout(),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )

        await viewModel.completeSet(actualReps: 5, completedWeight: 135)

        let snapshot = viewModel.activitySnapshotForTesting()
        XCTAssertEqual(viewModel.currentSetIndex, 1)
        XCTAssertEqual(snapshot.rest?.sourceExerciseName, "Back Squat")
        XCTAssertEqual(snapshot.rest?.sourceSetIndex, 0)
        XCTAssertEqual(snapshot.nextUp?.setIndex, 1)

        viewModel.skipRest()
    }

    func testConcurrentCompleteSetOnlyLogsAndAdvancesOnce() async throws {
        let dataClient = MockCloudKitClient()
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: multiSetWorkout(),
            dataClient: dataClient,
            healthClient: MockHealthKitClient()
        )

        async let first: Void = viewModel.completeSet(actualReps: 5, completedWeight: 135, setRPE: 9)
        async let second: Void = viewModel.completeSet(actualReps: 5, completedWeight: 135, setRPE: 9)
        _ = await (first, second)

        XCTAssertEqual(dataClient.recordCount(for: "WorkoutEffortLog"), 1)
        XCTAssertEqual(viewModel.completedSets, 1)
        XCTAssertEqual(viewModel.currentSetIndex, 1)

        viewModel.skipRest()
    }

    func testFirstRecordedMaxDoesNotTriggerPRSharePrompt() async throws {
        let dataClient = MockCloudKitClient()
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: squatWorkout(),
            dataClient: dataClient,
            healthClient: MockHealthKitClient()
        )

        await viewModel.completeSet(actualReps: 5, completedWeight: 135)
        let maxRecords: [OneRepMaxRecord] = try await dataClient.fetchAll(recordType: "OneRepMaxRecord")

        XCTAssertNil(viewModel.pendingPRShare)
        XCTAssertTrue(maxRecords.contains(where: { $0.exerciseName == "Back Squat" }))
        XCTAssertTrue(
            viewModel.celebrationEvents.contains { event in
                if case .newPersonalRecord(let exerciseName, _) = event {
                    return exerciseName == "Back Squat"
                }
                return false
            }
        )
    }

    func testExistingMaxCanTriggerPRSharePrompt() async throws {
        let dataClient = MockCloudKitClient()
        try await dataClient.save(
            OneRepMaxRecord(
                id: UUID().uuidString,
                exerciseName: "Back Squat",
                weight: 120,
                unit: .lbs,
                date: Date().addingTimeInterval(-86_400)
            ),
            recordType: "OneRepMaxRecord"
        )
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: squatWorkout(),
            dataClient: dataClient,
            healthClient: MockHealthKitClient()
        )

        await viewModel.completeSet(actualReps: 5, completedWeight: 135)

        XCTAssertEqual(viewModel.pendingPRShare?.exerciseName, "Back Squat")
        XCTAssertEqual(viewModel.pendingPRShare?.previousBest, 120)
        XCTAssertEqual(dataClient.recordCount(for: "OneRepMaxRecord"), 2)
    }

    private func waitForWarmupBlock(
        in viewModel: ActiveWorkoutSessionViewModel,
        timeoutNanoseconds: UInt64 = 1_000_000_000
    ) async throws -> WarmupBlock {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if let block = viewModel.pendingWarmupBlock {
                return block
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Expected pending warmup block")
        throw TestError.timeout
    }

    private func squatWorkout() -> Workout {
        Workout(
            date: Date(),
            name: "Squat Day",
            exercises: [
                Exercise(
                    id: "back-squat",
                    name: "Back Squat",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(reps: 5, prescribedWeight: 135, type: .fixed)
                    ]
                )
            ]
        )
    }

    private func multiSetWorkout() -> Workout {
        Workout(
            date: Date(),
            name: "Squat Day",
            exercises: [
                Exercise(
                    id: "back-squat",
                    name: "Back Squat",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(reps: 5, prescribedWeight: 135, type: .fixed),
                        ExerciseSet(reps: 5, prescribedWeight: 135, type: .fixed),
                        ExerciseSet(reps: 5, prescribedWeight: 135, type: .fixed)
                    ],
                    restMinutes: 2
                )
            ]
        )
    }

    private enum TestError: Error {
        case timeout
    }
}
