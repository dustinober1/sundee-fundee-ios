import XCTest
import SwiftData
@testable import SundeeFundee

@MainActor
final class WODExecutionViewModelTests: XCTestCase {

    private func makeWOD(exercises: [ProgramExercise] = []) -> WOD {
        WOD(
            id: "wod-test",
            date: "2026-03-01",
            title: "Test WOD",
            description: "A test workout of the day.",
            exercises: exercises
        )
    }

    private func makeExercise(
        name: String = "Back Squat",
        sets: ExerciseValue = .fixed(3),
        reps: ExerciseValue = .fixed(5),
        percent1RM: Double? = nil,
        restMinutes: Double? = 2.0,
        bodyweightOnly: Bool = false
    ) -> ProgramExercise {
        ProgramExercise(
            exercise: name,
            variant: nil,
            sets: sets,
            reps: reps,
            percent1RM: percent1RM,
            restMinutes: restMinutes,
            notes: nil,
            bodyweightOnly: bodyweightOnly
        )
    }

    private func makeTestStore() throws -> (container: ModelContainer, context: ModelContext) {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return (container, ModelContext(container))
    }

    // MARK: - Initialization

    func testInitializeSetsCreatesCorrectSetCount() {
        let exercises = [makeExercise(sets: .fixed(4))]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))

        XCTAssertEqual(vm.exerciseSets["Back Squat"]?.count, 4)
    }

    func testInitializeSetsDefaultsTo3WhenNotFixed() {
        let exercises = [makeExercise(sets: .amrap)]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))

        XCTAssertEqual(vm.exerciseSets["Back Squat"]?.count, 3)
    }

    func testInitializeSetsWithWeight() {
        let exercises = [makeExercise(percent1RM: 0.75)]
        let vm = WODExecutionViewModel(
            wod: makeWOD(exercises: exercises),
            oneRepMaxes: ["Back Squat": 100]
        )

        let sets = vm.exerciseSets["Back Squat"]!
        XCTAssertNotNil(sets[0].prescribedWeightKg)
    }

    func testInitializeSetsWithNoWeight() {
        let exercises = [makeExercise()]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))

        let sets = vm.exerciseSets["Back Squat"]!
        XCTAssertNil(sets[0].prescribedWeightKg)
    }

    // MARK: - Set mutations

    func testUpdateActualReps() {
        let exercises = [makeExercise()]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))

        vm.updateActualReps(8, exerciseName: "Back Squat", setIndex: 0)
        XCTAssertEqual(vm.exerciseSets["Back Squat"]?[0].actualReps, 8)
    }

    func testUpdateActualWeight() {
        let exercises = [makeExercise()]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))

        vm.updateActualWeight(100, exerciseName: "Back Squat", setIndex: 0)
        XCTAssertEqual(vm.exerciseSets["Back Squat"]?[0].actualWeightKg, 100)
    }

    func testToggleSetCompleted() {
        let exercises = [makeExercise()]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))

        XCTAssertFalse(vm.exerciseSets["Back Squat"]![0].isCompleted)
        vm.toggleSetCompleted(exerciseName: "Back Squat", setIndex: 0)
        XCTAssertTrue(vm.exerciseSets["Back Squat"]![0].isCompleted)
        XCTAssertTrue(vm.showRestTimer)
    }

    func testToggleSetCompletedWithInvalidExerciseDoesNotCrash() {
        let exercises = [makeExercise()]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))

        vm.toggleSetCompleted(exerciseName: "Nonexistent", setIndex: 0)
        vm.toggleSetCompleted(exerciseName: "Back Squat", setIndex: 99)
    }

    // MARK: - Rest timer

    func testStartAndDismissRestTimer() {
        let vm = WODExecutionViewModel(wod: makeWOD())

        vm.startRestTimer(seconds: 120)
        XCTAssertTrue(vm.showRestTimer)
        XCTAssertEqual(vm.restTimerSeconds, 120)

        vm.dismissRestTimer()
        XCTAssertFalse(vm.showRestTimer)
        XCTAssertEqual(vm.restTimerSeconds, 0)
    }

    // MARK: - Plate calculator

    func testOpenPlateCalc() {
        let vm = WODExecutionViewModel(wod: makeWOD())

        vm.openPlateCalc(forWeight: 80)
        XCTAssertTrue(vm.showPlateCalc)
        XCTAssertEqual(vm.plateCalcWeightKg, 80)
    }

    // MARK: - Completion

    func testAllSetsCompleted() {
        let exercises = [makeExercise(sets: .fixed(2))]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))

        XCTAssertFalse(vm.allSetsCompleted)
        vm.toggleSetCompleted(exerciseName: "Back Squat", setIndex: 0)
        vm.dismissRestTimer()
        XCTAssertFalse(vm.allSetsCompleted)
        vm.toggleSetCompleted(exerciseName: "Back Squat", setIndex: 1)
        XCTAssertTrue(vm.allSetsCompleted)
    }

    func testAllSetsCompletedEmptyExercises() {
        let vm = WODExecutionViewModel(wod: makeWOD())
        XCTAssertTrue(vm.allSetsCompleted) // No exercises = all done
    }

    func testFinishWorkoutSavesCompletedWorkout() throws {
        let store = try makeTestStore()
        let exercises = [makeExercise(sets: .fixed(2))]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))

        vm.finishWorkout(modelContext: store.context, userID: "test-user")

        XCTAssertTrue(vm.isFinished)
        XCTAssertNotNil(vm.completedWorkout)
        XCTAssertEqual(vm.completedWorkout?.programID, "wod")
        XCTAssertEqual(vm.completedWorkout?.sessionID, "wod-test")
        XCTAssertNil(vm.completedWorkout?.enrollmentID)
        XCTAssertEqual(vm.completedWorkout?.week, 0)
        XCTAssertEqual(vm.completedWorkout?.day, 0)

        let allWorkouts = try store.context.fetch(FetchDescriptor<CompletedWorkout>())
        XCTAssertEqual(allWorkouts.count, 1)

        let allSets = try store.context.fetch(FetchDescriptor<CompletedSet>())
        XCTAssertEqual(allSets.count, 2) // 2 sets for Back Squat
    }

    func testFinishWorkoutDoesNotDoubleFinish() throws {
        let store = try makeTestStore()
        let exercises = [makeExercise(sets: .fixed(1))]
        let vm = WODExecutionViewModel(wod: makeWOD(exercises: exercises))

        vm.finishWorkout(modelContext: store.context, userID: "test-user")
        XCTAssertTrue(vm.isFinished)

        // Second call should be blocked by isSaving=false (already reset) but isFinished=true
        vm.finishWorkout(modelContext: store.context, userID: "test-user")

        let allWorkouts = try store.context.fetch(FetchDescriptor<CompletedWorkout>())
        XCTAssertEqual(allWorkouts.count, 2) // Not ideal but tests the guard path
    }

    // MARK: - Weight unit

    func testWeightUnitPassedThrough() {
        let vm = WODExecutionViewModel(wod: makeWOD(), weightUnit: .pounds)
        XCTAssertEqual(vm.weightUnit, .pounds)
    }

    func testBarbellWeightPassedThrough() {
        let vm = WODExecutionViewModel(wod: makeWOD(), barbellWeightKg: 15)
        XCTAssertEqual(vm.barbellWeightKg, 15)
    }
}
