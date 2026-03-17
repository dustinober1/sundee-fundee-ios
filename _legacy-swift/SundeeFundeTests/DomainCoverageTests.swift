import Testing
import Foundation
@testable import SundeeFundee

@Suite("WeightCalculations Additional")
struct WeightCalculationsAdditionalTests {

    @Test func wasSetSuccessfulCoversWeightAndRepBranches() {
        #expect(WeightCalculations.wasSetSuccessful(
            actualReps: 5, prescribedReps: 5, actualWeight: 95, prescribedWeight: nil) == true)
        #expect(WeightCalculations.wasSetSuccessful(
            actualReps: 5, prescribedReps: 5, actualWeight: 100, prescribedWeight: 100) == true)
        #expect(WeightCalculations.wasSetSuccessful(
            actualReps: 4, prescribedReps: 5, actualWeight: 100, prescribedWeight: 100) == false)
        #expect(WeightCalculations.wasSetSuccessful(
            actualReps: 5, prescribedReps: 5, actualWeight: 95, prescribedWeight: 100) == false)
    }

    @Test func isPersonalRecordTrueAndFalse() {
        #expect(WeightCalculations.isPersonalRecord(weight: 105, previousMax: 100) == true)
        #expect(WeightCalculations.isPersonalRecord(weight: 100, previousMax: 100) == false)
    }

    @Test func detectPlateauCoversEdgeCasesAndHappyPaths() {
        // Less than 3 elements -> false
        #expect(WeightCalculations.detectPlateau(weights: []) == false)
        #expect(WeightCalculations.detectPlateau(weights: [100]) == false)
        #expect(WeightCalculations.detectPlateau(weights: [100, 100]) == false)

        // Exact 3 elements, plateau (diff < 5) -> true
        #expect(WeightCalculations.detectPlateau(weights: [100, 100, 100]) == true)
        #expect(WeightCalculations.detectPlateau(weights: [100, 102.5, 104]) == true)

        // Exact 3 elements, no plateau (diff >= 5) -> false
        #expect(WeightCalculations.detectPlateau(weights: [100, 102.5, 105]) == false)
        #expect(WeightCalculations.detectPlateau(weights: [100, 100, 105]) == false)

        // More than 3 elements, last 3 are plateau -> true
        #expect(WeightCalculations.detectPlateau(weights: [50, 60, 100, 102.5, 104]) == true)

        // More than 3 elements, last 3 are not plateau -> false
        #expect(WeightCalculations.detectPlateau(weights: [100, 100, 100, 102.5, 105]) == false)
    }
}

@Suite("PlateCalculation Additional")
struct PlateCalculationAdditionalTests {

    @Test func descriptionCoversPlateFormattingBranch() {
        // description() uses kg-unit path, output now shows lb equivalents
        let barKg = PlateCalculation.standardBarKg
        // 135 lb total → 45 lb per side → 1×45lb per side
        let totalKg = 135.0 / 2.2046226218
        let desc = PlateCalculation.description(totalWeightKg: totalKg, barbellWeightKg: barKg)
        #expect(desc.contains("per side"))
    }
}

@Suite("CycleCalculations Additional")
struct CycleCalculationsAdditionalTests {

    private var referenceDate: Date { Calendar.current.startOfDay(for: .now) }

    private func makeSettings(
        cycleDays: Int = 28,
        periodDays: Int = 5,
        lutealDays: Int = 14
    ) -> CycleSettings {
        CycleSettings(
            id: UUID().uuidString,
            userID: "u1",
            averageCycleLengthDays: cycleDays,
            averagePeriodLengthDays: periodDays,
            lutealPhaseLengthDays: lutealDays
        )
    }

    private func makePeriodLog(startOffset: Int, endOffset: Int? = nil) -> PeriodLog {
        let start = Calendar.current.date(byAdding: .day, value: startOffset, to: referenceDate)!
        let end = endOffset.map { Calendar.current.date(byAdding: .day, value: $0, to: referenceDate)! }
        return PeriodLog(id: UUID().uuidString, userID: "u1", startDate: start, endDate: end)
    }

    @Test func detectsOvulationAndLutealPhases() {
        let settings = makeSettings()

        let ovulation = CycleCalculations.calculateCycleStatus(
            periodLogs: [makePeriodLog(startOffset: -12)],
            settings: settings,
            referenceDate: referenceDate
        )
        #expect(ovulation?.currentPhase == .ovulation)

        let luteal = CycleCalculations.calculateCycleStatus(
            periodLogs: [makePeriodLog(startOffset: -20)],
            settings: settings,
            referenceDate: referenceDate
        )
        #expect(luteal?.currentPhase == .luteal)
    }

    @Test func sortsMultipleLogsByRecency() {
        let settings = makeSettings()
        let recent = makePeriodLog(startOffset: -7)
        let older = makePeriodLog(startOffset: -35)
        let result = CycleCalculations.calculateCycleStatus(
            periodLogs: [older, recent],
            settings: settings,
            referenceDate: referenceDate
        )
        #expect(result?.cycleDay == 8)
        #expect(result?.currentPhase == .follicular)
    }

    @Test func computesFallbackCycleStartWhenReferencePastExpectedWindow() {
        let result = CycleCalculations.calculateCycleStatus(
            periodLogs: [makePeriodLog(startOffset: -60)],
            settings: makeSettings(),
            referenceDate: referenceDate
        )
        #expect(result?.cycleDay == 5)
    }

    @Test func respectsExplicitPeriodEndDate() {
        let result = CycleCalculations.calculateCycleStatus(
            periodLogs: [makePeriodLog(startOffset: -2, endOffset: 0)],
            settings: makeSettings(),
            referenceDate: referenceDate
        )
        #expect(result?.currentPhase == .menstrual)
        #expect(result?.cycleDay == 3)
    }

    @Test func includesRemainingPhaseRecommendations() {
        let follicular = CycleCalculations.getPhaseRecommendation(.follicular)
        #expect(follicular.intensityRecommendation == "moderate")
        #expect(follicular.exercisesToAvoid.isEmpty)

        let luteal = CycleCalculations.getPhaseRecommendation(.luteal)
        #expect(luteal.intensityRecommendation == "moderate")
        #expect(!luteal.exercisesToAvoid.isEmpty)
    }

    @Test func cyclePhaseDisplayMetadata() {
        #expect(CyclePhase.menstrual.displayName == "Menstrual")
        #expect(CyclePhase.follicular.displayName == "Follicular")
        #expect(CyclePhase.ovulation.displayName == "Ovulation")
        #expect(CyclePhase.luteal.displayName == "Luteal")
        #expect(CyclePhase.menstrual.emoji == "🌊")
        #expect(CyclePhase.follicular.emoji == "🌱")
        #expect(CyclePhase.ovulation.emoji == "⚡️")
        #expect(CyclePhase.luteal.emoji == "🌕")
    }
}

@Suite("CycleAdaptationPolicy Additional")
struct CycleAdaptationPolicyAdditionalTests {

    private let policy = CycleAdaptationPolicy()
    private var referenceDate: Date { Calendar.current.startOfDay(for: .now) }

    @Test func resolveReadinessTierThresholds() {
        #expect(policy.resolveReadinessTier(readinessScore: nil) == .neutral)
        #expect(policy.resolveReadinessTier(readinessScore: 3) == .low)
        #expect(policy.resolveReadinessTier(readinessScore: 8) == .high)
        #expect(policy.resolveReadinessTier(readinessScore: 6) == .neutral)
    }

    @Test func resolvePhasePriorityOrder() {
        #expect(policy.resolvePhase(currentPhase: .ovulation, lastKnownPhase: .luteal) == .ovulation)
        #expect(policy.resolvePhase(currentPhase: nil, lastKnownPhase: .luteal) == .luteal)
        #expect(policy.resolvePhase(currentPhase: nil, lastKnownPhase: nil, fallbackPhase: "invalid") == .follicular)
    }

    @Test func resolveConfidenceBranches() {
        #expect(policy.resolveConfidence(
            currentPhase: nil, lastKnownPhase: nil, periodLogCount: 0,
            lastPeriodStart: nil, referenceDate: referenceDate
        ) == .low)

        let staleStart = Calendar.current.date(byAdding: .day, value: -46, to: referenceDate)!
        #expect(policy.resolveConfidence(
            currentPhase: .follicular, lastKnownPhase: nil, periodLogCount: 4,
            lastPeriodStart: staleStart, referenceDate: referenceDate
        ) == .low)

        let recentStart = Calendar.current.date(byAdding: .day, value: -5, to: referenceDate)!
        #expect(policy.resolveConfidence(
            currentPhase: .follicular, lastKnownPhase: nil, periodLogCount: 3,
            lastPeriodStart: recentStart, referenceDate: referenceDate
        ) == .high)
        #expect(policy.resolveConfidence(
            currentPhase: .follicular, lastKnownPhase: nil, periodLogCount: 1,
            lastPeriodStart: recentStart, referenceDate: referenceDate
        ) == .medium)
        #expect(policy.resolveConfidence(
            currentPhase: nil, lastKnownPhase: .luteal, periodLogCount: 2,
            lastPeriodStart: recentStart, referenceDate: referenceDate
        ) == .low)
    }

    @Test func resolveConfidenceScaleClampsForLowConfidence() {
        #expect(policy.resolveConfidenceScale(confidence: .low, lowConfidenceScale: 0.0) == 0.1)
        #expect(policy.resolveConfidenceScale(confidence: .medium) == 0.8)
    }

    @Test func applyPhaseAdjustmentCoversRangeAndPassthroughValues() {
        let ranged = ProgramExercise(
            exercise: "Back Squat",
            variant: nil,
            sets: .range(3, 5),
            reps: .range(8, 10),
            percent1RM: nil,
            restMinutes: 3,
            notes: nil
        )
        let rangedAdapted = policy.applyPhaseAdjustment(
            exercise: ranged,
            phase: .menstrual,
            readinessTier: .high,
            confidence: .high,
            profile: nil
        )

        switch rangedAdapted.sets {
        case .range(let lo, let hi):
            #expect(lo >= 1)
            #expect(hi >= lo)
        default:
            #expect(Bool(false))
        }
        switch rangedAdapted.reps {
        case .range(let lo, let hi):
            #expect(lo >= 1)
            #expect(hi >= lo)
        default:
            #expect(Bool(false))
        }
        #expect(rangedAdapted.percent1RM == nil)

        let passthrough = ProgramExercise(
            exercise: "Pull-Up",
            variant: nil,
            sets: .amrap,
            reps: .text("tempo"),
            percent1RM: 0.75,
            restMinutes: 2,
            notes: nil
        )
        let passthroughAdapted = policy.applyPhaseAdjustment(
            exercise: passthrough,
            phase: .ovulation,
            readinessTier: .neutral,
            confidence: .high,
            profile: nil
        )

        let hasAMRAPSets: Bool
        if case .amrap = passthroughAdapted.sets { hasAMRAPSets = true } else { hasAMRAPSets = false }
        #expect(hasAMRAPSets)

        let hasTempoReps: Bool
        if case .text("tempo") = passthroughAdapted.reps { hasTempoReps = true } else { hasTempoReps = false }
        #expect(hasTempoReps)
    }

    @Test func applyPhaseAdjustmentUsesProfileOverride() {
        let profile = ProgramCycleAdjustmentProfile(
            fallbackPhase: "follicular",
            lowConfidenceScale: 0.7,
            phaseSettings: [
                "ovulation": PhaseSettings(
                    loadMultiplier: 1.20,
                    setsMultiplier: 1.00,
                    repsMultiplier: 1.00
                )
            ]
        )
        let exercise = ProgramExercise(
            exercise: "Back Squat",
            variant: nil,
            sets: .fixed(3),
            reps: .fixed(5),
            percent1RM: 0.80,
            restMinutes: 3,
            notes: nil
        )
        let adapted = policy.applyPhaseAdjustment(
            exercise: exercise,
            phase: .ovulation,
            readinessTier: .neutral,
            confidence: .high,
            profile: profile
        )
        #expect(abs((adapted.percent1RM ?? 0) - 0.96) < 0.0001)
    }

    @Test func blendMultiplierClampsCorrectly() {
        // Readiness scale for .high is 1.2
        // Confidence scale for .high is 1.0
        // blendMultiplier(target) = (1.0 + (target - 1.0) * 1.2 * 1.0).clamped(to: 0.75...1.25)

        // Let's force target bounds using a custom profile
        // - loadMultiplier: 2.0 -> math gives 1.0 + (1.0 * 1.2) = 2.2 -> clamped to 1.25
        // - setsMultiplier: 0.1 -> math gives 1.0 + (-0.9 * 1.2) = 1.0 - 1.08 = -0.08 -> clamped to 0.75
        // - repsMultiplier: 1.0 -> math gives 1.0 + (0 * 1.2) = 1.0 -> no clamp (1.0)
        let extremeProfile = ProgramCycleAdjustmentProfile(
            fallbackPhase: "ovulation",
            lowConfidenceScale: 1.0,
            phaseSettings: [
                "ovulation": PhaseSettings(
                    loadMultiplier: 2.0,
                    setsMultiplier: 0.1,
                    repsMultiplier: 1.0
                )
            ]
        )

        let exercise = ProgramExercise(
            exercise: "Test Exercise",
            variant: nil,
            sets: .fixed(100), // 100 * 0.75 = 75
            reps: .fixed(10),  // 10 * 1.0 = 10
            percent1RM: 0.80,  // 0.80 * 1.25 = 1.0
            restMinutes: 3,
            notes: nil
        )

        let adapted = policy.applyPhaseAdjustment(
            exercise: exercise,
            phase: .ovulation,
            readinessTier: .high,
            confidence: .high,
            profile: extremeProfile
        )

        // loadMultiplier clamped to 1.25 -> percent1RM = 0.80 * 1.25 = 1.0
        #expect(abs((adapted.percent1RM ?? 0) - 1.0) < 0.0001)

        // setsMultiplier clamped to 0.75 -> sets = 100 * 0.75 = 75
        switch adapted.sets {
        case .fixed(let n):
            #expect(n == 75)
        default:
            Issue.record("Expected sets to be .fixed")
        }

        // repsMultiplier evaluates to 1.0 -> reps = 10 * 1.0 = 10
        switch adapted.reps {
        case .fixed(let n):
            #expect(n == 10)
        default:
            Issue.record("Expected reps to be .fixed")
        }
    }
}

@Suite("CycleProgramGenerator Additional")
struct CycleProgramGeneratorAdditionalTests {

    private var referenceDate: Date { Calendar.current.startOfDay(for: .now) }

    private func makeSettings() -> CycleSettings {
        CycleSettings(
            id: UUID().uuidString,
            userID: "u1",
            averageCycleLengthDays: 28,
            averagePeriodLengthDays: 5,
            lutealPhaseLengthDays: 14
        )
    }

    private func makePreferences(
        enabled: Bool = true,
        fallbackPhase: String = "follicular"
    ) -> CycleAdaptationPreferences {
        CycleAdaptationPreferences(
            id: UUID().uuidString,
            userID: "u1",
            adaptationEnabled: enabled,
            fallbackPhase: fallbackPhase
        )
    }

    private func makePeriodLog(startOffset: Int) -> PeriodLog {
        let start = Calendar.current.date(byAdding: .day, value: startOffset, to: referenceDate)!
        return PeriodLog(id: UUID().uuidString, userID: "u1", startDate: start)
    }

    private func makeProgram(profile: ProgramCycleAdjustmentProfile? = nil) -> Program {
        let ex = ProgramExercise(
            exercise: "Back Squat",
            variant: nil,
            sets: .fixed(3),
            reps: .fixed(5),
            percent1RM: 0.80,
            restMinutes: 3,
            notes: nil
        )
        let session = ProgramSession(
            sessionID: "s1",
            sessionName: "Day 1",
            sessionType: "strength",
            focus: "Lower",
            exercises: [ex]
        )
        let week = ProgramWeek(week: 1, phaseID: "", isTestWeek: false, sessions: [session])
        return Program(
            id: "p-cycle",
            name: "Cycle Test",
            category: "Strength",
            description: "",
            durationWeeks: 1,
            sessionsPerWeek: 1,
            difficulty: "beginner",
            phases: [],
            cycleAdjustmentProfile: profile, weeks: [week]
        )
    }

    @Test func returnsUnchangedWhenPreferencesMissingOrDisabled() {
        let program = makeProgram()
        let settings = makeSettings()

        let missingPrefs = CycleProgramGenerator.adaptProgram(
            program,
            phase: .ovulation,
            settings: settings,
            preferences: nil,
            periodLogs: [],
            referenceDate: referenceDate
        )
        #expect(missingPrefs.weeks[0].sessions[0].exercises[0].percent1RM == 0.80)

        let disabledPrefs = CycleProgramGenerator.adaptProgram(
            program,
            phase: .ovulation,
            settings: settings,
            preferences: makePreferences(enabled: false),
            periodLogs: [],
            referenceDate: referenceDate
        )
        #expect(disabledPrefs.weeks[0].sessions[0].exercises[0].percent1RM == 0.80)
    }

    @Test func returnsUnchangedWhenSettingsMissing() {
        let program = makeProgram()
        let adapted = CycleProgramGenerator.adaptProgram(
            program,
            phase: .ovulation,
            settings: nil,
            preferences: makePreferences(),
            periodLogs: [],
            referenceDate: referenceDate
        )
        #expect(adapted.weeks[0].sessions[0].exercises[0].percent1RM == 0.80)
    }

    @Test func prefersCurrentCycleStatusOverPassedPhase() {
        let program = makeProgram()
        let logs = [makePeriodLog(startOffset: -30), makePeriodLog(startOffset: 0)]
        let adapted = CycleProgramGenerator.adaptProgram(
            program,
            phase: .ovulation,
            settings: makeSettings(),
            preferences: makePreferences(),
            periodLogs: logs,
            referenceDate: referenceDate
        )
        let percent = adapted.weeks[0].sessions[0].exercises[0].percent1RM ?? 0
        #expect(percent < 0.80)
    }

    @Test func fallsBackToLastKnownAndPreferencePhaseWhenStatusUnavailable() {
        let program = makeProgram()
        let settings = makeSettings()

        let fromLastKnown = CycleProgramGenerator.adaptProgram(
            program,
            phase: .ovulation,
            settings: settings,
            preferences: makePreferences(),
            periodLogs: [],
            referenceDate: referenceDate
        )
        let lastKnownPercent = fromLastKnown.weeks[0].sessions[0].exercises[0].percent1RM ?? 0
        #expect(lastKnownPercent > 0.80)

        let fromFallback = CycleProgramGenerator.adaptProgram(
            program,
            phase: nil,
            settings: settings,
            preferences: makePreferences(fallbackPhase: "luteal"),
            periodLogs: [],
            referenceDate: referenceDate
        )
        let fallbackPercent = fromFallback.weeks[0].sessions[0].exercises[0].percent1RM ?? 0
        #expect(fallbackPercent < 0.80)
    }
}

@Suite("Program Parsing Additional")
struct ProgramParsingAdditionalTests {

    private struct ValueBox: Codable {
        let value: ExerciseValue
    }

    private func decodeValue(_ literal: String) throws -> ExerciseValue {
        let data = Data("{\"value\":\(literal)}".utf8)
        return try JSONDecoder().decode(ValueBox.self, from: data).value
    }

    private func fixedValue(_ value: ExerciseValue) -> Int? {
        guard case .fixed(let n) = value else { return nil }
        return n
    }

    private func rangeValue(_ value: ExerciseValue) -> [Int]? {
        guard case .range(let lo, let hi) = value else { return nil }
        return [lo, hi]
    }

    private func textValue(_ value: ExerciseValue) -> String? {
        guard case .text(let t) = value else { return nil }
        return t
    }

    private func isAMRAP(_ value: ExerciseValue) -> Bool {
        if case .amrap = value { return true }
        return false
    }

    private func makeProgram(id: String, name: String) -> Program {
        let exercise = ProgramExercise(
            exercise: "Back Squat",
            variant: nil,
            sets: .fixed(3),
            reps: .fixed(5),
            percent1RM: 0.8,
            restMinutes: 3,
            notes: nil
        )
        let session = ProgramSession(
            sessionID: "s1",
            sessionName: "Day 1",
            sessionType: "strength",
            focus: "Lower",
            exercises: [exercise]
        )
        let week = ProgramWeek(week: 1, phaseID: "", isTestWeek: false, sessions: [session])
        return Program(
            id: id,
            name: name,
            category: "Strength",
            description: "",
            durationWeeks: 1,
            sessionsPerWeek: 1,
            difficulty: "beginner",
            phases: [],
            cycleAdjustmentProfile: nil, weeks: [week]
        )
    }

    @Test func decodesProgramCodingKeysAndExerciseVariants() throws {
        let json = """
        {
          "id": "p1",
          "name": "Test Program",
          "category": "Strength",
          "description": "desc",
          "durationWeeks": 1,
          "sessionsPerWeek": 1,
          "difficulty": "beginner",
          "phases": [
            { "id": "base", "name": "Base", "goal": "Build", "weekRange": [1] }
          ],
          "weeks": [
            {
              "week": 1,
              "phaseId": "base",
              "isTestWeek": true,
              "sessions": [
                {
                  "sessionId": "s1",
                  "sessionName": "Day 1",
                  "sessionType": "strength",
                  "focus": "Lower",
                  "exercises": [
                    {
                      "exercise": "Back Squat",
                      "variant": null,
                      "sets": 3,
                      "reps": "5-7",
                      "percent1RM": 0.8,
                      "restMinutes": 3,
                      "notes": "notes"
                    },
                    {
                      "exercise": "Bench Press",
                      "variant": "Close Grip",
                      "sets": "AMRAP",
                      "reps": [8, 10],
                      "percent1RM": null,
                      "restMinutes": 2.5,
                      "notes": null
                    }
                  ]
                }
              ]
            }
          ],
          "cycleAdjustmentProfile": {
            "fallbackPhase": "luteal",
            "lowConfidenceScale": 0.6,
            "phaseSettings": {
              "ovulation": {
                "loadMultiplier": 1.1,
                "setsMultiplier": 1.0,
                "repsMultiplier": 0.9
              }
            }
          }
        }
        """

        let program = try JSONDecoder().decode(Program.self, from: Data(json.utf8))
        let session = program.weeks[0].sessions[0]
        #expect(program.weeks[0].phaseID == "base")
        #expect(session.sessionID == "s1")
        #expect(fixedValue(session.exercises[0].sets) == 3)
        #expect(rangeValue(session.exercises[0].reps) == [5, 7])
        #expect(isAMRAP(session.exercises[1].sets) == true)
        #expect(rangeValue(session.exercises[1].reps) == [8, 10])
        #expect(program.cycleAdjustmentProfile?.fallbackPhase == "luteal")
    }

    @Test func exerciseValueDecodingCoversAllSupportedFormats() throws {
        #expect(fixedValue(try decodeValue("4")) == 4)
        #expect(fixedValue(try decodeValue("4.9")) == 4)
        #expect(isAMRAP(try decodeValue("\" AMRAP \"")) == true)
        #expect(rangeValue(try decodeValue("\" 3 - 5 \"")) == [3, 5])
        #expect(fixedValue(try decodeValue("\"12\"")) == 12)
        #expect(textValue(try decodeValue("\"tempo\"")) == "tempo")
        #expect(rangeValue(try decodeValue("[6,8]")) == [6, 8])
        #expect(fixedValue(try decodeValue("{}")) == 0)
    }

    @Test func exerciseValueEncodingCoversAllCases() throws {
        let values: [ExerciseValue] = [.fixed(5), .amrap, .range(3, 6), .text("tempo")]
        let data = try JSONEncoder().encode(values)
        let decoded = try JSONDecoder().decode([ExerciseValue].self, from: data)
        #expect(fixedValue(decoded[0]) == 5)
        #expect(isAMRAP(decoded[1]) == true)
        #expect(rangeValue(decoded[2]) == [3, 6])
        #expect(textValue(decoded[3]) == "tempo")
    }

    @Test func exerciseValueDescriptions() {
        #expect(ExerciseValue.fixed(5).description == "5")
        #expect(ExerciseValue.amrap.description == "AMRAP")
        #expect(ExerciseValue.range(3, 6).description == "3–6")
        #expect(ExerciseValue.text("tempo").description == "tempo")
    }

    @Test func programHashAndCycleAdjustmentInitializers() {
        let lhs = makeProgram(id: "same-id", name: "A")
        let rhs = makeProgram(id: "same-id", name: "B")
        #expect(lhs == rhs)
        #expect(Set([lhs, rhs]).count == 1)

        let profile = ProgramCycleAdjustmentProfile()
        #expect(profile.fallbackPhase == "follicular")
        #expect(profile.lowConfidenceScale == 0.7)
        #expect(profile.phaseSettings.isEmpty)

        let defaults = PhaseSettings()
        #expect(defaults.loadMultiplier == 1.0)
        #expect(defaults.setsMultiplier == 1.0)
        #expect(defaults.repsMultiplier == 1.0)
    }
}

@Suite("CycleProgramGenerator Note Generation")
struct CycleProgramGeneratorNoteTests {

    private func makeExercise(
        sets: ExerciseValue = .fixed(3),
        reps: ExerciseValue = .fixed(5),
        percent1RM: Double? = 0.80,
        notes: String? = nil
    ) -> ProgramExercise {
        ProgramExercise(
            exercise: "Back Squat",
            variant: nil,
            sets: sets,
            reps: reps,
            percent1RM: percent1RM,
            restMinutes: 3,
            notes: notes
        )
    }

    @Test func noteIncludesOriginalAndAdjustedSchemeWithLoad() {
        let original = makeExercise(sets: .fixed(3), reps: .fixed(5), percent1RM: 0.80)
        let adapted = makeExercise(sets: .fixed(3), reps: .fixed(4), percent1RM: 0.72)
        let note = CycleProgramGenerator.cycleAdjustmentNote(
            original: original,
            adapted: adapted,
            phase: .menstrual
        )
        #expect(note == "Program: 3×5 @ 80% → Menstrual: 3×4 @ 72%")
    }

    @Test func noteIncludesSchemeWithoutLoadWhenNoPercent() {
        let original = makeExercise(sets: .fixed(3), reps: .fixed(8), percent1RM: nil)
        let adapted = makeExercise(sets: .fixed(3), reps: .fixed(7), percent1RM: nil)
        let note = CycleProgramGenerator.cycleAdjustmentNote(
            original: original,
            adapted: adapted,
            phase: .luteal
        )
        #expect(note == "Program: 3×8 → Luteal: 3×7")
    }

    @Test func noteIsNilWhenNothingChanged() {
        let original = makeExercise(sets: .fixed(3), reps: .fixed(5), percent1RM: 0.80)
        let adapted = makeExercise(sets: .fixed(3), reps: .fixed(5), percent1RM: 0.80)
        let note = CycleProgramGenerator.cycleAdjustmentNote(
            original: original,
            adapted: adapted,
            phase: .follicular
        )
        #expect(note == nil)
    }

    @Test func noteOnlyLoadChangedIsDetected() {
        let original = makeExercise(sets: .fixed(3), reps: .fixed(5), percent1RM: 0.80)
        let adapted = makeExercise(sets: .fixed(3), reps: .fixed(5), percent1RM: 0.90)
        let note = CycleProgramGenerator.cycleAdjustmentNote(
            original: original,
            adapted: adapted,
            phase: .ovulation
        )
        #expect(note == "Program: 3×5 @ 80% → Ovulation: 3×5 @ 90%")
    }

    @Test func existingNoteIsCombinedWithCycleNote() {
        let referenceDate = Calendar.current.startOfDay(for: .now)
        let recentStart = Calendar.current.date(byAdding: .day, value: -2, to: referenceDate)!
        let settings = CycleSettings(
            id: UUID().uuidString,
            userID: "u1",
            averageCycleLengthDays: 28,
            averagePeriodLengthDays: 5,
            lutealPhaseLengthDays: 14
        )
        let prefs = CycleAdaptationPreferences(
            id: UUID().uuidString,
            userID: "u1",
            adaptationEnabled: true,
            fallbackPhase: "follicular"
        )
        let periodLog = PeriodLog(id: UUID().uuidString, userID: "u1", startDate: recentStart)
        let ex = ProgramExercise(
            exercise: "Back Squat",
            variant: nil,
            sets: .fixed(3),
            reps: .fixed(5),
            percent1RM: 0.80,
            restMinutes: 3,
            notes: "Keep chest up"
        )
        let session = ProgramSession(
            sessionID: "s1", sessionName: "Day 1",
            sessionType: "strength", focus: "Lower",
            exercises: [ex]
        )
        let week = ProgramWeek(week: 1, phaseID: "", isTestWeek: false, sessions: [session])
        let program = Program(
            id: "p1", name: "Test", category: "Strength", description: "",
            durationWeeks: 1, sessionsPerWeek: 1, difficulty: "beginner",
            phases: [], cycleAdjustmentProfile: nil, weeks: [week]
        )
        let adapted = CycleProgramGenerator.adaptProgram(
            program,
            phase: nil,
            settings: settings,
            preferences: prefs,
            periodLogs: [periodLog],
            referenceDate: referenceDate
        )
        let adaptedEx = adapted.weeks[0].sessions[0].exercises[0]
        // If adjusted, the note should start with the existing note and include the cycle note
        if let note = adaptedEx.notes, note.contains("Program:") {
            #expect(note.hasPrefix("Keep chest up"))
        }
    }
}

@Suite("Comparable Extension Tests")
struct ComparableExtensionTests {

    @Test func comparableClampedExtension() {
        let intRange = 5...10

        // Below lower bound
        #expect(3.clamped(to: intRange) == 5)

        // Equal to lower bound
        #expect(5.clamped(to: intRange) == 5)

        // Within range
        #expect(7.clamped(to: intRange) == 7)

        // Equal to upper bound
        #expect(10.clamped(to: intRange) == 10)

        // Above upper bound
        #expect(12.clamped(to: intRange) == 10)

        // Test with Double
        let doubleRange = 0.5...1.5
        #expect(0.1.clamped(to: doubleRange) == 0.5)
        #expect(1.0.clamped(to: doubleRange) == 1.0)
        #expect(2.0.clamped(to: doubleRange) == 1.5)
    }
}
