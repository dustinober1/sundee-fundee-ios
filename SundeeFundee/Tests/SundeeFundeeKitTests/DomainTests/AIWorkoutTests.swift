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

    // MARK: - Workout generation rules

    func testKettlebellOnlyAllowsKettlebellMovements() {
        XCTAssertTrue(isExerciseAllowed("Kettlebell Swing", for: .kettlebellOnly))
        XCTAssertTrue(isExerciseAllowed("Goblet Squat", for: .kettlebellOnly))
        XCTAssertFalse(isExerciseAllowed("Flat Barbell Bench Press", for: .kettlebellOnly))
        XCTAssertFalse(isExerciseAllowed("Cable Row", for: .kettlebellOnly))
    }

    func testResistanceBandsOnlyAllowsBandAndBodyweightMovements() {
        XCTAssertTrue(isExerciseAllowed("Band Row", for: .resistanceBands))
        XCTAssertTrue(isExerciseAllowed("Band Pull-Apart", for: .resistanceBands))
        XCTAssertTrue(isExerciseAllowed("Push-Up", for: .resistanceBands))
        XCTAssertFalse(isExerciseAllowed("Flat Barbell Bench Press", for: .resistanceBands))
        XCTAssertFalse(isExerciseAllowed("Dumbbell Row", for: .resistanceBands))
        XCTAssertFalse(isExerciseAllowed("Kettlebell Swing", for: .resistanceBands))
    }

    func testBodyweightOnlyRejectsLoadedMovements() {
        XCTAssertTrue(isExerciseAllowed("Push-Up", for: .bodyweightOnly))
        XCTAssertFalse(isExerciseAllowed("Kettlebell Swing", for: .bodyweightOnly))
        XCTAssertFalse(isExerciseAllowed("Dumbbell Row", for: .bodyweightOnly))
    }

    func testValidateGeneratedWorkoutFlagsDisallowedEquipmentAndInvalidSets() {
        let workout = GeneratedWorkout(
            id: "bad",
            createdAt: Date(),
            isFavorite: false,
            coachingSummary: "Bad workout",
            exercises: [
                makeExercise("Flat Barbell Bench Press", sets: 4),
                makeExercise("Kettlebell Swing", sets: 9)
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 30,
                focus: .fullBody,
                energyLevel: .medium,
                equipment: .kettlebellOnly
            )
        )

        let issues = validateGeneratedWorkout(workout)
        XCTAssertTrue(issues.contains(.disallowedEquipment(exerciseName: "Flat Barbell Bench Press", equipment: .kettlebellOnly)))
        XCTAssertTrue(issues.contains(.invalidSets(exerciseName: "Kettlebell Swing", sets: 9)))
    }

    func testRepairGeneratedWorkoutReplacesInvalidWorkoutWithSafeKettlebellTemplate() {
        let workout = GeneratedWorkout(
            id: "repair",
            createdAt: Date(),
            isFavorite: false,
            coachingSummary: "Needs repair",
            exercises: [
                makeExercise("Flat Barbell Bench Press", sets: 9),
                makeExercise("Cable Row", sets: 9)
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 20,
                focus: .fullBody,
                energyLevel: .low,
                equipment: .kettlebellOnly
            )
        )

        let repaired = repairGeneratedWorkout(workout)

        XCTAssertFalse(repaired.exercises.isEmpty)
        XCTAssertTrue(repaired.exercises.allSatisfy { isExerciseAllowed($0.name, for: .kettlebellOnly) })
        XCTAssertTrue(repaired.exercises.allSatisfy { $0.sets <= 3 })
        XCTAssertLessThanOrEqual(totalEstimatedMinutes(repaired.exercises), 25)
    }

    func testRepairGeneratedWorkoutReplacesInvalidWorkoutWithSafeResistanceBandTemplate() {
        let workout = GeneratedWorkout(
            id: "band-repair",
            createdAt: Date(),
            isFavorite: false,
            coachingSummary: "Needs band repair",
            exercises: [
                makeExercise("Flat Barbell Bench Press", sets: 9),
                makeExercise("Kettlebell Swing", sets: 9)
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 20,
                focus: .fullBody,
                energyLevel: .low,
                equipment: .resistanceBands
            )
        )

        let repaired = repairGeneratedWorkout(workout)

        XCTAssertFalse(repaired.exercises.isEmpty)
        XCTAssertTrue(repaired.exercises.allSatisfy { isExerciseAllowed($0.name, for: .resistanceBands) })
        XCTAssertTrue(repaired.exercises.allSatisfy { $0.sets <= 3 })
        XCTAssertLessThanOrEqual(totalEstimatedMinutes(repaired.exercises), 25)
    }

    func testKettlebellLowEnergyPoolAvoidsHighSkillBallisticMovements() {
        let pool = workoutExercisePool(
            focus: .conditioning,
            equipment: .kettlebellOnly,
            energyLevel: .low
        ).map(\.name)

        XCTAssertTrue(pool.contains("Kettlebell Swing"))
        XCTAssertFalse(pool.contains("Kettlebell Snatch"))
        XCTAssertFalse(pool.contains("Turkish Get-Up"))
    }

    func testDeterministicCoachGeneratesValidKettlebellWorkout() async throws {
        let service = DeterministicCoachService()
        let preferences = QuestionnaireAnswers(
            timeMinutes: 30,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .kettlebellOnly
        )

        let response = try await service.generateWorkout(
            context: CoachContext(equipment: .kettlebellOnly),
            preferences: preferences
        )

        XCTAssertFalse(response.workout.exercises.isEmpty)
        XCTAssertTrue(response.workout.exercises.allSatisfy { isExerciseAllowed($0.name, for: .kettlebellOnly) })
        XCTAssertTrue(validateGeneratedWorkout(response.workout).isEmpty)
    }

    func testDeterministicCoachGeneratesValidResistanceBandWorkout() async throws {
        let service = DeterministicCoachService()
        let preferences = QuestionnaireAnswers(
            timeMinutes: 30,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .resistanceBands
        )

        let response = try await service.generateWorkout(
            context: CoachContext(equipment: .resistanceBands),
            preferences: preferences
        )

        XCTAssertFalse(response.workout.exercises.isEmpty)
        XCTAssertTrue(response.workout.exercises.allSatisfy { isExerciseAllowed($0.name, for: .resistanceBands) })
        XCTAssertTrue(validateGeneratedWorkout(response.workout).isEmpty)
    }
}
