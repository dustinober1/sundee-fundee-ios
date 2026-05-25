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
}
