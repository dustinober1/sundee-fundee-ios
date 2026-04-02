import XCTest
@testable import SundeeFundeeKit

final class WorkoutTests: XCTestCase {
    func testWorkoutInitialization() {
        let workout = Workout(
            id: "workout-001",
            date: Date(),
            name: "Leg Day",
            exercises: [
                Exercise(
                    id: "squat-001",
                    name: "Back Squat",
                    category: .compound,
                    bodyweight: 150,
                    targetSets: [
                        ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed)
                    ]
                )
            ],
            notes: "Felt strong today",
            duration: 45
        )

        XCTAssertEqual(workout.id, "workout-001")
        XCTAssertEqual(workout.name, "Leg Day")
        XCTAssertEqual(workout.exercises.count, 1)
        XCTAssertEqual(workout.duration, 45)
    }

    func testWorkoutTotalVolume() {
        let workout = Workout(
            id: "workout-002",
            date: Date(),
            name: "Volume Day",
            exercises: [
                Exercise(
                    id: "squat-001",
                    name: "Back Squat",
                    category: .compound,
                    bodyweight: 150,
                    targetSets: [
                        ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed),
                        ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed)
                    ]
                )
            ]
        )

        // 5 reps × 185 lbs × 2 sets = 1850 lbs total volume
        XCTAssertEqual(workout.totalVolume, 1850)
    }
}
