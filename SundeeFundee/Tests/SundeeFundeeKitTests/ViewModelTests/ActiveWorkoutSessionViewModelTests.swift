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

    private enum TestError: Error {
        case timeout
    }
}
