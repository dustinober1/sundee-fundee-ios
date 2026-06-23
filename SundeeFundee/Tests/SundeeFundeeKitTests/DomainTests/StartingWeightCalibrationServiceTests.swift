import XCTest
@testable import SundeeFundeeKit

final class StartingWeightCalibrationServiceTests: XCTestCase {
    func testKnownMaxReturnsPercentageBasedLoad() {
        let exercise = weightedExercise(name: "Back Squat", reps: 5)
        let suggestion = StartingWeightCalibrationService.suggestion(
            for: exercise,
            maxRecords: [OneRepMaxRecord(id: "1", exerciseName: "Back Squat", weight: 200, unit: .lbs, date: Date())],
            experienceLevel: .intermediate,
            unit: .lbs
        )

        XCTAssertEqual(suggestion.suggestedWeight, 155)
        XCTAssertGreaterThan(suggestion.confidence, 0.8)
    }

    func testBeginnerWithoutMaxReturnsConservativeStarter() {
        let exercise = weightedExercise(name: "Back Squat", reps: 8)
        let suggestion = StartingWeightCalibrationService.suggestion(
            for: exercise,
            maxRecords: [],
            experienceLevel: .beginner,
            unit: .lbs
        )

        XCTAssertEqual(suggestion.suggestedWeight, 45)
    }

    func testExperienceLevelAdjustsSuggestedLoad() {
        let exercise = weightedExercise(name: "Back Squat", reps: 5)
        let beginnerSuggestion = StartingWeightCalibrationService.suggestion(
            for: exercise,
            maxRecords: [OneRepMaxRecord(id: "1", exerciseName: "Back Squat", weight: 200, unit: .lbs, date: Date())],
            experienceLevel: .beginner,
            unit: .lbs
        )
        let advancedSuggestion = StartingWeightCalibrationService.suggestion(
            for: exercise,
            maxRecords: [OneRepMaxRecord(id: "1", exerciseName: "Back Squat", weight: 200, unit: .lbs, date: Date())],
            experienceLevel: .advanced,
            unit: .lbs
        )

        XCTAssertNotNil(beginnerSuggestion.suggestedWeight)
        XCTAssertNotNil(advancedSuggestion.suggestedWeight)
        XCTAssertTrue((beginnerSuggestion.suggestedWeight ?? 0) < (advancedSuggestion.suggestedWeight ?? 0))
    }

    func testBodyweightExerciseReturnsGuidanceInsteadOfWeight() {
        let exercise = Exercise(
            id: "bw",
            name: "Push-Up",
            category: .accessory,
            bodyweight: 1.0,
            targetSets: [ExerciseSet(reps: 12, prescribedWeight: 0, type: .fixed)]
        )

        let suggestion = StartingWeightCalibrationService.suggestion(
            for: exercise,
            maxRecords: [],
            experienceLevel: .beginner
        )

        XCTAssertNil(suggestion.suggestedWeight)
        XCTAssertNotNil(suggestion.repsGuidance)
    }

    private func weightedExercise(name: String, reps: Int) -> Exercise {
        Exercise(
            id: UUID().uuidString,
            name: name,
            category: .compound,
            bodyweight: 0,
            targetSets: [ExerciseSet(reps: reps, prescribedWeight: 0, type: .fixed)]
        )
    }
}
