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
        #expect(WeightCalculations.detectPlateau(weights: []) == false)
        #expect(WeightCalculations.detectPlateau(weights: [80]) == false)
        #expect(WeightCalculations.detectPlateau(weights: [80, 80]) == false)
    }

    @Test func detectPlateauExactlyFiveDifference() {
        // Difference is exactly 5.0 (not less than 5)
        #expect(WeightCalculations.detectPlateau(weights: [80, 80, 85]) == false)
        #expect(WeightCalculations.detectPlateau(weights: [85, 80, 85]) == false)
    }

    @Test func detectPlateauNegativeWeights() {
        // Handled cleanly despite negative values (if they somehow exist)
        #expect(WeightCalculations.detectPlateau(weights: [-10, -10, -12]) == true)
        #expect(WeightCalculations.detectPlateau(weights: [-10, -15, -20]) == false)
    }

    @Test func detectPlateauLargeArrays() {
        // Only checks the last 3 elements
        #expect(WeightCalculations.detectPlateau(weights: [100, 110, 120, 130, 80, 80, 82]) == true)
        #expect(WeightCalculations.detectPlateau(weights: [80, 80, 82, 100, 110, 120, 130]) == false)
    }

    @Test func detectPlateauDecimalDifferences() {
        #expect(WeightCalculations.detectPlateau(weights: [100.0, 102.5, 104.9]) == true)
        #expect(WeightCalculations.detectPlateau(weights: [100.0, 102.5, 105.0]) == false)
    }

    @Test func detectPlateauAllIdenticalWeights() {
        #expect(WeightCalculations.detectPlateau(weights: [50, 50, 50]) == true)
    }

    @Test func detectPlateauAscendingWeights() {
        #expect(WeightCalculations.detectPlateau(weights: [100, 102, 104]) == true)
        #expect(WeightCalculations.detectPlateau(weights: [100, 103, 106]) == false)
    }

    @Test func detectPlateauShortArrays() {
        // Less than 3 elements should return false
        #expect(WeightCalculations.detectPlateau(weights: []) == false)
        #expect(WeightCalculations.detectPlateau(weights: [100]) == false)
        #expect(WeightCalculations.detectPlateau(weights: [100, 100]) == false)
    }

    @Test func detectPlateauLongArrays() {
        // Only the last 3 elements are evaluated
        #expect(WeightCalculations.detectPlateau(weights: [50, 60, 100, 100, 100]) == true)
        #expect(WeightCalculations.detectPlateau(weights: [100, 100, 100, 100, 105, 110]) == false)
    }

    // MARK: - Barbell snapping

    @Test func snapBarbellWeightSnapsToFiveLbIncrements() {
        // 226.9 lb → should snap to 225 lb (men's bar)
        let snapped = WeightCalculations.snapBarbellWeightLb(226.9, barLb: 45.0)
        #expect(abs(snapped - 225.0) < 0.1)
    }

    @Test func snapBarbellWeightPreservesExactLoadableValues() {
        // 225 lb is exactly loadable (bar + 2×45 per side)
        let snapped225 = WeightCalculations.snapBarbellWeightLb(225.0, barLb: 45.0)
        #expect(abs(snapped225 - 225.0) < 0.1)

        // 135 lb is exactly loadable
        let snapped135 = WeightCalculations.snapBarbellWeightLb(135.0, barLb: 45.0)
        #expect(abs(snapped135 - 135.0) < 0.1)
    }

    @Test func snapBarbellWeightWomenBar() {
        // Women's bar is 35 lb; 100 lb total → 65 lb of plates → snaps to 100 lb
        let snapped = WeightCalculations.snapBarbellWeightLb(100.0, barLb: 35.0)
        #expect(abs(snapped - 100.0) < 0.1)
    }

    // MARK: - Dumbbell snapping

    @Test func snapDumbbellWeightToAvailableValues() {
        // 27 lb → nearest available is 25 lb
        let snapped27 = WeightCalculations.snapDumbbellWeightLb(27.0)
        #expect(snapped27 == 25)

        // 17 lb → nearest available is 15 lb
        let snapped17 = WeightCalculations.snapDumbbellWeightLb(17.0)
        #expect(snapped17 == 15)

        // 45 lb → nearest available is 40 lb or 50 lb
        let snapped45 = WeightCalculations.snapDumbbellWeightLb(45.0)
        #expect(snapped45 == 40 || snapped45 == 50)
    }

    @Test func snapDumbbellWeightPreservesAvailableValues() {
        // Each available dumbbell weight should snap to itself
        for lbWeight in WeightCalculations.availableDumbbellWeightsLb {
            let snapped = WeightCalculations.snapDumbbellWeightLb(lbWeight)
            #expect(snapped == lbWeight)
        }
    }

    // MARK: - Kettlebell snapping

    @Test func snapKettlebellWeightToAvailableValues() {
        // 28 lb → nearest available is 25 lb
        let snapped28 = WeightCalculations.snapKettlebellWeightLb(28.0)
        #expect(snapped28 == 25)

        // 40 lb → nearest available is 32 lb or 53 lb
        let snapped40 = WeightCalculations.snapKettlebellWeightLb(40.0)
        #expect(snapped40 == 32 || snapped40 == 53)

        // 65 lb → nearest available is 70 lb
        let snapped65 = WeightCalculations.snapKettlebellWeightLb(65.0)
        #expect(snapped65 == 70)
    }

    @Test func snapKettlebellWeightPreservesAvailableValues() {
        for lbWeight in WeightCalculations.availableKettlebellWeightsLb {
            let snapped = WeightCalculations.snapKettlebellWeightLb(lbWeight)
            #expect(snapped == lbWeight)
        }
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
        // Use kg path: totalWeightKg == barbellWeightKg → no plates
        let barKg = PlateCalculation.standardBarKg
        let plates = PlateCalculation.platesPerSideKg(totalWeightKg: barKg, barbellWeightKg: barKg)
        #expect(plates.isEmpty)
    }

    @Test func emptyForLighterThanBar() {
        // Weight less than the bar → no plates
        let barKg = PlateCalculation.standardBarKg
        let plates = PlateCalculation.platesPerSideKg(totalWeightKg: barKg - 5, barbellWeightKg: barKg)
        #expect(plates.isEmpty)
    }

    @Test func lbPlatesForLbUnit() {
        // 225 lb total, 45 lb bar → 90 lb per side → 2×45
        let totalKg = 225.0 / 2.2046226218
        let barKg = PlateCalculation.standardBarKg
        let plates = PlateCalculation.platesPerSide(totalWeightKg: totalKg, barbellWeightKg: barKg, weightUnit: .pounds)
        let dict = Dictionary(uniqueKeysWithValues: plates.map { ($0.weight, $0.count) })
        #expect(dict[45.0] == 2)
    }

    @Test func lbPlatesBreakdown() {
        // 135 lb total, 45 lb bar → 45 lb per side → 1×45
        let totalKg = 135.0 / 2.2046226218
        let barKg = PlateCalculation.standardBarKg
        let plates = PlateCalculation.platesPerSide(totalWeightKg: totalKg, barbellWeightKg: barKg, weightUnit: .pounds)
        let dict = Dictionary(uniqueKeysWithValues: plates.map { ($0.weight, $0.count) })
        #expect(dict[45.0] == 1)
    }

    @Test func descriptionBarOnly() {
        let barKg = PlateCalculation.standardBarKg
        let desc = PlateCalculation.description(totalWeightKg: barKg, barbellWeightKg: barKg)
        #expect(desc.contains("Bar only"))
    }

    @Test func standardBarIsFortyFiveLb() {
        let lb = PlateCalculation.standardBarKg * 2.2046226218
        #expect(abs(lb - 45.0) < 0.01)
    }

    @Test func womenBarIsThirtyFiveLb() {
        let lb = PlateCalculation.womenBarKg * 2.2046226218
        #expect(abs(lb - 35.0) < 0.01)
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

    @Test func zeroAverageCycleLengthDoesNotCrash() {
        // Issue: Zero average length cycle edge case
        let result = CycleCalculations.calculateCycleStatus(
            periodLogs: [makePeriodLog(startOffset: -60)], // Ensure we fall into the else block for cycleStartDate
            settings: makeSettings(cycleDays: 0, periodDays: 5, lutealDays: 14)
        )
        // We just want to ensure it doesn't crash from division by zero, and it returns safely
        #expect(result != nil)
        // With length max(1, 0) -> 1, completed = 60 / 1 = 60, cycle start = 60 * 1 = 60, cycle day = 61
        // (the values don't matter as much as the crash not occurring)
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

    @Test func phaseBoundariesStandardCycle() {
        let settings = makeSettings(cycleDays: 28, periodDays: 5, lutealDays: 14)
        let boundaries = CycleCalculations.getPhaseBoundaries(settings: settings)

        // ovDay = 28 - 14 = 14
        // ovStart = max(5 + 2, 14 - 2) = max(7, 12) = 12
        // ovEnd = min(14 + 2, 28 - 14 + 2) = min(16, 16) = 16

        #expect(boundaries[.menstrual]?.start == 1)
        #expect(boundaries[.menstrual]?.end == 5)

        #expect(boundaries[.follicular]?.start == 6)
        #expect(boundaries[.follicular]?.end == 11)

        #expect(boundaries[.ovulation]?.start == 12)
        #expect(boundaries[.ovulation]?.end == 16)

        #expect(boundaries[.luteal]?.start == 17)
        #expect(boundaries[.luteal]?.end == 28)
    }

    @Test func phaseBoundariesShortCycle() {
        let settings = makeSettings(cycleDays: 21, periodDays: 3, lutealDays: 10)
        let boundaries = CycleCalculations.getPhaseBoundaries(settings: settings)

        #expect(boundaries[.menstrual]?.start == 1)
        #expect(boundaries[.menstrual]?.end == 3)

        #expect(boundaries[.follicular]?.start == 4)
        #expect(boundaries[.follicular]?.end == 8)

        #expect(boundaries[.ovulation]?.start == 9)
        #expect(boundaries[.ovulation]?.end == 13)

        #expect(boundaries[.luteal]?.start == 14)
        #expect(boundaries[.luteal]?.end == 21)
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
        let week = ProgramWeek(week: 1, phaseID: "", isTestWeek: false, sessions: [session])
        return Program(id: "p1", name: "Test", category: "Test",
                       description: "", durationWeeks: 1, sessionsPerWeek: 1,
                       difficulty: "beginner", phases: [], cycleAdjustmentProfile: nil, weeks: [week])
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

    @Test func femaleBarbellWeightIs35Lb() {
        // Women's bar is 35 lb (~15.876 kg)
        let weight = DashboardViewModel.barbellWeight(for: .female)
        #expect(abs(weight - PlateCalculation.womenBarKg) < 0.001)
    }

    @Test func maleBarbellWeightIs45Lb() {
        // Men's bar is 45 lb (~20.412 kg)
        let weight = DashboardViewModel.barbellWeight(for: .male)
        #expect(abs(weight - PlateCalculation.standardBarKg) < 0.001)
    }

    @Test func preferNotToSayBarbellWeightIs45Lb() {
        let weight = DashboardViewModel.barbellWeight(for: .preferNotToSay)
        #expect(abs(weight - PlateCalculation.standardBarKg) < 0.001)
    }

    @Test func nilGenderBarbellWeightIs45Lb() {
        let weight = DashboardViewModel.barbellWeight(for: nil)
        #expect(abs(weight - PlateCalculation.standardBarKg) < 0.001)
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
