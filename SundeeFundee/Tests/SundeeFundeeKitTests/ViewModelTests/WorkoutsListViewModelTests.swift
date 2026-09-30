import Testing
import Foundation
@testable import SundeeFundeeKit

private let calendar = Calendar.current

private func makeDate(year: Int, month: Int, day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12, minute: 0, second: 0))!
}

@Suite("WorkoutsListViewModelTests")
@MainActor
struct WorkoutsListViewModelTests {

    @Test("loadWorkouts merges workouts + benchmark results into one timeline")
    @available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
    func testLoadWorkoutsMergesAndSortsTimeline() async throws {
        let mock = MockCloudKitClient()

        let workoutNewDate = makeDate(year: 2026, month: 3, day: 3)
        let benchmarkDate = makeDate(year: 2026, month: 3, day: 2)
        let workoutOldDate = makeDate(year: 2026, month: 3, day: 1)

        let workoutNew = Workout(
            id: "workout-new",
            date: workoutNewDate,
            name: "Workout New",
            exercises: [],
            duration: 0,
            completedAt: nil
        )
        let workoutOld = Workout(
            id: "workout-old",
            date: workoutOldDate,
            name: "Workout Old",
            exercises: [],
            duration: 30,
            completedAt: workoutOldDate
        )
        let benchmarkResult = BenchmarkResult(
            id: "result-1",
            benchmarkId: "classic-fran",
            benchmarkName: "Fran",
            score: 125,
            date: benchmarkDate
        )

        try await mock.save([workoutNew, workoutOld], recordType: "Workout")
        try await mock.save([benchmarkResult], recordType: "BenchmarkResult")

        let vm = WorkoutsListViewModel(dataClient: mock)
        await vm.loadWorkouts()

        #expect(vm.workouts.map(\.id) == ["workout-new", "benchmark-result-1", "workout-old"])

        let benchmarkItem = vm.workouts[1]
        #expect(benchmarkItem.name == "Fran Benchmark")
        #expect(benchmarkItem.isComplete == true)
        #expect(benchmarkItem.isRedoable == false)
        #expect(benchmarkItem.duration == 3)

        guard case let .benchmark(resultId, benchmarkId, scoreText) = benchmarkItem.source else {
            #expect(Bool(false), "Expected benchmark item source")
            return
        }
        #expect(resultId == "result-1")
        #expect(benchmarkId == "classic-fran")
        #expect(scoreText == "2:05")
    }

    @Test("resumeCandidate ignores benchmark items")
    @available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
    func testResumeCandidateIgnoresBenchmarks() async throws {
        let mock = MockCloudKitClient()

        let benchmarkDate = makeDate(year: 2026, month: 3, day: 2)
        let benchmarkResult = BenchmarkResult(
            id: "result-1",
            benchmarkId: "classic-fran",
            benchmarkName: "Fran",
            score: 125,
            date: benchmarkDate
        )
        try await mock.save([benchmarkResult], recordType: "BenchmarkResult")

        let vm = WorkoutsListViewModel(dataClient: mock)
        await vm.loadWorkouts()

        #expect(vm.workouts.count == 1)
        #expect(vm.resumeCandidate == nil)
    }

    @Test("redo preserves active-recovery completion provenance")
    @available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
    func redoPreservesActiveRecoveryKind() async throws {
        let mock = MockCloudKitClient()
        let recovery = Workout(
            id: "recovery",
            date: Date(timeIntervalSince1970: 1),
            name: "Active recovery",
            exercises: [],
            kind: .activeRecovery
        )
        try await mock.save(recovery, recordType: "Workout")

        let viewModel = WorkoutsListViewModel(
            dataClient: mock,
            healthClient: MockHealthKitClient()
        )
        let session = await viewModel.redoWorkout(id: recovery.id)

        #expect(session?.workout.kind == .activeRecovery)
    }

    @Test("NewWorkoutViewModel pairWithNext creates superset with proper labels and rest")
    @available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
    func testSupersetBuilderGroupsConsecutiveExercises() async throws {
        let mock = MockCloudKitClient()
        let vm = NewWorkoutViewModel(dataClient: mock)
        vm.workoutName = "Upper Body Superset"
        vm.addExercises(["Bench Press", "Barbell Row", "Overhead Press"])

        #expect(vm.exercises.count == 3)
        #expect(vm.groupDisplayLabel(for: 0) == nil)

        // Pair exercise 0 and 1
        vm.pairWithNext(at: 0)

        #expect(vm.exercises[0].groupTag == "A")
        #expect(vm.exercises[1].groupTag == "A")
        #expect(vm.exercises[2].groupTag == nil)

        #expect(vm.groupDisplayLabel(for: 0) == "Superset A1")
        #expect(vm.groupDisplayLabel(for: 1) == "Superset A2")
        #expect(vm.groupDisplayLabel(for: 2) == nil)

        let workout = await vm.createWorkout()
        #expect(workout != nil)
        guard let workout else { return }

        #expect(workout.exercises[0].grouping?.groupID == "group-a")
        #expect(workout.exercises[0].grouping?.groupType == .superset)
        #expect(workout.exercises[0].grouping?.label == "A1")
        #expect(workout.exercises[0].grouping?.transitionRestSeconds == 30)
        #expect(workout.exercises[0].grouping?.groupRestSeconds == 90)

        #expect(workout.exercises[1].grouping?.groupID == "group-a")
        #expect(workout.exercises[1].grouping?.groupType == .superset)
        #expect(workout.exercises[1].grouping?.label == "A2")

        #expect(workout.exercises[2].grouping == nil)
    }

    @Test("NewWorkoutViewModel creates circuit when 3 or more exercises share a group")
    @available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
    func testCircuitBuilderGroupsThreeExercises() async throws {
        let mock = MockCloudKitClient()
        let vm = NewWorkoutViewModel(dataClient: mock)
        vm.workoutName = "Core Circuit"
        vm.addExercises(["Plank", "Russian Twist", "Hanging Leg Raise"])

        vm.setGroupTag(at: 0, tag: "B")
        vm.setGroupTag(at: 1, tag: "B")
        vm.setGroupTag(at: 2, tag: "B")

        #expect(vm.groupDisplayLabel(for: 0) == "Circuit B1")
        #expect(vm.groupDisplayLabel(for: 1) == "Circuit B2")
        #expect(vm.groupDisplayLabel(for: 2) == "Circuit B3")

        let workout = await vm.createWorkout()
        guard let workout else {
            #expect(Bool(false), "Workout creation failed")
            return
        }

        #expect(workout.exercises.count == 3)
        for (i, exercise) in workout.exercises.enumerated() {
            #expect(exercise.grouping?.groupID == "group-b")
            #expect(exercise.grouping?.groupType == .circuit)
            #expect(exercise.grouping?.label == "B\(i + 1)")
        }
    }

    @Test("WorkoutsListViewModel filters workouts by selectedFilter")
    @available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
    func testHistoryFilteringByFilterKind() async throws {
        let mock = MockCloudKitClient()

        let standardWorkout = Workout(
            id: "std-1",
            date: makeDate(year: 2026, month: 3, day: 3),
            name: "Heavy Upper",
            exercises: [Exercise(id: "e1", name: "Bench Press", category: .compound, bodyweight: 0, targetSets: [])],
            kind: .standard
        )
        let recoveryWorkout = Workout(
            id: "rec-1",
            date: makeDate(year: 2026, month: 3, day: 2),
            name: "Mobility Flow",
            exercises: [Exercise(id: "e2", name: "Cat Cow", category: .accessory, bodyweight: 1, targetSets: [])],
            kind: .activeRecovery
        )
        let benchmarkResult = BenchmarkResult(
            id: "bm-1",
            benchmarkId: "classic-cindy",
            benchmarkName: "Cindy",
            score: 20,
            date: makeDate(year: 2026, month: 3, day: 1)
        )

        try await mock.save([standardWorkout, recoveryWorkout], recordType: "Workout")
        try await mock.save([benchmarkResult], recordType: "BenchmarkResult")

        let vm = WorkoutsListViewModel(dataClient: mock)
        await vm.loadWorkouts()

        // Default .all
        #expect(vm.filteredWorkouts.count == 3)

        // Filter: .strength
        vm.selectedFilter = .strength
        #expect(vm.filteredWorkouts.count == 1)
        #expect(vm.filteredWorkouts.first?.id == "std-1")

        // Filter: .activeRecovery
        vm.selectedFilter = .activeRecovery
        #expect(vm.filteredWorkouts.count == 1)
        #expect(vm.filteredWorkouts.first?.id == "rec-1")

        // Filter: .benchmarks
        vm.selectedFilter = .benchmarks
        #expect(vm.filteredWorkouts.count == 1)
        #expect(vm.filteredWorkouts.first?.id == "benchmark-bm-1")
    }

    @Test("WorkoutsListViewModel filters workouts by search query on name or exercises")
    @available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
    func testSearchFilteringByNameAndExercise() async throws {
        let mock = MockCloudKitClient()

        let workout1 = Workout(
            id: "w1",
            date: makeDate(year: 2026, month: 3, day: 3),
            name: "Chest Day",
            exercises: [
                Exercise(id: "e1", name: "Incline Dumbbell Press", category: .compound, bodyweight: 0, targetSets: []),
                Exercise(id: "e2", name: "Tricep Pushdown", category: .accessory, bodyweight: 0, targetSets: [])
            ]
        )
        let workout2 = Workout(
            id: "w2",
            date: makeDate(year: 2026, month: 3, day: 2),
            name: "Leg Day",
            exercises: [
                Exercise(id: "e3", name: "Barbell Back Squat", category: .compound, bodyweight: 0, targetSets: [])
            ]
        )

        try await mock.save([workout1, workout2], recordType: "Workout")

        let vm = WorkoutsListViewModel(dataClient: mock)
        await vm.loadWorkouts()

        #expect(vm.filteredWorkouts.count == 2)

        // Search by workout name
        vm.searchText = "chest"
        #expect(vm.filteredWorkouts.count == 1)
        #expect(vm.filteredWorkouts.first?.id == "w1")

        // Search by exercise name
        vm.searchText = "squat"
        #expect(vm.filteredWorkouts.count == 1)
        #expect(vm.filteredWorkouts.first?.id == "w2")

        // Search with no matches
        vm.searchText = "deadlift"
        #expect(vm.filteredWorkouts.isEmpty)
    }

    @Test("redo preserves exercise groupings for supersets")
    @available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
    func testRedoPreservesExerciseGrouping() async throws {
        let mock = MockCloudKitClient()
        let groupingA1 = ExerciseGrouping(groupID: "group-a", groupType: .superset, label: "A1")
        let groupingA2 = ExerciseGrouping(groupID: "group-a", groupType: .superset, label: "A2")

        let workout = Workout(
            id: "superset-workout",
            date: Date(timeIntervalSince1970: 1000),
            name: "Superset Session",
            exercises: [
                Exercise(id: "e1", name: "Biceps Curl", category: .accessory, bodyweight: 0, targetSets: [], grouping: groupingA1),
                Exercise(id: "e2", name: "Triceps Extension", category: .accessory, bodyweight: 0, targetSets: [], grouping: groupingA2)
            ]
        )
        try await mock.save(workout, recordType: "Workout")

        let viewModel = WorkoutsListViewModel(
            dataClient: mock,
            healthClient: MockHealthKitClient()
        )
        let session = await viewModel.redoWorkout(id: workout.id)

        #expect(session != nil)
        #expect(session?.workout.exercises[0].grouping?.label == "A1")
        #expect(session?.workout.exercises[1].grouping?.label == "A2")
    }
}
