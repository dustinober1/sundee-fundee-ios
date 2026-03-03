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
        #expect(WeightCalculations.detectPlateau(weights: [80]) == false)
        #expect(WeightCalculations.detectPlateau(weights: []) == false)
    }

    @Test func detectPlateauExactly5() {
        #expect(WeightCalculations.detectPlateau(weights: [100, 102, 105]) == false)
    }

    @Test func detectPlateauMoreThan3Elements() {
        #expect(WeightCalculations.detectPlateau(weights: [50, 60, 100, 102, 104]) == true)
        #expect(WeightCalculations.detectPlateau(weights: [100, 100, 100, 105, 110]) == false)
    }

    @Test func detectPlateauNegativeOrZeroWeights() {
        #expect(WeightCalculations.detectPlateau(weights: [0, 0, 0]) == true)
        #expect(WeightCalculations.detectPlateau(weights: [-10, -8, -6]) == true)
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

// MARK: - WeightUnitConversion tests

@Suite("WeightUnitConversion")
struct WeightUnitConversionTests {

    @Test func convertsKgToLbAndBack() {
        let pounds = WeightUnitConversion.value(fromKilograms: 100, unit: .pounds)
        #expect(abs(pounds - 220.46) < 0.01)

        let kilograms = WeightUnitConversion.kilograms(from: pounds, unit: .pounds)
        #expect(abs(kilograms - 100) < 0.001)
    }

    @Test func parsesUserInputToKilograms() {
        #expect(WeightUnitConversion.parseInputToKilograms("100", unit: .kilograms) == 100)
        let fromPounds = WeightUnitConversion.parseInputToKilograms("225", unit: .pounds)
        #expect(abs((fromPounds ?? 0) - 102.06) < 0.01)
        #expect(WeightUnitConversion.parseInputToKilograms("bad", unit: .pounds) == nil)
    }

    @Test func formatsWithUnitSuffix() {
        #expect(WeightUnitConversion.formatWithUnit(kilograms: 80, unit: .kilograms).hasSuffix("kg"))
        #expect(WeightUnitConversion.formatWithUnit(kilograms: 80, unit: .pounds).hasSuffix("lb"))
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
        let program = makeSingleExerciseProgram("Romanian Deadlift (No Straps)")
        let adapted = InjuryAdaptationEngine.adaptProgram(program, activeInjuries: [makeInjury(location: "back")])
        let exercise = adapted.weeks.first?.sessions.first?.exercises.first?.exercise ?? ""
        // Should be replaced with a back-safe alternative
        #expect(exercise != "Romanian Deadlift (No Straps)")
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

    @Test func sqautCleanReplacedForShoulderInjury() {
        let program = makeSingleExerciseProgram("Squat Clean")
        let adapted = InjuryAdaptationEngine.adaptProgram(program, activeInjuries: [makeInjury(location: "shoulder")])
        let exercise = adapted.weeks.first?.sessions.first?.exercises.first?.exercise ?? ""
        #expect(exercise != "Squat Clean")
    }

    @Test func cleanAndJerkReplacedForWristInjury() {
        let program = makeSingleExerciseProgram("Clean and Jerk")
        let adapted = InjuryAdaptationEngine.adaptProgram(program, activeInjuries: [makeInjury(location: "wrist")])
        let exercise = adapted.weeks.first?.sessions.first?.exercises.first?.exercise ?? ""
        #expect(exercise != "Clean and Jerk")
    }

    @Test func recoveryPrepBlockWristHasExercises() {
        let block = InjuryAdaptationEngine.buildRecoveryPrepBlock(injuries: [makeInjury(location: "wrist")])
        #expect(!block.isEmpty)
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
        #expect(WeightliftingExerciseCatalog.isWeightliftingExercise("Plated Calf Step Up") == false)
    }

    @Test func wallBallThrustersIsNotWeightlifting() {
        #expect(WeightliftingExerciseCatalog.isWeightliftingExercise("Wall Ball Thrusters") == false)
    }

    @Test func walkingLungesIsNotWeightlifting() {
        #expect(WeightliftingExerciseCatalog.isWeightliftingExercise("Walking Lunges") == false)
    }

    @Test func romanianDeadliftIsWeightlifting() {
        #expect(WeightliftingExerciseCatalog.isWeightliftingExercise("Romanian Deadlift (No Straps)") == true)
    }

    @Test func cleanAndJerkIsWeightlifting() {
        #expect(WeightliftingExerciseCatalog.isWeightliftingExercise("Clean and Jerk") == true)
    }

    @Test func olympicCategoryExists() {
        let olympicEntries = WeightliftingExerciseCatalog.all.filter { $0.category == .olympic }
        #expect(olympicEntries.count == 9)
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

// MARK: - CelebrationEvent subtitle tests

@Suite("CelebrationEvent.subtitle")
struct CelebrationEventSubtitleTests {

    @Test func workoutCompletedSubtitleShowsDuration() {
        let event = CelebrationEvent.workoutCompleted(durationSeconds: 3600)
        let subtitle = event.subtitle(unit: .kilograms)
        #expect(subtitle.contains("60 min"))
    }

    @Test func workoutCompletedSubtitleZeroDuration() {
        let event = CelebrationEvent.workoutCompleted(durationSeconds: 0)
        let subtitle = event.subtitle(unit: .pounds)
        #expect(subtitle.contains("saved"))
    }

    @Test func newPersonalRecordSubtitleUsesKilograms() {
        let event = CelebrationEvent.newPersonalRecord(exerciseName: "Back Squat", weightKg: 100)
        let subtitle = event.subtitle(unit: .kilograms)
        #expect(subtitle.contains("Back Squat"))
        #expect(subtitle.contains("kg"))
        #expect(!subtitle.contains("lb"))
    }

    @Test func newPersonalRecordSubtitleUsesPounds() {
        let event = CelebrationEvent.newPersonalRecord(exerciseName: "Deadlift", weightKg: 100)
        let subtitle = event.subtitle(unit: .pounds)
        #expect(subtitle.contains("Deadlift"))
        #expect(subtitle.contains("lb"))
        #expect(!subtitle.contains("kg"))
    }

    @Test func programCompletedSubtitleIsUnitIndependent() {
        let event = CelebrationEvent.programCompleted(programName: "5/3/1")
        #expect(event.subtitle(unit: .kilograms) == event.subtitle(unit: .pounds))
        #expect(event.subtitle(unit: .kilograms).contains("5/3/1"))
    }

    @Test func weightMilestoneSubtitleUsesKilograms() {
        let event = CelebrationEvent.weightMilestone(exerciseName: "Bench Press", thresholdKg: 100)
        let subtitle = event.subtitle(unit: .kilograms)
        #expect(subtitle.contains("Bench Press"))
        #expect(subtitle.contains("kg"))
        #expect(!subtitle.contains("lb"))
    }

    @Test func weightMilestoneSubtitleUsesPounds() {
        let event = CelebrationEvent.weightMilestone(exerciseName: "Bench Press", thresholdKg: 100)
        let subtitle = event.subtitle(unit: .pounds)
        #expect(subtitle.contains("Bench Press"))
        #expect(subtitle.contains("lb"))
        #expect(!subtitle.contains("kg"))
    }

    @Test func defaultSubtitlePropertyUsesKilograms() {
        let event = CelebrationEvent.newPersonalRecord(exerciseName: "Squat", weightKg: 80)
        #expect(event.subtitle == event.subtitle(unit: .kilograms))
    }
}

// MARK: - DashboardViewModel barbell weight tests

@Suite("DashboardViewModel.barbellWeight")
@MainActor
struct DashboardViewModelBarbellWeightTests {

    @Test func femaleBarbellWeightIs15() {
        let weight = DashboardViewModel.barbellWeight(for: .female)
        #expect(weight == 15.0)
    }

    @Test func maleBarbellWeightIs20() {
        let weight = DashboardViewModel.barbellWeight(for: .male)
        #expect(weight == 20.0)
    }

    @Test func preferNotToSayBarbellWeightIs20() {
        let weight = DashboardViewModel.barbellWeight(for: .preferNotToSay)
        #expect(weight == 20.0)
    }

    @Test func nilGenderBarbellWeightIs20() {
        let weight = DashboardViewModel.barbellWeight(for: nil)
        #expect(weight == 20.0)
    }
}

// MARK: - ConditioningScoringType tests

@Suite("ConditioningScoringType")
struct ConditioningScoringTypeTests {

    @Test func rawValues() {
        #expect(ConditioningScoringType.time.rawValue == "time")
        #expect(ConditioningScoringType.reps.rawValue == "reps")
    }

    @Test func isBetterThanTimeNilExisting() {
        #expect(ConditioningScoringType.time.isBetterThan(newValue: 90, existingValue: nil) == true)
    }

    @Test func isBetterThanTimeLowerWins() {
        #expect(ConditioningScoringType.time.isBetterThan(newValue: 80, existingValue: 90) == true)
        #expect(ConditioningScoringType.time.isBetterThan(newValue: 100, existingValue: 90) == false)
    }

    @Test func isBetterThanRepsNilExisting() {
        #expect(ConditioningScoringType.reps.isBetterThan(newValue: 50, existingValue: nil) == true)
    }

    @Test func isBetterThanRepsHigherWins() {
        #expect(ConditioningScoringType.reps.isBetterThan(newValue: 100, existingValue: 90) == true)
        #expect(ConditioningScoringType.reps.isBetterThan(newValue: 80, existingValue: 90) == false)
    }

    @Test func formatValueTime() {
        #expect(ConditioningScoringType.time.formatValue(90) == "1:30")
        #expect(ConditioningScoringType.time.formatValue(45) == "0:45")
        #expect(ConditioningScoringType.time.formatValue(3600) == "60:00")
    }

    @Test func formatValueReps() {
        #expect(ConditioningScoringType.reps.formatValue(100) == "100 reps")
        #expect(ConditioningScoringType.reps.formatValue(1) == "1 rep")
    }
}

// MARK: - ConditioningExerciseCatalog tests

@Suite("ConditioningExerciseCatalog")
struct ConditioningExerciseCatalogTests {

    @Test func wallBallIsConditioning() {
        #expect(ConditioningExerciseCatalog.isConditioningExercise("Wall Ball") == true)
    }

    @Test func backSquatIsNotConditioning() {
        #expect(ConditioningExerciseCatalog.isConditioningExercise("Back Squat") == false)
    }

    @Test func scoringTypeForRepsExercise() {
        #expect(ConditioningExerciseCatalog.scoringType(for: "Burpee") == .reps)
    }

    @Test func scoringTypeForTimeExercise() {
        #expect(ConditioningExerciseCatalog.scoringType(for: "400m Run") == .time)
    }

    @Test func scoringTypeForUnknownExercise() {
        #expect(ConditioningExerciseCatalog.scoringType(for: "Unknown") == nil)
    }

    @Test func catalogIsNonEmpty() {
        #expect(ConditioningExerciseCatalog.all.isEmpty == false)
    }
}

// MARK: - CelebrationEvent conditioning PR tests

@Suite("CelebrationEvent.conditioningPR")
struct CelebrationEventConditioningPRTests {

    @Test func conditioningPR_title() {
        let event = CelebrationEvent.newConditioningPR(exerciseName: "Wall Ball", value: 100, scoringType: .reps)
        #expect(event.title == "New Conditioning PR!")
    }

    @Test func conditioningPR_subtitle_reps() {
        let event = CelebrationEvent.newConditioningPR(exerciseName: "Wall Ball", value: 100, scoringType: .reps)
        #expect(event.subtitle == "Wall Ball — 100 reps")
    }

    @Test func conditioningPR_subtitle_time() {
        let event = CelebrationEvent.newConditioningPR(exerciseName: "1-Mile Run", value: 390, scoringType: .time)
        #expect(event.subtitle == "1-Mile Run — 6:30")
    }

    @Test func conditioningPR_subtitle_unitIndependent() {
        let event = CelebrationEvent.newConditioningPR(exerciseName: "Burpee", value: 50, scoringType: .reps)
        #expect(event.subtitle(unit: .kilograms) == event.subtitle(unit: .pounds))
    }
}

// MARK: - CompletedSet conditioning fields tests

@Suite("CompletedSet.conditioningFields")
struct CompletedSetConditioningFieldsTests {

    @Test func defaultNil() {
        let set = CompletedSet(id: "1", userID: "u", workoutID: "w", exerciseName: "Squat", setIndex: 0, prescribedReps: "5")
        #expect(set.actualTimeSeconds == nil)
        #expect(set.scoringTypeRaw == nil)
    }

    @Test func canBeSet() {
        let set = CompletedSet(id: "1", userID: "u", workoutID: "w", exerciseName: "Wall Ball", setIndex: 0, prescribedReps: "100", actualTimeSeconds: 180, scoringTypeRaw: "time")
        #expect(set.actualTimeSeconds == 180)
        #expect(set.scoringTypeRaw == "time")
    }
}
