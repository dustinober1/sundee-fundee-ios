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

    func testMetricWeightUnitPRRecording() async throws {
        let dataClient = MockCloudKitClient()
        try await dataClient.save(
            UserSettingsRecord(
                cycleTrackingEnabled: false,
                weightUnit: "kg",
                experienceLevel: "beginner",
                primaryGoal: "strength"
            ),
            recordType: "UserSettings"
        )
        try await dataClient.save(
            OneRepMaxRecord(
                id: UUID().uuidString,
                exerciseName: "Back Squat",
                weight: 80,
                unit: .kg,
                date: Date().addingTimeInterval(-86_400)
            ),
            recordType: "OneRepMaxRecord"
        )
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: squatWorkout(),
            dataClient: dataClient,
            healthClient: MockHealthKitClient()
        )
        viewModel.beginSession()

        let deadline = DispatchTime.now().uptimeNanoseconds + 1_000_000_000
        while viewModel.weightUnit != .kg && DispatchTime.now().uptimeNanoseconds < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(viewModel.weightUnit, .kg)

        await viewModel.completeSet(actualReps: 5, completedWeight: 100)
        let maxRecords: [OneRepMaxRecord] = try await dataClient.fetchAll(recordType: "OneRepMaxRecord")

        let newRecord = maxRecords.first(where: { $0.weight > 80 })
        XCTAssertNotNil(newRecord)
        XCTAssertEqual(newRecord?.exerciseName, "Back Squat")
        XCTAssertEqual(newRecord?.unit, .kg)

        XCTAssertEqual(viewModel.pendingPRShare?.exerciseName, "Back Squat")
        XCTAssertEqual(viewModel.pendingPRShare?.unit, "kg")

        let celebration = viewModel.celebrationEvents.first { event in
            if case .newPersonalRecord(let exerciseName, _) = event {
                return exerciseName == "Back Squat"
            }
            return false
        }
        XCTAssertNotNil(celebration)
        if case .newPersonalRecord(_, let weightKg) = celebration, let record = newRecord {
            XCTAssertEqual(weightKg, record.weight, accuracy: 0.01)
        }

        await viewModel.abandonWorkout()
    }

    func testAddRestExtendsActiveRestTimer() async throws {
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: multiSetWorkout(),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )

        await viewModel.completeSet(actualReps: 5, completedWeight: 135)
        XCTAssertTrue(viewModel.isResting)
        let initialRemaining = viewModel.restTimeRemaining

        viewModel.addRest(seconds: 30)
        XCTAssertGreaterThan(viewModel.restTimeRemaining, initialRemaining)

        viewModel.skipRest()
    }

    func testCompleteSetFromIntentNotificationTriggersSetCompletion() async throws {
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: multiSetWorkout(),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )
        viewModel.beginSession()

        XCTAssertEqual(viewModel.currentSetIndex, 0)
        NotificationCenter.default.post(name: .completeSetFromIntent, object: nil)

        // Give MainActor Task time to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.currentSetIndex, 1)
        XCTAssertEqual(viewModel.completedSets, 1)

        await viewModel.abandonWorkout()
    }

    func testAddRestFromIntentNotificationExtendsRestTimer() async throws {
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: multiSetWorkout(),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )
        viewModel.beginSession()

        await viewModel.completeSet(actualReps: 5, completedWeight: 135)
        XCTAssertTrue(viewModel.isResting)
        let beforeNotification = viewModel.restTimeRemaining

        NotificationCenter.default.post(name: .addRestFromIntent, object: nil)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertGreaterThan(viewModel.restTimeRemaining, beforeNotification)

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

    func testSwapCurrentExerciseKeepingCompletedSetsSplitsExercise() async throws {
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: multiSetWorkout(),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )

        // Complete 1 of 3 sets on Back Squat
        await viewModel.completeSet(actualReps: 5, completedWeight: 135)
        viewModel.skipRest()

        XCTAssertEqual(viewModel.completedSets, 1)
        XCTAssertEqual(viewModel.currentExercise?.name, "Back Squat")
        XCTAssertEqual(viewModel.currentSetIndex, 1)

        // Swap to Front Squat keeping completed sets
        viewModel.swapCurrentExercise(to: "Front Squat", keepCompletedSets: true)

        // Back Squat remains as first exercise with 1 completed set
        XCTAssertEqual(viewModel.workout.exercises.count, 2)
        XCTAssertEqual(viewModel.workout.exercises[0].name, "Back Squat")
        XCTAssertEqual(viewModel.workout.exercises[0].targetSets.count, 1)
        XCTAssertTrue(viewModel.workout.exercises[0].targetSets[0].isComplete)

        // Front Squat inserted as second exercise with remaining 2 incomplete sets
        XCTAssertEqual(viewModel.workout.exercises[1].name, "Front Squat")
        XCTAssertEqual(viewModel.workout.exercises[1].targetSets.count, 2)
        XCTAssertFalse(viewModel.workout.exercises[1].targetSets[0].isComplete)
        XCTAssertFalse(viewModel.workout.exercises[1].targetSets[1].isComplete)

        // View model points to Front Squat at set 0
        XCTAssertEqual(viewModel.currentExerciseIndex, 1)
        XCTAssertEqual(viewModel.currentSetIndex, 0)
        XCTAssertEqual(viewModel.currentExercise?.name, "Front Squat")
        XCTAssertEqual(viewModel.completedSets, 1)
        XCTAssertEqual(viewModel.totalSets, 3)
    }

    func testSwapCurrentExerciseResettingProgressReplacesInPlace() async throws {
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: multiSetWorkout(),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )

        // Complete 1 of 3 sets on Back Squat
        await viewModel.completeSet(actualReps: 5, completedWeight: 135)
        viewModel.skipRest()

        // Swap to Front Squat without keeping completed sets
        viewModel.swapCurrentExercise(to: "Front Squat", keepCompletedSets: false)

        // Single exercise replaced in-place with all sets reset
        XCTAssertEqual(viewModel.workout.exercises.count, 1)
        XCTAssertEqual(viewModel.workout.exercises[0].name, "Front Squat")
        XCTAssertEqual(viewModel.workout.exercises[0].targetSets.count, 3)
        XCTAssertTrue(viewModel.workout.exercises[0].targetSets.allSatisfy { !$0.isComplete })

        XCTAssertEqual(viewModel.currentExerciseIndex, 0)
        XCTAssertEqual(viewModel.currentSetIndex, 0)
        XCTAssertEqual(viewModel.completedSets, 0)
        XCTAssertEqual(viewModel.totalSets, 3)
    }

    func testSwapCurrentExerciseWithoutProgressReplacesInPlaceEvenIfKeepTrue() {
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: multiSetWorkout(),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )

        // No sets completed yet
        viewModel.swapCurrentExercise(to: "Front Squat", keepCompletedSets: true)

        XCTAssertEqual(viewModel.workout.exercises.count, 1)
        XCTAssertEqual(viewModel.workout.exercises[0].name, "Front Squat")
        XCTAssertEqual(viewModel.workout.exercises[0].targetSets.count, 3)
        XCTAssertEqual(viewModel.currentExerciseIndex, 0)
        XCTAssertEqual(viewModel.currentSetIndex, 0)
    }

    func testAddExercisesAppendsNewExercisesWithAppropriateSetsAndWeights() {
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: squatWorkout(),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )

        XCTAssertEqual(viewModel.workout.exercises.count, 1)
        XCTAssertEqual(viewModel.totalSets, 1)

        // Add 2 exercises mid-workout
        viewModel.addExercises(["Barbell Row", "Dumbbell Bicep Curl"], setsCount: 3)

        XCTAssertEqual(viewModel.workout.exercises.count, 3)
        XCTAssertEqual(viewModel.workout.exercises[1].name, "Barbell Row")
        XCTAssertEqual(viewModel.workout.exercises[1].category, .compound)
        XCTAssertEqual(viewModel.workout.exercises[1].targetSets.count, 3)
        XCTAssertEqual(viewModel.workout.exercises[1].targetSets[0].prescribedWeight, 65)

        XCTAssertEqual(viewModel.workout.exercises[2].name, "Dumbbell Bicep Curl")
        XCTAssertEqual(viewModel.workout.exercises[2].category, .isolation)
        XCTAssertEqual(viewModel.workout.exercises[2].targetSets.count, 3)
        XCTAssertEqual(viewModel.workout.exercises[2].targetSets[0].prescribedWeight, 20)

        XCTAssertEqual(viewModel.totalSets, 7) // 1 + 3 + 3
    }

    func testAddExerciseCanInsertAfterCurrentExercise() {
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: multiSetWorkout(),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )

        // Insert right after current
        viewModel.addExercise(name: "Pull-Up", setsCount: 2, reps: 5, insertAfterCurrent: true)

        XCTAssertEqual(viewModel.workout.exercises.count, 2)
        XCTAssertEqual(viewModel.workout.exercises[1].name, "Pull-Up")
        XCTAssertEqual(viewModel.workout.exercises[1].targetSets.count, 2)
        XCTAssertEqual(viewModel.workout.exercises[1].targetSets[0].reps, 5)
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

    func testSupersetProgressionAlternatesExercisesAndRestDurations() async throws {
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: supersetWorkout(),
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )
        viewModel.beginSession()

        // 1. Initial state: on A1 (Bench Press), Set 0
        XCTAssertEqual(viewModel.currentExerciseIndex, 0)
        XCTAssertEqual(viewModel.currentSetIndex, 0)
        XCTAssertEqual(viewModel.currentExercise?.name, "Bench Press")

        // 2. Complete A1 Set 0 -> should advance to A2 (Barbell Row) Set 0 with 30s transition rest
        await viewModel.completeSet(actualReps: 8, completedWeight: 185)
        XCTAssertEqual(viewModel.currentExerciseIndex, 1)
        XCTAssertEqual(viewModel.currentSetIndex, 0)
        XCTAssertEqual(viewModel.currentExercise?.name, "Barbell Row")
        XCTAssertGreaterThan(viewModel.restTimeRemaining, 25)
        XCTAssertLessThanOrEqual(viewModel.restTimeRemaining, 30)
        XCTAssertTrue(viewModel.restGuidanceReason?.contains("transition") == true)

        // 3. Complete A2 Set 0 -> should advance to A1 (Bench Press) Set 1 with 90s group rest
        viewModel.skipRest()
        await viewModel.completeSet(actualReps: 8, completedWeight: 155)
        XCTAssertEqual(viewModel.currentExerciseIndex, 0)
        XCTAssertEqual(viewModel.currentSetIndex, 1)
        XCTAssertEqual(viewModel.currentExercise?.name, "Bench Press")
        XCTAssertGreaterThan(viewModel.restTimeRemaining, 85)
        XCTAssertLessThanOrEqual(viewModel.restTimeRemaining, 90)
        XCTAssertTrue(viewModel.restGuidanceReason?.contains("round complete") == true)

        // 4. Complete A1 Set 1 -> should advance to A2 (Barbell Row) Set 1 with 30s transition rest
        viewModel.skipRest()
        await viewModel.completeSet(actualReps: 8, completedWeight: 185)
        XCTAssertEqual(viewModel.currentExerciseIndex, 1)
        XCTAssertEqual(viewModel.currentSetIndex, 1)
        XCTAssertEqual(viewModel.currentExercise?.name, "Barbell Row")
        XCTAssertGreaterThan(viewModel.restTimeRemaining, 25)
        XCTAssertLessThanOrEqual(viewModel.restTimeRemaining, 30)

        // 5. Complete A2 Set 1 -> superset finished, advances to Exercise 2 (Tricep Pushdown)
        viewModel.skipRest()
        await viewModel.completeSet(actualReps: 8, completedWeight: 155)
        XCTAssertEqual(viewModel.currentExerciseIndex, 2)
        XCTAssertEqual(viewModel.currentSetIndex, 0)
        XCTAssertEqual(viewModel.currentExercise?.name, "Tricep Pushdown")

        // 6. Complete final straight set -> finishes workout
        viewModel.skipRest()
        await viewModel.completeSet(actualReps: 12, completedWeight: 50)
        XCTAssertTrue(viewModel.isComplete)
    }

    private func supersetWorkout() -> Workout {
        let group1 = ExerciseGrouping(
            groupID: "group-A",
            groupType: .superset,
            label: "A1",
            transitionRestSeconds: 30,
            groupRestSeconds: 90
        )
        let group2 = ExerciseGrouping(
            groupID: "group-A",
            groupType: .superset,
            label: "A2",
            transitionRestSeconds: 30,
            groupRestSeconds: 90
        )

        return Workout(
            date: Date(),
            name: "Superset Upper Day",
            exercises: [
                Exercise(
                    id: "bench-press",
                    name: "Bench Press",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(reps: 8, prescribedWeight: 185, type: .fixed),
                        ExerciseSet(reps: 8, prescribedWeight: 185, type: .fixed)
                    ],
                    restMinutes: 1.5,
                    grouping: group1
                ),
                Exercise(
                    id: "barbell-row",
                    name: "Barbell Row",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(reps: 8, prescribedWeight: 155, type: .fixed),
                        ExerciseSet(reps: 8, prescribedWeight: 155, type: .fixed)
                    ],
                    restMinutes: 1.5,
                    grouping: group2
                ),
                Exercise(
                    id: "tricep-pushdown",
                    name: "Tricep Pushdown",
                    category: .isolation,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(reps: 12, prescribedWeight: 50, type: .fixed)
                    ],
                    restMinutes: 1.0,
                    grouping: nil
                )
            ]
        )
    }

    private enum TestError: Error {
        case timeout
    }
}
