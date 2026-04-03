import XCTest
@testable import SundeeFundeeKit

final class ExerciseCatalogTests: XCTestCase {

    // MARK: - Weightlifting Exercises

    func testWeightliftingExercises_TotalCount() {
        XCTAssertEqual(weightliftingExercises.count, 59)
    }

    func testWeightliftingExercises_SquatCount() {
        let count = weightliftingExercises.filter { $0.category == .squat }.count
        XCTAssertEqual(count, 9)
    }

    func testWeightliftingExercises_HipHingeCount() {
        let count = weightliftingExercises.filter { $0.category == .hipHinge }.count
        XCTAssertEqual(count, 13)
    }

    func testWeightliftingExercises_PressCount() {
        let count = weightliftingExercises.filter { $0.category == .press }.count
        XCTAssertEqual(count, 10)
    }

    func testWeightliftingExercises_PullCount() {
        let count = weightliftingExercises.filter { $0.category == .pull }.count
        XCTAssertEqual(count, 12)
    }

    func testWeightliftingExercises_CarryCount() {
        let count = weightliftingExercises.filter { $0.category == .carry }.count
        XCTAssertEqual(count, 4)
    }

    func testWeightliftingExercises_OlympicCount() {
        let count = weightliftingExercises.filter { $0.category == .olympicWeightlifting }.count
        XCTAssertEqual(count, 11) // 11 from original TS: + Muscle Snatch + Muscle Clean
    }

    // MARK: - isWeightliftingExercise

    func testIsWeightlifting_BackSquat() {
        XCTAssertTrue(isWeightliftingExercise("Back Squat"))
    }

    func testIsWeightlifting_DeadliftWithStraps() {
        XCTAssertTrue(isWeightliftingExercise("Conventional Deadlift (With Straps)"))
    }

    func testIsWeightlifting_CleanAndJerk() {
        XCTAssertTrue(isWeightliftingExercise("Clean and Jerk"))
    }

    func testIsWeightlifting_UnknownExercise() {
        XCTAssertFalse(isWeightliftingExercise("Bicep Curl"))
    }

    func testIsWeightlifting_EmptyString() {
        XCTAssertFalse(isWeightliftingExercise(""))
    }

    // MARK: - Conditioning Exercises

    func testConditioningExercises_TotalCount() {
        XCTAssertEqual(conditioningExercises.count, 31)
    }

    func testIsConditioning_WallBall() {
        XCTAssertTrue(isConditioningExercise("Wall Ball"))
    }

    func testIsConditioning_500mRow() {
        XCTAssertTrue(isConditioningExercise("500m Row"))
    }

    func testIsConditioning_UnknownExercise() {
        XCTAssertFalse(isConditioningExercise("Back Squat"))
    }

    // MARK: - conditioningScoringType

    func testScoringType_WallBall_IsReps() {
        XCTAssertEqual(conditioningScoringType(for: "Wall Ball"), .reps)
    }

    func testScoringType_500mRow_IsTime() {
        XCTAssertEqual(conditioningScoringType(for: "500m Row"), .time)
    }

    func testScoringType_Unknown_IsNil() {
        XCTAssertNil(conditioningScoringType(for: "Unknown"))
    }

    // MARK: - formatConditioningValue

    func testFormatConditioning_Time() {
        XCTAssertEqual(formatConditioningValue(185, type: .time), "3:05")
    }

    func testFormatConditioning_Time_EvenMinutes() {
        XCTAssertEqual(formatConditioningValue(120, type: .time), "2:00")
    }

    func testFormatConditioning_Reps_Singular() {
        XCTAssertEqual(formatConditioningValue(1, type: .reps), "1 rep")
    }

    func testFormatConditioning_Reps_Plural() {
        XCTAssertEqual(formatConditioningValue(15, type: .reps), "15 reps")
    }

    // MARK: - isBetterConditioningScore

    func testBetterScore_Time_LowerIsBetter() {
        XCTAssertTrue(isBetterConditioningScore(newValue: 180, existingValue: 200, type: .time))
        XCTAssertFalse(isBetterConditioningScore(newValue: 200, existingValue: 180, type: .time))
    }

    func testBetterScore_Reps_HigherIsBetter() {
        XCTAssertTrue(isBetterConditioningScore(newValue: 20, existingValue: 15, type: .reps))
        XCTAssertFalse(isBetterConditioningScore(newValue: 10, existingValue: 15, type: .reps))
    }

    func testBetterScore_NilExisting_AlwaysBetter() {
        XCTAssertTrue(isBetterConditioningScore(newValue: 100, existingValue: nil, type: .time))
        XCTAssertTrue(isBetterConditioningScore(newValue: 10, existingValue: nil, type: .reps))
    }
}
