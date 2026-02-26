import Testing
import Foundation
@testable import SundeeFundee

// MARK: - WeightCalculations tests

@Suite("WeightCalculations")
struct WeightCalculationsTests {

    @Test func roundToNearestFive() {
        #expect(WeightCalculations.roundToNearestFive(102.0) == 100.0)
        #expect(WeightCalculations.roundToNearestFive(103.0) == 105.0)
        #expect(WeightCalculations.roundToNearestFive(100.0) == 100.0)
        #expect(WeightCalculations.roundToNearestFive(0) == 0)
    }

    @Test func calculateTargetWeight() {
        // 100 kg 1RM at 70% → 70 kg (rounded to nearest 5)
        #expect(WeightCalculations.calculateTargetWeight(oneRepMax: 100, percentage: 0.70) == 70.0)
        // 100 kg 1RM at 85% → 85 kg
        #expect(WeightCalculations.calculateTargetWeight(oneRepMax: 100, percentage: 0.85) == 85.0)
        // 91 kg 1RM at 80% → 75 kg (72.8 rounds to 75)
        #expect(WeightCalculations.calculateTargetWeight(oneRepMax: 91, percentage: 0.80) == 75.0)
    }

    @Test func nextRecommendedWeightSuccess() {
        let next = WeightCalculations.getNextRecommendedWeight(
            currentWeight: 80, result: .success, oneRepMax: 100)
        #expect(next == 85.0)
    }

    @Test func nextRecommendedWeightFailure() {
        let next = WeightCalculations.getNextRecommendedWeight(
            currentWeight: 80, result: .failure, oneRepMax: 100)
        #expect(next == 75.0)
    }

    @Test func nextRecommendedWeightFirst() {
        let next = WeightCalculations.getNextRecommendedWeight(
            currentWeight: 0, result: .first, oneRepMax: 100)
        #expect(next == 70.0)
    }

    @Test func volumeLoad() {
        #expect(WeightCalculations.calculateVolumeLoad(weight: 100, reps: 5, sets: 3) == 1500.0)
    }

    @Test func detectPlateauTrue() {
        #expect(WeightCalculations.detectPlateau(weights: [80, 80, 82]) == true)
    }

    @Test func detectPlateauFalse() {
        #expect(WeightCalculations.detectPlateau(weights: [70, 80, 90]) == false)
    }

    @Test func detectPlateauInsufficientData() {
        #expect(WeightCalculations.detectPlateau(weights: [80, 80]) == false)
    }
}

// MARK: - EpleyFormula tests

@Suite("EpleyFormula")
struct EpleyFormulaTests {

    @Test func singleRepIsMax() {
        #expect(EpleyFormula.estimated1RM(weight: 100, reps: 1) == 100.0)
    }

    @Test func fiveRepEstimate() {
        // 80 kg × 5 reps → 80 × (1 + 5/30) = 80 × 1.1667 ≈ 93.3
        let result = EpleyFormula.estimated1RM(weight: 80, reps: 5)
        #expect(abs(result - 93.33) < 0.1)
    }

    @Test func isPR() {
        #expect(EpleyFormula.isPR(newEstimate: 105, currentMax: 100) == true)
        #expect(EpleyFormula.isPR(newEstimate: 95,  currentMax: 100) == false)
        #expect(EpleyFormula.isPR(newEstimate: 100, currentMax: nil)  == true)
    }
}

// MARK: - PlateCalculation tests

@Suite("PlateCalculation")
struct PlateCalculationTests {

    @Test func emptyForBarOnly() {
        let plates = PlateCalculation.platesPerSide(totalWeightKg: 20, barbellWeightKg: 20)
        #expect(plates.isEmpty)
    }

    @Test func oneHundredKgPlates() {
        // 100 kg total, 20 kg bar → 40 kg on each side
        // Available kg plates: [25, 20, 15, 10, 5, 2.5, 1.25]
        // 40 = 1×25 + 1×15
        let plates = PlateCalculation.platesPerSide(totalWeightKg: 100, barbellWeightKg: 20)
        let dict = Dictionary(uniqueKeysWithValues: plates.map { ($0.weight, $0.count) })
        #expect(dict[25.0] == 1)
        #expect(dict[15.0] == 1)
    }

    @Test func descriptionBarOnly() {
        let desc = PlateCalculation.description(totalWeightKg: 20, barbellWeightKg: 20)
        #expect(desc.contains("Bar only"))
    }
}

// MARK: - CycleCalculations tests

@Suite("CycleCalculations")
struct CycleCalculationsTests {

    private func makeSettings(
        cycleDays: Int = 28,
        periodDays: Int = 5,
        lutealDays: Int = 14
    ) -> CycleSettings {
        CycleSettings(id: "s1", userID: "u1",
                      averageCycleLengthDays: cycleDays,
                      averagePeriodLengthDays: periodDays,
                      lutealPhaseLengthDays: lutealDays)
    }

    private func makePeriodLog(startOffset: Int) -> PeriodLog {
        let start = Calendar.current.date(byAdding: .day, value: startOffset, to: Calendar.current.startOfDay(for: .now))!
        return PeriodLog(id: UUID().uuidString, userID: "u1", startDate: start)
    }

    @Test func returnsNilWithNoPeriodLogs() {
        let result = CycleCalculations.calculateCycleStatus(
            periodLogs: [], settings: makeSettings())
        #expect(result == nil)
    }

    @Test func detectsMenstrualPhase() {
        // Period started today → day 1 → menstrual
        let log = makePeriodLog(startOffset: 0)
        let result = CycleCalculations.calculateCycleStatus(
            periodLogs: [log], settings: makeSettings())
        #expect(result?.currentPhase == .menstrual)
        #expect(result?.cycleDay == 1)
    }

    @Test func detectsFollicularPhase() {
        // Period started 7 days ago → day 8 → follicular (after 5-day period)
        let log = makePeriodLog(startOffset: -7)
        let result = CycleCalculations.calculateCycleStatus(
            periodLogs: [log], settings: makeSettings())
        #expect(result?.currentPhase == .follicular)
    }

    @Test func phaseRecommendationMenstrual() {
        let rec = CycleCalculations.getPhaseRecommendation(.menstrual)
        #expect(rec.intensityRecommendation == "low")
        #expect(!rec.exercisesToAvoid.isEmpty)
    }

    @Test func phaseRecommendationOvulation() {
        let rec = CycleCalculations.getPhaseRecommendation(.ovulation)
        #expect(rec.intensityRecommendation == "peak")
    }
}

// MARK: - CycleAdaptationPolicy tests

@Suite("CycleAdaptationPolicy")
struct CycleAdaptationPolicyTests {

    let policy = CycleAdaptationPolicy()

    @Test func ovulationIncreasesLoad() {
        let ex = ProgramExercise(exercise: "Back Squat", variant: nil,
                                 sets: .fixed(3), reps: .fixed(5),
                                 percent1RM: 0.80, restMinutes: 3, notes: nil)
        let adapted = policy.applyPhaseAdjustment(
            exercise: ex, phase: .ovulation,
            readinessTier: .neutral, confidence: .high, profile: nil)
        // Ovulation load multiplier is 1.12 — percent1RM should increase
        #expect((adapted.percent1RM ?? 0) > 0.80)
    }

    @Test func menstrualReducesLoad() {
        let ex = ProgramExercise(exercise: "Back Squat", variant: nil,
                                 sets: .fixed(3), reps: .fixed(5),
                                 percent1RM: 0.80, restMinutes: 3, notes: nil)
        let adapted = policy.applyPhaseAdjustment(
            exercise: ex, phase: .menstrual,
            readinessTier: .neutral, confidence: .high, profile: nil)
        #expect((adapted.percent1RM ?? 1) < 0.80)
    }

    @Test func lowConfidenceBluntsEffect() {
        let ex = ProgramExercise(exercise: "Squat", variant: nil,
                                 sets: .fixed(3), reps: .fixed(5),
                                 percent1RM: 0.80, restMinutes: 3, notes: nil)
        let highConf = policy.applyPhaseAdjustment(
            exercise: ex, phase: .ovulation,
            readinessTier: .neutral, confidence: .high, profile: nil)
        let lowConf = policy.applyPhaseAdjustment(
            exercise: ex, phase: .ovulation,
            readinessTier: .neutral, confidence: .low, profile: nil)
        // Low confidence should produce smaller ovulation boost
        #expect((highConf.percent1RM ?? 0) > (lowConf.percent1RM ?? 0))
    }
}

// MARK: - InjuryAdaptationEngine tests

@Suite("InjuryAdaptationEngine")
struct InjuryAdaptationEngineTests {

    private func makeInjury(location: String) -> InjuryProfile {
        InjuryProfile(id: UUID().uuidString, userID: "u1", location: location)
    }

    @Test func romanianDeadliftReplacedForBackInjury() {
        let program = makeSingleExerciseProgram("Romanian Deadlift")
        let adapted = InjuryAdaptationEngine.adaptProgram(program, activeInjuries: [makeInjury(location: "back")])
        let exercise = adapted.weeks.first?.sessions.first?.exercises.first?.exercise ?? ""
        // Should be replaced with a back-safe alternative
        #expect(exercise != "Romanian Deadlift")
    }

    @Test func walkingLungesReplacedForKneeInjury() {
        let program = makeSingleExerciseProgram("Walking Lunges")
        let adapted = InjuryAdaptationEngine.adaptProgram(program, activeInjuries: [makeInjury(location: "knee")])
        let exercise = adapted.weeks.first?.sessions.first?.exercises.first?.exercise ?? ""
        #expect(exercise != "Walking Lunges")
    }

    @Test func noInjuryReturnsUnchanged() {
        let program = makeSingleExerciseProgram("Back Squat")
        let adapted = InjuryAdaptationEngine.adaptProgram(program, activeInjuries: [])
        let exercise = adapted.weeks.first?.sessions.first?.exercises.first?.exercise ?? ""
        #expect(exercise == "Back Squat")
    }

    @Test func recoveryPrepBlockKneeHasExercises() {
        let block = InjuryAdaptationEngine.buildRecoveryPrepBlock(injuries: [makeInjury(location: "knee")])
        #expect(!block.isEmpty)
    }

    @Test func recoveryPrepBlockHipHasExercises() {
        let block = InjuryAdaptationEngine.buildRecoveryPrepBlock(injuries: [makeInjury(location: "hip")])
        #expect(block.count >= 2)
    }

    @Test func recoveryPrepBlockCombinesMultipleInjuries() {
        let knee = makeInjury(location: "knee")
        let shoulder = makeInjury(location: "shoulder")
        let block = InjuryAdaptationEngine.buildRecoveryPrepBlock(injuries: [knee, shoulder])
        // Should include exercises for both locations, de-duplicated
        #expect(block.count >= 3)
    }

    // MARK: - Helper

    private func makeSingleExerciseProgram(_ exerciseName: String) -> Program {
        let ex = ProgramExercise(exercise: exerciseName, variant: nil,
                                  sets: .fixed(3), reps: .fixed(5),
                                  percent1RM: 0.80, restMinutes: 3, notes: nil)
        let session = ProgramSession(sessionID: "s1", sessionName: "Day 1",
                                     sessionType: "strength", focus: "Lower",
                                     exercises: [ex])
        let week = ProgramWeek(week: 1, phaseID: nil, isTestWeek: nil, sessions: [session])
        return Program(id: "p1", name: "Test", category: "Test",
                       description: "", durationWeeks: 1, sessionsPerWeek: 1,
                       difficulty: "beginner", phases: [], weeks: [week],
                       cycleAdjustmentProfile: nil)
    }
}

// MARK: - WeightliftingExerciseCatalog tests

@Suite("WeightliftingExerciseCatalog")
struct WeightliftingExerciseCatalogTests {

    @Test func backSquatIsWeightlifting() {
        #expect(WeightliftingExerciseCatalog.isWeightliftingExercise("Back Squat") == true)
    }

    @Test func calfRaiseIsNotWeightlifting() {
        #expect(WeightliftingExerciseCatalog.isWeightliftingExercise("Calf Raise") == false)
    }

    @Test func legPressIsNotWeightlifting() {
        #expect(WeightliftingExerciseCatalog.isWeightliftingExercise("Leg Press") == false)
    }

    @Test func walkingLungesIsNotWeightlifting() {
        #expect(WeightliftingExerciseCatalog.isWeightliftingExercise("Walking Lunges") == false)
    }

    @Test func romanianDeadliftIsWeightlifting() {
        #expect(WeightliftingExerciseCatalog.isWeightliftingExercise("Romanian Deadlift") == true)
    }

    @Test func catalogIsNonEmpty() {
        #expect(WeightliftingExerciseCatalog.all.isEmpty == false)
    }

    @Test func sortedByCategoryOrdering() {
        let sorted = WeightliftingExerciseCatalog.sortedByCategory
        // Squats come before hinges in category order
        let squatIdx = sorted.firstIndex { $0.category == .squat }
        let hingeIdx = sorted.firstIndex { $0.category == .hinge }
        if let s = squatIdx, let h = hingeIdx { #expect(s < h) }
    }
}
