import XCTest
@testable import SundeeFundeeKit

final class ProgressiveOverloadEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeWorkout(
        id: String = UUID().uuidString,
        date: Date,
        exerciseName: String,
        category: ExerciseCategory = .compound,
        bodyweight: Double = 0,
        prescribedWeight: Double,
        completedWeight: Double? = nil,
        targetReps: Int,
        actualReps: Int?,
        setsCount: Int = 3
    ) -> Workout {
        let sets = (0..<setsCount).map { index in
            ExerciseSet(
                id: "\(id)-set-\(index)",
                reps: targetReps,
                prescribedWeight: prescribedWeight,
                type: .fixed,
                completedWeight: completedWeight ?? prescribedWeight,
                actualReps: actualReps,
                isComplete: true
            )
        }
        let exercise = Exercise(
            id: "\(id)-ex",
            name: exerciseName,
            category: category,
            bodyweight: bodyweight,
            targetSets: sets
        )
        return Workout(
            id: id,
            date: date,
            name: "Session",
            exercises: [exercise],
            completedAt: date
        )
    }

    // MARK: - Tests

    func testSuccessfulCompoundIncreasesWeightByFivePounds() {
        let workout = makeWorkout(
            date: Date(),
            exerciseName: "Bench Press",
            category: .compound,
            prescribedWeight: 135,
            targetReps: 5,
            actualReps: 5
        )

        let result = ProgressiveOverloadEngine.evaluate(
            exerciseName: "Bench Press",
            workouts: [workout],
            unit: .lbs
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.action, .increaseWeight)
        XCTAssertEqual(result?.previousWeight, 135)
        XCTAssertEqual(result?.recommendedWeight, 140)
        XCTAssertEqual(result?.weightIncrement, 5.0)
        XCTAssertEqual(result?.previousReps, 5)
        XCTAssertEqual(result?.recommendedReps, 5)
        XCTAssertEqual(result?.consecutiveSuccesses, 1)
        XCTAssertEqual(result?.consecutiveFailures, 0)
        XCTAssertTrue(result?.reason.contains("+5 lbs progressive overload") == true)
    }

    func testSuccessfulIsolationIncreasesWeightByTwoPointFivePounds() {
        let workout = makeWorkout(
            date: Date(),
            exerciseName: "Dumbbell Bicep Curl",
            category: .isolation,
            prescribedWeight: 30,
            targetReps: 10,
            actualReps: 10
        )

        let result = ProgressiveOverloadEngine.evaluate(
            exerciseName: "Dumbbell Bicep Curl",
            workouts: [workout],
            unit: .lbs
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.action, .increaseWeight)
        XCTAssertEqual(result?.previousWeight, 30)
        XCTAssertEqual(result?.recommendedWeight, 32.5)
        XCTAssertEqual(result?.weightIncrement, 2.5)
        XCTAssertEqual(result?.previousReps, 10)
        XCTAssertEqual(result?.recommendedReps, 10)
        XCTAssertEqual(result?.consecutiveSuccesses, 1)
        XCTAssertEqual(result?.consecutiveFailures, 0)
        XCTAssertTrue(result?.reason.contains("+2.5 lbs progressive overload") == true)
    }

    func testLowRPELowerBodyCompoundIncreasesWeightByTenPounds() {
        let workout = makeWorkout(
            id: "squat-session",
            date: Date(),
            exerciseName: "Back Squat",
            category: .compound,
            prescribedWeight: 225,
            targetReps: 5,
            actualReps: 5
        )
        let effortLog = WorkoutEffortLog(
            workoutID: "squat-session",
            exerciseName: "Back Squat",
            setID: nil,
            rpe: 6
        )

        let result = ProgressiveOverloadEngine.evaluate(
            exerciseName: "Back Squat",
            workouts: [workout],
            effortLogs: [effortLog],
            unit: .lbs
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.action, .increaseWeight)
        XCTAssertEqual(result?.previousWeight, 225)
        XCTAssertEqual(result?.recommendedWeight, 235)
        XCTAssertEqual(result?.weightIncrement, 10.0)
        XCTAssertEqual(result?.averageRPE, 6.0)
        XCTAssertEqual(result?.consecutiveSuccesses, 1)
        XCTAssertTrue(result?.reason.contains("+10 lbs progressive overload") == true)
        XCTAssertTrue(result?.reason.contains("RPE 6") == true)
    }

    func testMetricIncrementsForCompoundAndIsolation() {
        let compoundWorkout = makeWorkout(
            date: Date(),
            exerciseName: "Overhead Press",
            category: .compound,
            prescribedWeight: 50,
            targetReps: 5,
            actualReps: 5
        )
        let compoundResult = ProgressiveOverloadEngine.evaluate(
            exerciseName: "Overhead Press",
            workouts: [compoundWorkout],
            unit: .kg
        )
        XCTAssertEqual(compoundResult?.action, .increaseWeight)
        XCTAssertEqual(compoundResult?.previousWeight, 50)
        XCTAssertEqual(compoundResult?.recommendedWeight, 52.5)
        XCTAssertEqual(compoundResult?.weightIncrement, 2.5)
        XCTAssertTrue(compoundResult?.reason.contains("+2.5 kg progressive overload") == true)

        let isolationWorkout = makeWorkout(
            date: Date(),
            exerciseName: "Lateral Raise",
            category: .isolation,
            prescribedWeight: 10,
            targetReps: 12,
            actualReps: 12
        )
        let isolationResult = ProgressiveOverloadEngine.evaluate(
            exerciseName: "Lateral Raise",
            workouts: [isolationWorkout],
            unit: .kg
        )
        XCTAssertEqual(isolationResult?.action, .increaseWeight)
        XCTAssertEqual(isolationResult?.previousWeight, 10)
        XCTAssertEqual(isolationResult?.recommendedWeight, 11.25)
        XCTAssertEqual(isolationResult?.weightIncrement, 1.25)
        XCTAssertTrue(isolationResult?.reason.contains("+1.25 kg progressive overload") == true)
    }

    func testMetricLowRPELowerBodyCompoundIncreasesWeightByFiveKg() {
        let workout = makeWorkout(
            id: "deadlift-metric",
            date: Date(),
            exerciseName: "Deadlift",
            category: .compound,
            prescribedWeight: 100,
            targetReps: 5,
            actualReps: 5
        )
        let effortLog = WorkoutEffortLog(
            workoutID: "deadlift-metric",
            exerciseName: "Deadlift",
            setID: nil,
            rpe: 7
        )

        let result = ProgressiveOverloadEngine.evaluate(
            exerciseName: "Deadlift",
            workouts: [workout],
            effortLogs: [effortLog],
            unit: .kg
        )

        XCTAssertEqual(result?.action, .increaseWeight)
        XCTAssertEqual(result?.previousWeight, 100)
        XCTAssertEqual(result?.recommendedWeight, 105)
        XCTAssertEqual(result?.weightIncrement, 5.0)
        XCTAssertTrue(result?.reason.contains("+5 kg progressive overload") == true)
    }

    func testMissedRepsLeadsToMaintain() {
        let workout = makeWorkout(
            date: Date(),
            exerciseName: "Bench Press",
            category: .compound,
            prescribedWeight: 185,
            targetReps: 5,
            actualReps: 3
        )

        let result = ProgressiveOverloadEngine.evaluate(
            exerciseName: "Bench Press",
            workouts: [workout],
            unit: .lbs
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.action, .maintain)
        XCTAssertEqual(result?.previousWeight, 185)
        XCTAssertEqual(result?.recommendedWeight, 185)
        XCTAssertEqual(result?.consecutiveSuccesses, 0)
        XCTAssertEqual(result?.consecutiveFailures, 1)
        XCTAssertTrue(result?.reason.contains("Missed target reps or high strain") == true)
    }

    func testHighRPELeadsToMaintainEvenIfRepsHit() {
        let workout = makeWorkout(
            id: "heavy-bench",
            date: Date(),
            exerciseName: "Bench Press",
            category: .compound,
            prescribedWeight: 185,
            targetReps: 5,
            actualReps: 5
        )
        let highStrainLog = WorkoutEffortLog(
            workoutID: "heavy-bench",
            exerciseName: "Bench Press",
            setID: nil,
            rpe: 10
        )

        let result = ProgressiveOverloadEngine.evaluate(
            exerciseName: "Bench Press",
            workouts: [workout],
            effortLogs: [highStrainLog],
            unit: .lbs
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.action, .maintain)
        XCTAssertEqual(result?.previousWeight, 185)
        XCTAssertEqual(result?.recommendedWeight, 185)
        XCTAssertEqual(result?.consecutiveFailures, 1)
        XCTAssertTrue(result?.reason.contains("Missed target reps or high strain") == true)
    }

    func testThreeConsecutiveFailuresLeadsToDeloadOrReset() {
        let baseDate = Date()
        let w1 = makeWorkout(
            date: baseDate.addingTimeInterval(-86400 * 2),
            exerciseName: "Back Squat",
            category: .compound,
            prescribedWeight: 200,
            targetReps: 5,
            actualReps: 3
        )
        let w2 = makeWorkout(
            date: baseDate.addingTimeInterval(-86400 * 1),
            exerciseName: "Back Squat",
            category: .compound,
            prescribedWeight: 200,
            targetReps: 5,
            actualReps: 4
        )
        let w3 = makeWorkout(
            date: baseDate,
            exerciseName: "Back Squat",
            category: .compound,
            prescribedWeight: 200,
            targetReps: 5,
            actualReps: 4
        )

        let result = ProgressiveOverloadEngine.evaluate(
            exerciseName: "Back Squat",
            workouts: [w1, w2, w3],
            unit: .lbs
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.action, .deloadOrReset)
        XCTAssertEqual(result?.previousWeight, 200)
        XCTAssertEqual(result?.recommendedWeight, 180)
        XCTAssertEqual(result?.consecutiveFailures, 3)
        XCTAssertEqual(result?.consecutiveSuccesses, 0)
        XCTAssertTrue(result?.reason.contains("Stalled for 3 consecutive sessions on Back Squat") == true)
        XCTAssertTrue(result?.reason.contains("10% reset to 180 lbs") == true)
    }

    func testBodyweightMovementLeadsToIncreaseReps() {
        let workout = makeWorkout(
            date: Date(),
            exerciseName: "Push-Up",
            category: .accessory,
            bodyweight: 1.0,
            prescribedWeight: 0,
            completedWeight: 0,
            targetReps: 15,
            actualReps: 15
        )

        let result = ProgressiveOverloadEngine.evaluate(
            exerciseName: "Push-Up",
            workouts: [workout],
            unit: .lbs
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.action, .increaseReps)
        XCTAssertEqual(result?.previousWeight, 0)
        XCTAssertEqual(result?.recommendedWeight, 0)
        XCTAssertEqual(result?.previousReps, 15)
        XCTAssertEqual(result?.recommendedReps, 16)
        XCTAssertEqual(result?.consecutiveSuccesses, 1)
        XCTAssertEqual(result?.consecutiveFailures, 0)
        XCTAssertEqual(result?.reason, "Completed all sets of Push-Up. Add 1 rep per set for progressive overload.")
    }

    func testStartingWeightCalibrationServiceUsesProgressiveOverloadWhenPastWorkoutsExist() {
        let pastWorkout = makeWorkout(
            date: Date(),
            exerciseName: "Barbell Squat",
            category: .compound,
            prescribedWeight: 185,
            targetReps: 5,
            actualReps: 5
        )

        let targetExercise = Exercise(
            id: "target-ex",
            name: "Barbell Squat",
            category: .compound,
            bodyweight: 0,
            targetSets: [ExerciseSet(reps: 5, prescribedWeight: 0, type: .fixed)]
        )

        let suggestion = StartingWeightCalibrationService.suggestion(
            for: targetExercise,
            maxRecords: [],
            experienceLevel: .beginner,
            unit: .lbs,
            recentWorkouts: [pastWorkout]
        )

        XCTAssertEqual(suggestion.suggestedWeight, 190)
        XCTAssertEqual(suggestion.confidence, 0.90)
        XCTAssertTrue(suggestion.reason.contains("+5 lbs progressive overload"))
    }

    func testStartingWeightCalibrationSuggestionsForWholeWorkout() {
        let pastWorkout = makeWorkout(
            date: Date(),
            exerciseName: "Bench Press",
            category: .compound,
            prescribedWeight: 135,
            targetReps: 5,
            actualReps: 5
        )

        let newWorkout = Workout(
            date: Date(),
            name: "Upper Body",
            exercises: [
                Exercise(
                    id: "bench-ex",
                    name: "Bench Press",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [ExerciseSet(reps: 5, prescribedWeight: 0, type: .fixed)]
                )
            ]
        )

        let suggestions = StartingWeightCalibrationService.suggestions(
            for: newWorkout,
            maxRecords: [],
            experienceLevel: .intermediate,
            unit: .lbs,
            recentWorkouts: [pastWorkout]
        )

        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(suggestions.first?.suggestedWeight, 140)
        XCTAssertEqual(suggestions.first?.confidence, 0.90)
    }

    func testNextWorkingWeightFallbackAndResolved() {
        let fallback = ProgressiveOverloadEngine.nextWorkingWeight(
            for: "Deadlift",
            fallbackWeight: 135,
            workouts: [],
            unit: .lbs
        )
        XCTAssertEqual(fallback, 135)

        let workout = makeWorkout(
            date: Date(),
            exerciseName: "Deadlift",
            category: .compound,
            prescribedWeight: 225,
            targetReps: 5,
            actualReps: 5
        )
        let next = ProgressiveOverloadEngine.nextWorkingWeight(
            for: "Deadlift",
            fallbackWeight: 135,
            workouts: [workout],
            unit: .lbs
        )
        XCTAssertEqual(next, 230)
    }

    func testEvaluateAllExtractsAndEvaluatesMultipleExercises() {
        let date = Date()
        let setsA = [ExerciseSet(reps: 5, prescribedWeight: 135, type: .fixed, completedWeight: 135, actualReps: 5, isComplete: true)]
        let setsB = [ExerciseSet(reps: 8, prescribedWeight: 30, type: .fixed, completedWeight: 30, actualReps: 8, isComplete: true)]

        let exA = Exercise(id: "1", name: "Bench Press", category: .compound, bodyweight: 0, targetSets: setsA)
        let exB = Exercise(id: "2", name: "Incline Dumbbell Curl", category: .isolation, bodyweight: 0, targetSets: setsB)

        let workout = Workout(id: "w1", date: date, name: "Upper", exercises: [exA, exB], completedAt: date)

        let results = ProgressiveOverloadEngine.evaluateAll(workouts: [workout], unit: .lbs)
        XCTAssertEqual(results.count, 2)

        let bench = results.first { $0.exerciseName == "Bench Press" }
        XCTAssertEqual(bench?.recommendedWeight, 140)

        let curl = results.first { $0.exerciseName == "Incline Dumbbell Curl" }
        XCTAssertEqual(curl?.recommendedWeight, 32.5)
    }
}
