import XCTest
@testable import SundeeFundeeKit

final class AIWorkoutTests: XCTestCase {

    // MARK: - Helpers

    func makeExercise(_ name: String, sets: Int = 3, reps: String = "8", bodyweightOnly: Bool = false, weightKg: Double? = nil) -> GeneratedExercise {
        GeneratedExercise(id: "ex-\(name)", name: name, sets: sets, reps: reps, weightKg: weightKg, bodyweightOnly: bodyweightOnly)
    }

    // MARK: - extractMuscleGroups

    func testMuscleGroups_Quads() {
        XCTAssertTrue(extractMuscleGroups([makeExercise("Back Squat")]).contains("Quads"))
    }

    func testMuscleGroups_Glutes() {
        XCTAssertTrue(extractMuscleGroups([makeExercise("Romanian Deadlift")]).contains("Glutes"))
    }

    func testMuscleGroups_Chest() {
        XCTAssertTrue(extractMuscleGroups([makeExercise("Bench Press")]).contains("Chest"))
    }

    func testMuscleGroups_Back() {
        XCTAssertTrue(extractMuscleGroups([makeExercise("Barbell Row")]).contains("Back"))
    }

    func testMuscleGroups_Biceps() {
        XCTAssertTrue(extractMuscleGroups([makeExercise("Barbell Curl")]).contains("Biceps"))
    }

    func testMuscleGroups_Triceps() {
        XCTAssertTrue(extractMuscleGroups([makeExercise("Tricep Extension")]).contains("Triceps"))
    }

    func testMuscleGroups_Core() {
        XCTAssertTrue(extractMuscleGroups([makeExercise("Plank")]).contains("Core"))
    }

    func testMuscleGroups_Calves() {
        XCTAssertTrue(extractMuscleGroups([makeExercise("Calf Raise")]).contains("Calves"))
    }

    func testMuscleGroups_Hamstrings() {
        XCTAssertTrue(extractMuscleGroups([makeExercise("Romanian Deadlift")]).contains("Hamstrings"))
    }

    func testMuscleGroups_ReturnsSorted() {
        let groups = extractMuscleGroups([makeExercise("Back Squat"), makeExercise("Bench Press")])
        XCTAssertEqual(groups, groups.sorted())
    }

    // MARK: - aiDefaultPercentage

    func testDefaultPercentage_HeavyReps() {
        XCTAssertEqual(aiDefaultPercentage(reps: "3"), 0.85, accuracy: 0.01)
    }

    func testDefaultPercentage_MediumReps() {
        XCTAssertEqual(aiDefaultPercentage(reps: "5"), 0.80, accuracy: 0.01)
    }

    func testDefaultPercentage_LightReps() {
        XCTAssertEqual(aiDefaultPercentage(reps: "8"), 0.70, accuracy: 0.01)
    }

    func testDefaultPercentage_Range() {
        XCTAssertEqual(aiDefaultPercentage(reps: "8-10"), 0.70, accuracy: 0.01)
    }

    // MARK: - assignRestMinutes

    func testRestMinutes_Bodyweight() {
        XCTAssertEqual(assignRestMinutes(bodyweight: true, reps: "5"), 1.0, accuracy: 0.01)
    }

    func testRestMinutes_Heavy() {
        XCTAssertEqual(assignRestMinutes(bodyweight: false, reps: "3"), 2.5, accuracy: 0.01)
    }

    func testRestMinutes_Light() {
        XCTAssertEqual(assignRestMinutes(bodyweight: false, reps: "12"), 1.5, accuracy: 0.01)
    }

    // MARK: - totalEstimatedMinutes

    func testTotalMinutes_SingleExercise() {
        let exercises = [makeExercise("Back Squat", sets: 4, reps: "5")]
        let minutes = totalEstimatedMinutes(exercises)
        XCTAssertGreaterThan(minutes, 0)
    }

    // MARK: - energyMultiplier

    func testEnergyMultiplier_Low() {
        XCTAssertEqual(energyMultiplier(.low), 0.85, accuracy: 0.01)
    }

    func testEnergyMultiplier_Medium() {
        XCTAssertEqual(energyMultiplier(.medium), 1.0, accuracy: 0.01)
    }

    func testEnergyMultiplier_High() {
        XCTAssertEqual(energyMultiplier(.high), 1.05, accuracy: 0.01)
    }

    // MARK: - aiCyclePhaseMultiplier

    func testCycleMultiplier_Menstrual() {
        XCTAssertEqual(aiCyclePhaseMultiplier(.menstrual), 0.90, accuracy: 0.01)
    }

    func testCycleMultiplier_Ovulation() {
        XCTAssertEqual(aiCyclePhaseMultiplier(.ovulation), 1.12, accuracy: 0.01)
    }

    func testCycleMultiplier_Nil() {
        XCTAssertEqual(aiCyclePhaseMultiplier(nil), 1.0, accuracy: 0.01)
    }

    // MARK: - findMatchingMax

    func testFindMax_ExactMatch() {
        let maxes = [ExerciseMax(name: "Back Squat", weightKg: 150)]
        let result = findMatchingMax("Back Squat", maxes: maxes)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.weightKg, 150, accuracy: 0.01)
    }

    func testFindMax_FuzzyMatch() {
        let maxes = [ExerciseMax(name: "Squat", weightKg: 150)]
        let result = findMatchingMax("Back Squat", maxes: maxes)
        XCTAssertNotNil(result)
    }

    func testFindMax_NoMatch() {
        let maxes = [ExerciseMax(name: "Bench Press", weightKg: 100)]
        XCTAssertNil(findMatchingMax("Back Squat", maxes: maxes))
    }

    // MARK: - applyWeights

    func testApplyWeights_SetsWeight() {
        let exercises = [makeExercise("Back Squat", reps: "5")]
        let maxes = [ExerciseMax(name: "Back Squat", weightKg: 200)]
        let result = applyWeights(exercises: exercises, maxes: maxes, energyMult: 1.0, cycleMult: 1.0)
        let weight = result[0].weightKg
        XCTAssertNotNil(weight)
        XCTAssertGreaterThan(weight!, 0)
    }

    func testApplyWeights_SkipsBodyweight() {
        let exercises = [makeExercise("Pull-Up", bodyweightOnly: true)]
        let maxes = [ExerciseMax(name: "Pull-Up", weightKg: 80)]
        let result = applyWeights(exercises: exercises, maxes: maxes, energyMult: 1.0, cycleMult: 1.0)
        XCTAssertNil(result[0].weightKg)
    }
}
