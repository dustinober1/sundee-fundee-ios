import XCTest
@testable import SundeeFundeeKit

final class StarterWorkoutBuilderTests: XCTestCase {
    func testBeginnerStarterDoesNotRequireMaxes() {
        let workout = StarterWorkoutBuilder.build(context: StarterWorkoutContext(
            experienceLevel: .beginner,
            primaryGoal: .strength,
            weightUnit: .lbs,
            cycleTrackingEnabled: true
        ))

        XCTAssertTrue((4...6).contains(workout.exercises.count))
        XCTAssertTrue(workout.exercises.allSatisfy { $0.targetSets.count >= 2 })
        XCTAssertTrue(workout.exercises.flatMap(\.targetSets).allSatisfy { $0.prescribedWeight == 0 })
    }

    func testIntermediateAdvancedAndWeightLossPathsReturnValidWorkouts() {
        let contexts = [
            StarterWorkoutContext(experienceLevel: .intermediate, primaryGoal: .strength, weightUnit: .lbs, cycleTrackingEnabled: false),
            StarterWorkoutContext(experienceLevel: .advanced, primaryGoal: .hypertrophy, weightUnit: .kg, cycleTrackingEnabled: false),
            StarterWorkoutContext(experienceLevel: .beginner, primaryGoal: .weightLoss, weightUnit: .lbs, cycleTrackingEnabled: false)
        ]

        for context in contexts {
            let workout = StarterWorkoutBuilder.build(context: context)
            XCTAssertTrue((4...6).contains(workout.exercises.count))
            XCTAssertTrue(workout.exercises.allSatisfy { $0.targetSets.count >= 2 })
        }
    }
}
