import XCTest
@testable import SundeeFundeeKit

final class ActiveRecoveryWorkoutBuilderTests: XCTestCase {
    func testBuilderCreatesThreeToFiveExercises() {
        let workout = ActiveRecoveryWorkoutBuilder.build(
            equipment: .fullGym,
            cyclePhase: .follicular
        )

        XCTAssertGreaterThanOrEqual(workout.exercises.count, 3)
        XCTAssertLessThanOrEqual(workout.exercises.count, 5)
    }

    func testBuilderAvoidsMaxEffortNaming() {
        let workout = ActiveRecoveryWorkoutBuilder.build(
            equipment: .kettlebellOnly,
            cyclePhase: .follicular
        )
        let names = workout.exercises.map { $0.name.lowercased() }

        XCTAssertFalse(names.contains(where: { $0.contains("max") }))
        XCTAssertFalse(names.contains(where: { $0.contains("1rm") }))
    }

    func testMenstrualContextFavorsLowStressMovements() {
        let workout = ActiveRecoveryWorkoutBuilder.build(
            equipment: .kettlebellOnly,
            cyclePhase: .menstrual
        )
        let names = workout.exercises.map { $0.name.lowercased() }

        XCTAssertTrue(names.contains(where: { $0.contains("walking") || $0.contains("cat-cow") || $0.contains("bird dog") }))
        XCTAssertFalse(names.contains(where: { $0.contains("swing") }))
    }
}
