import XCTest
@testable import SundeeFundeeKit

final class EquipmentConversionServiceTests: XCTestCase {
    func testConvertsFullGymWorkoutToDumbbells() {
        let workout = workout(named: "Flat Barbell Bench Press")
        let converted = EquipmentConversionService.convert(workout: workout, to: .homeDumbbells)

        XCTAssertFalse(converted.changes.isEmpty)
        XCTAssertTrue(EquipmentConversionService.matchesEquipment(
            exerciseName: converted.workout.exercises[0].name,
            equipment: .homeDumbbells
        ))
    }

    func testConvertsFullGymWorkoutToBands() {
        let workout = workout(named: "Cable Row")
        let converted = EquipmentConversionService.convert(workout: workout, to: .resistanceBands)

        XCTAssertFalse(converted.changes.isEmpty)
        XCTAssertTrue(EquipmentConversionService.matchesEquipment(
            exerciseName: converted.workout.exercises[0].name,
            equipment: .resistanceBands
        ))
    }

    func testConvertsFullGymWorkoutToKettlebell() {
        let workout = workout(named: "Romanian Deadlift (No Straps)")
        let converted = EquipmentConversionService.convert(workout: workout, to: .kettlebellOnly)

        XCTAssertFalse(converted.changes.isEmpty)
        XCTAssertTrue(EquipmentConversionService.matchesEquipment(
            exerciseName: converted.workout.exercises[0].name,
            equipment: .kettlebellOnly
        ))
    }

    func testConvertsFullGymWorkoutToBodyweight() {
        let workout = workout(named: "Lat Pulldown")
        let converted = EquipmentConversionService.convert(workout: workout, to: .bodyweightOnly)

        XCTAssertFalse(converted.changes.isEmpty)
        XCTAssertTrue(EquipmentConversionService.matchesEquipment(
            exerciseName: converted.workout.exercises[0].name,
            equipment: .bodyweightOnly
        ))
    }

    private func workout(named exerciseName: String) -> Workout {
        Workout(
            date: Date(),
            name: "Test",
            exercises: [
                Exercise(
                    id: UUID().uuidString,
                    name: exerciseName,
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(reps: 8, prescribedWeight: 95, type: .fixed)
                    ]
                )
            ]
        )
    }
}
