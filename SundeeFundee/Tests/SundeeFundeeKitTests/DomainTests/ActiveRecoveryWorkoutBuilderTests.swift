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

    func testBuildFromSourceReturnsIndependentSafeDraft() {
        let source = Workout(date: Date(timeIntervalSince1970: 123), name: "Planned Session", exercises: [])
        let draft = ActiveRecoveryWorkoutBuilder.build(from: source, equipment: .bodyweightOnly)

        XCTAssertEqual(draft.date, source.date)
        XCTAssertNotEqual(draft.name, source.name)
        XCTAssertFalse(draft.exercises.isEmpty)
        XCTAssertTrue(draft.exercises.allSatisfy { exercise in
            exercise.targetSets.allSatisfy { $0.prescribedWeight == 0 }
        })
    }
}
