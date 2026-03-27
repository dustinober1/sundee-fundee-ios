import XCTest
@testable import SundeeFundee

final class WorkoutPostProcessorTests: XCTestCase {

    // MARK: - Helpers

    private func makeRawOutput(exercises: [AIExerciseOutput] = [
        AIExerciseOutput(name: "Barbell Back Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil),
        AIExerciseOutput(name: "Push-Up", sets: 3, reps: 12, bodyweightOnly: true, notes: nil)
    ], coachingSummary: String = "Great workout ahead!") -> AIWorkoutOutput {
        AIWorkoutOutput(coachingSummary: coachingSummary, exercises: exercises)
    }

    private func makeContext(
        maxes: [ExerciseMax] = [],
        energyLevel: EnergyLevel = .medium,
        cyclePhase: String? = nil,
        readinessTier: String? = nil,
        focus: WorkoutFocus = .fullBody,
        timeMinutes: Int = 45,
        equipment: EquipmentAccess = .fullGym,
        activeInjuries: [InjurySummary] = []
    ) -> WorkoutGenerationContext {
        WorkoutGenerationContext(
            userID: "test-user",
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment,
            maxes: maxes,
            recentWorkouts: [],
            cyclePhase: cyclePhase,
            readinessTier: readinessTier,
            activeInjuries: activeInjuries,
            experienceLevel: "intermediate",
            primaryGoal: "strength",
            gender: "female",
            weightUnit: "kg"
        )
    }

    // MARK: - Weight Calculation

    func testWeightAppliedFromMaxes() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Barbell Back Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil)
        ])
        let context = makeContext(maxes: [ExerciseMax(name: "Barbell Back Squat", weightKg: 100)])
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.exercises.first?.weightKg, 80.0)
    }

    func testNoMaxesMeansNilWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Barbell Back Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil)
        ])
        let context = makeContext(maxes: [])
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertNil(result.exercises.first?.weightKg)
    }

    func testBodyweightExerciseGetsNilWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Push-Up", sets: 3, reps: 12, bodyweightOnly: true, notes: nil)
        ])
        let context = makeContext(maxes: [ExerciseMax(name: "Push-Up", weightKg: 50)])
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertNil(result.exercises.first?.weightKg)
    }

    func testFuzzyNameMatching() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Bench Press", sets: 4, reps: 8, bodyweightOnly: false, notes: nil)
        ])
        let context = makeContext(maxes: [ExerciseMax(name: "Flat Barbell Bench Press", weightKg: 100)])
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.exercises.first?.weightKg, 70.0)
    }

    func testDefaultPercentageForVariousRepRanges() {
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "3"), 0.85)
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "5"), 0.80)
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "8-10"), 0.70)
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "12-15"), 0.65)  // "12" parsed → case 9...12
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "15"), 0.60)
        XCTAssertEqual(WorkoutPostProcessor.defaultPercentage(for: "AMRAP"), 0.65)  // "AMRAP" → Int fails → default 10 → case 9...12
    }

    // MARK: - Rest Periods

    func testRestPeriodsAssignedByRepRange() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Curl", sets: 3, reps: 12, bodyweightOnly: false, notes: nil)
        ])
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.exercises[0].restMinutes, 2.5)
        XCTAssertEqual(result.exercises[1].restMinutes, 1.5)
    }

    func testBodyweightRestPeriod() {
        XCTAssertEqual(WorkoutPostProcessor.assignRestMinutes(reps: "10", bodyweight: true), 1.0)
    }

    // MARK: - Energy Level

    func testLowEnergyReducesWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil)
        ])
        let mediumContext = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], energyLevel: .medium)
        let lowContext = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], energyLevel: .low)
        let mediumResult = WorkoutPostProcessor.process(raw: raw, context: mediumContext)
        let lowResult = WorkoutPostProcessor.process(raw: raw, context: lowContext)
        XCTAssertLessThan(lowResult.exercises.first!.weightKg!, mediumResult.exercises.first!.weightKg!)
    }

    func testHighEnergyIncreasesWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil)
        ])
        let mediumContext = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], energyLevel: .medium)
        let highContext = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], energyLevel: .high)
        let mediumResult = WorkoutPostProcessor.process(raw: raw, context: mediumContext)
        let highResult = WorkoutPostProcessor.process(raw: raw, context: highContext)
        XCTAssertGreaterThan(highResult.exercises.first!.weightKg!, mediumResult.exercises.first!.weightKg!)
    }

    func testEnergyMultiplierValues() {
        XCTAssertEqual(WorkoutPostProcessor.applyEnergyMultiplier(100, energy: .low), 85.0)
        XCTAssertEqual(WorkoutPostProcessor.applyEnergyMultiplier(100, energy: .medium), 100.0)
        XCTAssertEqual(WorkoutPostProcessor.applyEnergyMultiplier(100, energy: .high), 105.0)
    }

    // MARK: - Cycle Phase

    func testMenstrualPhaseReducesWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil)
        ])
        let baseline = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: "follicular")
        let menstrual = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: "menstrual")
        let baseResult = WorkoutPostProcessor.process(raw: raw, context: baseline)
        let menstrualResult = WorkoutPostProcessor.process(raw: raw, context: menstrual)
        XCTAssertLessThan(menstrualResult.exercises.first!.weightKg!, baseResult.exercises.first!.weightKg!)
    }

    func testOvulationPhaseIncreasesWeight() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil)
        ])
        let baseline = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: "follicular")
        let ovulation = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: "ovulation")
        let baseResult = WorkoutPostProcessor.process(raw: raw, context: baseline)
        let ovulationResult = WorkoutPostProcessor.process(raw: raw, context: ovulation)
        XCTAssertGreaterThan(ovulationResult.exercises.first!.weightKg!, baseResult.exercises.first!.weightKg!)
    }

    func testNilCyclePhaseAppliesNoAdjustment() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil)
        ])
        let baseline = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: "follicular")
        let noCycle = makeContext(maxes: [ExerciseMax(name: "Squat", weightKg: 100)], cyclePhase: nil)
        let baseResult = WorkoutPostProcessor.process(raw: raw, context: baseline)
        let noCycleResult = WorkoutPostProcessor.process(raw: raw, context: noCycle)
        XCTAssertEqual(noCycleResult.exercises.first!.weightKg!, baseResult.exercises.first!.weightKg!)
    }

    func testCyclePhaseMultiplierValues() {
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "menstrual", readiness: nil), 90.0, accuracy: 0.01)
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "follicular", readiness: nil), 100.0, accuracy: 0.01)
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "ovulation", readiness: nil), 112.0, accuracy: 0.01)
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "luteal", readiness: nil), 97.0, accuracy: 0.01)
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: nil, readiness: nil), 100.0, accuracy: 0.01)
    }

    func testReadinessMultiplier() {
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "follicular", readiness: "low"), 85.0, accuracy: 0.01)
        XCTAssertEqual(WorkoutPostProcessor.applyCyclePhaseMultiplier(100, phase: "follicular", readiness: "high"), 110.0, accuracy: 0.01)
    }

    // MARK: - Coaching Summary

    func testCoachingSummaryEnrichedWithMenstrualPhase() {
        let raw = makeRawOutput()
        let context = makeContext(cyclePhase: "menstrual")
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertTrue(result.coachingSummary.lowercased().contains("menstrual"))
    }

    func testCoachingSummaryIncludesLowEnergyNote() {
        let raw = makeRawOutput()
        let context = makeContext(energyLevel: .low)
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertTrue(result.coachingSummary.contains("low energy"))
    }

    func testCoachingSummaryIncludesHighEnergyNote() {
        let raw = makeRawOutput()
        let context = makeContext(energyLevel: .high)
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertTrue(result.coachingSummary.contains("high energy"))
    }

    func testCoachingSummaryMediumEnergyNoNote() {
        let raw = makeRawOutput(coachingSummary: "Base note.")
        let context = makeContext(energyLevel: .medium)
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.coachingSummary, "Base note.")
    }

    func testCoachingSummaryFollicularPhaseNoNote() {
        let raw = makeRawOutput(coachingSummary: "Base note.")
        let context = makeContext(energyLevel: .medium, cyclePhase: "follicular")
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.coachingSummary, "Base note.")
    }

    func testCoachingSummaryNilPhaseNoNote() {
        let raw = makeRawOutput(coachingSummary: "Base note.")
        let context = makeContext(energyLevel: .medium, cyclePhase: nil)
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.coachingSummary, "Base note.")
    }

    // MARK: - Output Mapping

    func testOutputMapsToGeneratedWorkout() {
        let raw = makeRawOutput()
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.exercises.count, 2)
        XCTAssertFalse(result.id.isEmpty)
        XCTAssertEqual(result.questionnaire.focus, .fullBody)
        XCTAssertEqual(result.questionnaire.timeMinutes, 45)
        XCTAssertEqual(result.isFavorite, false)
    }

    func testEachExerciseGetsUniqueID() {
        let raw = makeRawOutput()
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        let ids = result.exercises.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testExerciseNotesPassedThrough() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Squat", sets: 3, reps: 5, bodyweightOnly: false, notes: "Keep chest up")
        ])
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.exercises.first?.notes, "Keep chest up")
    }

    func testReasoningIsAlwaysNil() {
        let raw = makeRawOutput()
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertTrue(result.exercises.allSatisfy { $0.reasoning == nil })
    }

    // MARK: - Equipment Filtering

    func testBodyweightOnlyFilterRemovesBarbellExercises() {
        let exercises = [
            AIExerciseOutput(name: "Barbell Back Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Push-Up", sets: 3, reps: 12, bodyweightOnly: true, notes: nil),
            AIExerciseOutput(name: "Deadlift", sets: 4, reps: 5, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Plank Hold", sets: 3, reps: 0, bodyweightOnly: true, notes: nil)
        ]
        let filtered = WorkoutPostProcessor.filterForEquipment(exercises, equipment: .bodyweightOnly)
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.bodyweightOnly || !$0.name.lowercased().contains("barbell") })
    }

    func testBodyweightOnlyFilterRemovesDumbbellExercises() {
        let exercises = [
            AIExerciseOutput(name: "Dumbbell Bench Press", sets: 3, reps: 8, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Burpees", sets: 4, reps: 10, bodyweightOnly: true, notes: nil)
        ]
        let filtered = WorkoutPostProcessor.filterForEquipment(exercises, equipment: .bodyweightOnly)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Burpees")
    }

    func testHomeDumbbellsFilterRemovesBarbellAndMachineExercises() {
        let exercises = [
            AIExerciseOutput(name: "Barbell Back Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Dumbbell Row", sets: 3, reps: 10, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Leg Press", sets: 3, reps: 12, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Push-Up", sets: 3, reps: 15, bodyweightOnly: true, notes: nil)
        ]
        let filtered = WorkoutPostProcessor.filterForEquipment(exercises, equipment: .homeDumbbells)
        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered.map(\.name), ["Dumbbell Row", "Push-Up"])
    }

    func testFullGymFilterKeepsAllExercises() {
        let exercises = [
            AIExerciseOutput(name: "Barbell Back Squat", sets: 4, reps: 5, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Cable Fly", sets: 3, reps: 12, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Push-Up", sets: 3, reps: 15, bodyweightOnly: true, notes: nil)
        ]
        let filtered = WorkoutPostProcessor.filterForEquipment(exercises, equipment: .fullGym)
        XCTAssertEqual(filtered.count, 3)
    }

    func testOutdoorFilterMatchesBodyweightOnly() {
        let exercises = [
            AIExerciseOutput(name: "Deadlift", sets: 4, reps: 5, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Burpees", sets: 4, reps: 10, bodyweightOnly: true, notes: nil)
        ]
        let filtered = WorkoutPostProcessor.filterForEquipment(exercises, equipment: .outdoor)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Burpees")
    }

    func testProcessWithBodyweightFilterRemovesWeightedExercises() {
        let raw = makeRawOutput(exercises: [
            AIExerciseOutput(name: "Deadlift", sets: 4, reps: 5, bodyweightOnly: false, notes: nil),
            AIExerciseOutput(name: "Push-Up", sets: 3, reps: 12, bodyweightOnly: true, notes: nil)
        ])
        let context = makeContext(equipment: .bodyweightOnly)
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertEqual(result.exercises.count, 1)
        XCTAssertEqual(result.exercises.first?.name, "Push-Up")
    }

    // MARK: - Edge Cases

    func testEmptyExercisesArrayProducesEmptyWorkout() {
        let raw = makeRawOutput(exercises: [])
        let context = makeContext()
        let result = WorkoutPostProcessor.process(raw: raw, context: context)
        XCTAssertTrue(result.exercises.isEmpty)
    }
}
