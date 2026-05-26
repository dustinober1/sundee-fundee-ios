import XCTest
@testable import SundeeFundeeKit

@MainActor
final class ActiveWorkoutSessionViewModelTests: XCTestCase {
    func testBeginSessionUsesTodaysRecoveryScoreForWarmupContext() async throws {
        let dataClient = MockCloudKitClient()
        try await dataClient.save(
            RecoveryScoreRecord(
                scoreDate: todayString(),
                totalScore: 32,
                presentInputCount: 5,
                cyclePhaseRaw: CyclePhase.luteal.rawValue,
                recommendationRaw: TrainingRecommendation.restDay.rawValue
            ),
            recordType: "RecoveryScore"
        )
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: squatWorkout(),
            dataClient: dataClient,
            healthClient: MockHealthKitClient()
        )

        viewModel.beginSession()
        let block = try await waitForWarmupBlock(in: viewModel)

        XCTAssertLessThanOrEqual(block.estimatedMinutes, 5)
        XCTAssertTrue(block.reasons.contains(where: { $0.localizedCaseInsensitiveContains("low recovery") }))
        XCTAssertTrue(block.reasons.contains(where: { $0.localizedCaseInsensitiveContains("cycle context") }))

        await viewModel.abandonWorkout()
    }

    func testBeginSessionFallsBackToLatestRecoveryScoreWhenTodayIsMissing() async throws {
        let dataClient = MockCloudKitClient()
        try await dataClient.save(
            RecoveryScoreRecord(
                scoreDate: dayString(daysAgo: 2),
                totalScore: 32,
                presentInputCount: 5,
                cyclePhaseRaw: CyclePhase.luteal.rawValue,
                recommendationRaw: TrainingRecommendation.restDay.rawValue
            ),
            recordType: "RecoveryScore"
        )
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: squatWorkout(),
            dataClient: dataClient,
            healthClient: MockHealthKitClient()
        )

        viewModel.beginSession()
        let block = try await waitForWarmupBlock(in: viewModel)

        XCTAssertLessThanOrEqual(block.estimatedMinutes, 5)
        XCTAssertTrue(block.reasons.contains(where: { $0.localizedCaseInsensitiveContains("low recovery") }))

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

        viewModel.skipRest()
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

    private func todayString() -> String {
        ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
    }

    private func dayString(daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: date))
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
