import XCTest
@testable import SundeeFundeeKit

final class ExerciseTests: XCTestCase {
    func testExerciseInitialization() {
        let exercise = Exercise(
            id: "squat-001",
            name: "Back Squat",
            category: .compound,
            bodyweight: 150,
            targetSets: [
                ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed),
                ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed),
                ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed),
            ]
        )

        XCTAssertEqual(exercise.id, "squat-001")
        XCTAssertEqual(exercise.name, "Back Squat")
        XCTAssertEqual(exercise.category, .compound)
        XCTAssertEqual(exercise.bodyweight, 150)
        XCTAssertEqual(exercise.targetSets.count, 3)
    }

    func testExerciseTypeEnum() {
        XCTAssertEqual(ExerciseType.fixed.description, "Fixed")
        XCTAssertEqual(ExerciseType.amrap.description, "AMRAP")
        XCTAssertEqual(ExerciseType.range(min: 8, max: 12).description, "8-12 reps")
    }
}
