import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("WorkoutCalorieBurnEstimator")
struct WorkoutCalorieBurnEstimatorTests {

    @Test func standard45MinuteStrengthSessionCalculatesReasonableCalories() {
        // 45 min = 2700 sec, 15 completed sets, moderate RPE 7.0, 70 kg bodyweight
        let calories = WorkoutCalorieBurnEstimator.estimateCalories(
            durationSeconds: 2700,
            completedSetsCount: 15,
            averageRPE: 7.0,
            userWeightKg: 70.0,
            isSupersetOrCircuit: false
        )

        // Standard 45-min moderate lifting is ~200 - 300 kcal (approx 4.5-6.5 kcal/min)
        #expect(calories >= 180)
        #expect(calories <= 320)
    }

    @Test func highIntensitySupersetBurnsMoreCaloriesThanStraightSets() {
        let straightCalories = WorkoutCalorieBurnEstimator.estimateCalories(
            durationSeconds: 1800,
            completedSetsCount: 12,
            averageRPE: 8.0,
            userWeightKg: 70.0,
            isSupersetOrCircuit: false
        )

        let supersetCalories = WorkoutCalorieBurnEstimator.estimateCalories(
            durationSeconds: 1800,
            completedSetsCount: 12,
            averageRPE: 8.0,
            userWeightKg: 70.0,
            isSupersetOrCircuit: true
        )

        #expect(supersetCalories > straightCalories)
    }

    @Test func handlesZeroOrVeryShortDurationGracefully() {
        let zeroCalories = WorkoutCalorieBurnEstimator.estimateCalories(
            durationSeconds: 0,
            completedSetsCount: 0,
            averageRPE: nil,
            userWeightKg: nil,
            isSupersetOrCircuit: false
        )
        #expect(zeroCalories == 0)

        let shortCalories = WorkoutCalorieBurnEstimator.estimateCalories(
            durationSeconds: 60, // 1 minute
            completedSetsCount: 1,
            averageRPE: 6.0,
            userWeightKg: 70.0,
            isSupersetOrCircuit: false
        )
        #expect(shortCalories > 0 && shortCalories < 15)
    }

    @Test func scalesWithUserWeight() {
        let lighter = WorkoutCalorieBurnEstimator.estimateCalories(
            durationSeconds: 2400,
            completedSetsCount: 12,
            averageRPE: 7.0,
            userWeightKg: 55.0,
            isSupersetOrCircuit: false
        )

        let heavier = WorkoutCalorieBurnEstimator.estimateCalories(
            durationSeconds: 2400,
            completedSetsCount: 12,
            averageRPE: 7.0,
            userWeightKg: 90.0,
            isSupersetOrCircuit: false
        )

        #expect(heavier > lighter)
    }
}
