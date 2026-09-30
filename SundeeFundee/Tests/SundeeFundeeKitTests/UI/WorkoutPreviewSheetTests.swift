import XCTest
import SwiftUI
@testable import SundeeFundeeKit

@MainActor
final class WorkoutPreviewSheetTests: XCTestCase {
    func testWorkoutPreviewSheetInitializesAndExecutesCallback() {
        let workout = Workout(
            id: "workout-preview-1",
            date: Date(),
            name: "Upper Body Strength",
            exercises: [
                Exercise(
                    id: "bench-press",
                    name: "Bench Press",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed),
                        ExerciseSet(reps: 5, prescribedWeight: 185, type: .fixed)
                    ],
                    restMinutes: 2.0
                )
            ]
        )

        var startedWorkout: Workout?
        let sheet = WorkoutPreviewSheet(workout: workout) { selected in
            startedWorkout = selected
        }

        XCTAssertNotNil(sheet)
        XCTAssertEqual(sheet.workout.name, "Upper Body Strength")
        XCTAssertEqual(sheet.workout.exercises.count, 1)

        sheet.onStart(workout)
        XCTAssertEqual(startedWorkout?.id, "workout-preview-1")
    }
}
