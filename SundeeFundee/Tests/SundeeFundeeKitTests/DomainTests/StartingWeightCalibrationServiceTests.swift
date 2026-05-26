import XCTest
@testable import SundeeFundeeKit

final class StartingWeightCalibrationServiceTests: XCTestCase {
    func testKnownMaxReturnsPercentageBasedLoad() {
        let exercise = weightedExercise(name: "Back Squat", reps: 5)
        let suggestion = StartingWeightCalibrationService.suggestion(
            for: exercise,
            maxRecords: [OneRepMaxRecord(id: "1", exerciseName: "Back Squat", weight: 200, unit: .lbs, date: Date())],
            experienceLevel: .intermediate,
            recoveryScore: nil,
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
            recoveryScore: nil,
            unit: .lbs
        )

        XCTAssertEqual(suggestion.suggestedWeight, 45)
    }

    func testLowRecoveryReducesSuggestedLoad() {
        let exercise = weightedExercise(name: "Back Squat", reps: 5)
        let highRecoverySuggestion = StartingWeightCalibrationService.suggestion(
            for: exercise,
            maxRecords: [OneRepMaxRecord(id: "1", exerciseName: "Back Squat", weight: 200, unit: .lbs, date: Date())],
            experienceLevel: .advanced,
            recoveryScore: makeRecovery(total: 80),
            unit: .lbs
        )
        let lowRecoverySuggestion = StartingWeightCalibrationService.suggestion(
            for: exercise,
            maxRecords: [OneRepMaxRecord(id: "1", exerciseName: "Back Squat", weight: 200, unit: .lbs, date: Date())],
            experienceLevel: .advanced,
            recoveryScore: makeRecovery(total: 35),
            unit: .lbs
        )

        XCTAssertNotNil(highRecoverySuggestion.suggestedWeight)
        XCTAssertNotNil(lowRecoverySuggestion.suggestedWeight)
        XCTAssertTrue((lowRecoverySuggestion.suggestedWeight ?? 0) < (highRecoverySuggestion.suggestedWeight ?? 0))
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
            experienceLevel: .beginner,
            recoveryScore: nil
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

    private func makeRecovery(total: Int) -> RecoveryScore {
        RecoveryScore(
            total: total,
            recommendation: total >= 70 ? .pushDay : (total >= 40 ? .moderate : .restDay),
            subScores: [.sleep: total],
            presentInputCount: 1,
            totalInputCount: 5,
            explanations: [.sleep: "Sleep"]
        )
    }
}
