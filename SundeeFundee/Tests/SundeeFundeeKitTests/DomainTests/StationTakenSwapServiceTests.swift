import XCTest
@testable import SundeeFundeeKit

final class StationTakenSwapServiceTests: XCTestCase {
    func testRackTakenWithDumbbellsRanksGobletSquatAheadOfUnrelatedUpperBodyMovements() {
        let swaps = StationTakenSwapService.rankedSwaps(
            request: StationTakenSwapRequest(
                exerciseName: "Back Squat",
                blockedStation: .rack,
                equipment: .homeDumbbells,
                painLogs: []
            )
        )

        let names = swaps.map(\.exerciseName)
        guard let gobletIndex = names.firstIndex(of: "Goblet Squat") else {
            XCTFail("Expected Goblet Squat in station-taken substitutions")
            return
        }

        XCTAssertEqual(gobletIndex, 0)
        XCTAssertFalse(names.contains("Back Squat"))

        let unrelatedUpperBody = ["Dumbbell Bench Press", "Dumbbell Row", "Push-Up"]
        for name in unrelatedUpperBody {
            if let index = names.firstIndex(of: name) {
                XCTAssertLessThan(gobletIndex, index)
            }
        }
    }

    func testBenchTakenForBarbellBenchRanksDumbbellPressOrPushUpVariation() {
        let swaps = StationTakenSwapService.rankedSwaps(
            request: StationTakenSwapRequest(
                exerciseName: "Flat Barbell Bench Press",
                blockedStation: .bench,
                equipment: .homeDumbbells,
                painLogs: []
            )
        )

        let names = swaps.map(\.exerciseName)
        XCTAssertFalse(names.contains { $0.localizedCaseInsensitiveContains("bench") })
        XCTAssertTrue(
            names.prefix(3).contains(where: { name in
                name == "Dumbbell Overhead Press"
                    || name.localizedCaseInsensitiveContains("Push-Up")
            }),
            "Expected a no-bench dumbbell press or push-up variation near the top, got \(names)"
        )
    }

    @MainActor
    @available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
    func testStationTakenRankingDoesNotSilentlyClearCompletedSets() {
        let completedSet = ExerciseSet(
            reps: 5,
            prescribedWeight: 185,
            type: .fixed,
            completedWeight: 185,
            actualReps: 5,
            isComplete: true
        )
        let pendingSet = ExerciseSet(
            reps: 5,
            prescribedWeight: 185,
            type: .fixed
        )
        let exercise = Exercise(
            id: "back-squat",
            name: "Back Squat",
            category: .compound,
            bodyweight: 0,
            targetSets: [completedSet, pendingSet]
        )
        let workout = Workout(
            id: "station-taken-workout",
            date: Date(),
            name: "Station Taken Test",
            exercises: [exercise]
        )
        let viewModel = ActiveWorkoutSessionViewModel(
            workout: workout,
            dataClient: MockCloudKitClient(),
            healthClient: MockHealthKitClient()
        )

        let swaps = viewModel.stationTakenSwaps(
            blockedStation: .rack,
            painLogs: []
        )

        XCTAssertFalse(swaps.isEmpty)
        XCTAssertTrue(viewModel.currentExerciseHasProgress)
        XCTAssertEqual(viewModel.currentExercise?.name, "Back Squat")
        XCTAssertEqual(viewModel.currentExercise?.targetSets.first?.isComplete, true)
        XCTAssertEqual(viewModel.currentExercise?.targetSets.first?.completedWeight, 185)
    }
}
