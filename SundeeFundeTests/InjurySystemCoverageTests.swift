import Testing
import Foundation
@testable import SundeeFundee

// MARK: - RecoveryPhase Tests

@Suite("RecoveryPhase")
struct RecoveryPhaseTests {
    @Test func allCasesExist() {
        #expect(RecoveryPhase.allCases.count == 5)
    }

    @Test func rawValues() {
        #expect(RecoveryPhase.acute.rawValue == "acute")
        #expect(RecoveryPhase.rehab.rawValue == "rehab")
        #expect(RecoveryPhase.lightLoad.rawValue == "lightLoad")
        #expect(RecoveryPhase.returnToPlay.rawValue == "returnToPlay")
        #expect(RecoveryPhase.resolved.rawValue == "resolved")
    }

    @Test func displayNames() {
        #expect(RecoveryPhase.acute.displayName == "Acute")
        #expect(RecoveryPhase.rehab.displayName == "Rehab")
        #expect(RecoveryPhase.lightLoad.displayName == "Light Load")
        #expect(RecoveryPhase.returnToPlay.displayName == "Return to Play")
        #expect(RecoveryPhase.resolved.displayName == "Resolved")
    }
}

// MARK: - BodyLocation Tests

@Suite("BodyLocation")
struct BodyLocationTests {
    @Test func allRegionsExist() {
        #expect(BodyLocation.Region.allCases.count == 17)
    }

    @Test func engineKeysMapCorrectly() {
        #expect(BodyLocation.Region.leftKnee.engineKey == "knee")
        #expect(BodyLocation.Region.rightKnee.engineKey == "knee")
        #expect(BodyLocation.Region.leftShoulder.engineKey == "shoulder")
        #expect(BodyLocation.Region.rightShoulder.engineKey == "shoulder")
        #expect(BodyLocation.Region.chest.engineKey == "shoulder")
        #expect(BodyLocation.Region.lowerBack.engineKey == "back")
        #expect(BodyLocation.Region.upperBack.engineKey == "back")
        #expect(BodyLocation.Region.head.engineKey == "back")
        #expect(BodyLocation.Region.neck.engineKey == "back")
        #expect(BodyLocation.Region.leftHip.engineKey == "hip")
        #expect(BodyLocation.Region.rightHip.engineKey == "hip")
        #expect(BodyLocation.Region.leftAnkle.engineKey == "ankle")
        #expect(BodyLocation.Region.rightAnkle.engineKey == "ankle")
        #expect(BodyLocation.Region.leftWrist.engineKey == "wrist")
        #expect(BodyLocation.Region.rightWrist.engineKey == "wrist")
        #expect(BodyLocation.Region.leftElbow.engineKey == "wrist")
        #expect(BodyLocation.Region.rightElbow.engineKey == "wrist")
    }

    @Test func displayNames() {
        #expect(BodyLocation.Region.leftKnee.displayName == "Left Knee")
        #expect(BodyLocation.Region.rightShoulder.displayName == "Right Shoulder")
        #expect(BodyLocation.Region.lowerBack.displayName == "Lower Back")
    }

    @Test func parseAndEncodeRoundTrips() {
        let regions: [BodyLocation.Region] = [.leftKnee, .rightShoulder]
        let encoded = BodyLocation.encodeRegions(regions)
        let decoded = BodyLocation.parseRegions(encoded)
        #expect(decoded == regions)
    }

    @Test func parseEmptyString() {
        let result = BodyLocation.parseRegions("")
        #expect(result.isEmpty)
    }

    @Test func parseInvalidString() {
        let result = BodyLocation.parseRegions("invalid,garbage")
        #expect(result.isEmpty)
    }
}

// MARK: - PainTrendAnalyzer Tests

@Suite("PainTrendAnalyzer")
struct PainTrendAnalyzerTests {
    private func makeLogs(levels: [Int]) -> [PainLog] {
        levels.enumerated().map { (i, level) in
            PainLog(
                injuryProfileID: "injury1",
                painLevel: level,
                recordedAt: Date().addingTimeInterval(-Double(i) * 3600)
            )
        }
    }

    @Test func emptyLogsReturnsDefault() {
        let result = PainTrendAnalyzer.analyzeTrend(logs: [])
        #expect(result.trailingAverage == 0)
        #expect(result.isImproving == false)
        #expect(result.latestPainLevel == nil)
        #expect(result.readingCount == 0)
    }

    @Test func singleLogNotImproving() {
        let logs = makeLogs(levels: [5])
        let result = PainTrendAnalyzer.analyzeTrend(logs: logs)
        #expect(result.trailingAverage == 5.0)
        #expect(result.isImproving == false)
        #expect(result.latestPainLevel == 5)
        #expect(result.readingCount == 1)
    }

    @Test func windowSizeOneWithMultipleLogs() {
        let logs = makeLogs(levels: [5, 4, 3])
        let result = PainTrendAnalyzer.analyzeTrend(logs: logs, windowSize: 1)
        #expect(result.trailingAverage == 5.0)
        #expect(result.isImproving == false)
        #expect(result.latestPainLevel == 5)
        #expect(result.readingCount == 3)
    }

    @Test func twoLogsImprovingTrend() {
        let logs = makeLogs(levels: [2, 4])
        let result = PainTrendAnalyzer.analyzeTrend(logs: logs)
        #expect(result.trailingAverage == 3.0)
        #expect(result.isImproving == true)
        #expect(result.latestPainLevel == 2)
        #expect(result.readingCount == 2)
    }

    @Test func twoLogsWorseningTrend() {
        let logs = makeLogs(levels: [4, 2])
        let result = PainTrendAnalyzer.analyzeTrend(logs: logs)
        #expect(result.trailingAverage == 3.0)
        #expect(result.isImproving == false)
        #expect(result.latestPainLevel == 4)
        #expect(result.readingCount == 2)
    }

    @Test func improvingTrend() {
        // Newest first: 2, 3, 4, 5, 6, 7, 8 — newer half lower = improving
        let logs = makeLogs(levels: [2, 3, 4, 5, 6, 7, 8])
        let result = PainTrendAnalyzer.analyzeTrend(logs: logs)
        #expect(result.isImproving == true)
        #expect(result.latestPainLevel == 2)
    }

    @Test func worseningTrend() {
        // Newest first: 8, 7, 6, 5, 4, 3, 2 — newer half higher = not improving
        let logs = makeLogs(levels: [8, 7, 6, 5, 4, 3, 2])
        let result = PainTrendAnalyzer.analyzeTrend(logs: logs)
        #expect(result.isImproving == false)
    }

    @Test func hasRecentLogTrue() {
        let logs = makeLogs(levels: [5])
        #expect(PainTrendAnalyzer.hasRecentLog(logs: logs) == true)
    }

    @Test func hasRecentLogFalse() {
        let old = PainLog(
            injuryProfileID: "injury1",
            painLevel: 5,
            recordedAt: Date().addingTimeInterval(-25 * 3600)
        )
        #expect(PainTrendAnalyzer.hasRecentLog(logs: [old]) == false)
    }

    @Test func hasRecentLogEmpty() {
        #expect(PainTrendAnalyzer.hasRecentLog(logs: []) == false)
    }

    @Test func sparklineData() {
        let logs = makeLogs(levels: [3, 5, 7])
        let data = PainTrendAnalyzer.sparklineData(logs: logs, count: 3)
        #expect(data == [7, 5, 3]) // Reversed for display
    }

    @Test func sparklineDataEmpty() {
        let data = PainTrendAnalyzer.sparklineData(logs: [], count: 7)
        #expect(data.isEmpty)
    }
}

// MARK: - LoadAdjustmentPolicy Tests

@Suite("LoadAdjustmentPolicy")
struct LoadAdjustmentPolicyTests {
    @Test func acuteMultipliers() {
        let m = LoadAdjustmentPolicy.multipliers(for: .acute)
        #expect(m.load == 0.0)
        #expect(m.sets == 0.0)
        #expect(m.reps == 0.0)
    }

    @Test func rehabMultipliers() {
        let m = LoadAdjustmentPolicy.multipliers(for: .rehab)
        #expect(m.load == 0.30)
        #expect(m.sets == 0.50)
        #expect(m.reps == 0.70)
    }

    @Test func lightLoadMultipliers() {
        let m = LoadAdjustmentPolicy.multipliers(for: .lightLoad)
        #expect(m.load == 0.50)
        #expect(m.sets == 0.75)
        #expect(m.reps == 0.85)
    }

    @Test func returnToPlayMultipliers() {
        let m = LoadAdjustmentPolicy.multipliers(for: .returnToPlay)
        #expect(m.load == 0.80)
        #expect(m.sets == 0.90)
        #expect(m.reps == 1.0)
    }

    @Test func resolvedMultipliers() {
        let m = LoadAdjustmentPolicy.multipliers(for: .resolved)
        #expect(m.load == 1.0)
        #expect(m.sets == 1.0)
        #expect(m.reps == 1.0)
    }

    @Test func adjustFixedValue() {
        let result = LoadAdjustmentPolicy.adjustValue(.fixed(10), multiplier: 0.5)
        #expect(result.description == "5")
    }

    @Test func adjustFixedMinOne() {
        let result = LoadAdjustmentPolicy.adjustValue(.fixed(1), multiplier: 0.1)
        #expect(result.description == "1")
    }

    @Test func adjustRangeValue() {
        let result = LoadAdjustmentPolicy.adjustValue(.range(8, 12), multiplier: 0.5)
        #expect(result.description == "4–6")
    }

    @Test func adjustAmrapUnchanged() {
        let result = LoadAdjustmentPolicy.adjustValue(.amrap, multiplier: 0.5)
        #expect(result.description == "AMRAP")
    }

    @Test func adjustTextUnchanged() {
        let result = LoadAdjustmentPolicy.adjustValue(.text("custom"), multiplier: 0.5)
        #expect(result.description == "custom")
    }

    @Test func adjustLoadNilReturnsNil() {
        #expect(LoadAdjustmentPolicy.adjustLoad(nil, multiplier: 0.5) == nil)
    }

    @Test func adjustLoadWithValue() {
        #expect(LoadAdjustmentPolicy.adjustLoad(0.80, multiplier: 0.5) == 0.40)
    }

    @Test func applyMultipliersRehab() {
        let ex = ProgramExercise(exercise: "Test", variant: nil, sets: .fixed(4), reps: .fixed(10), percent1RM: 0.80, restMinutes: 2, notes: nil)
        let adjusted = LoadAdjustmentPolicy.applyMultipliers(ex, phase: .rehab)
        #expect(adjusted.sets.description == "2")
        #expect(adjusted.reps.description == "7")
        #expect((adjusted.percent1RM ?? 0) < 0.80)
    }

    @Test func applyMultipliersResolvedUnchanged() {
        let ex = ProgramExercise(exercise: "Test", variant: nil, sets: .fixed(4), reps: .fixed(10), percent1RM: 0.80, restMinutes: 2, notes: nil)
        let adjusted = LoadAdjustmentPolicy.applyMultipliers(ex, phase: .resolved)
        #expect(adjusted.sets.description == "4")
        #expect(adjusted.reps.description == "10")
        #expect(adjusted.percent1RM == 0.80)
    }
}

// MARK: - PhaseTransitionAdvisor Tests

@Suite("PhaseTransitionAdvisor")
struct PhaseTransitionAdvisorTests {
    private func makeLogs(levels: [Int]) -> [PainLog] {
        levels.enumerated().map { (i, level) in
            PainLog(injuryProfileID: "injury1", painLevel: level, recordedAt: Date().addingTimeInterval(-Double(i) * 86400))
        }
    }

    @Test func acuteToRehabSuggested() {
        let logs = makeLogs(levels: [4, 3, 5])
        let suggestion = PhaseTransitionAdvisor.evaluateTransition(injuryID: "i1", currentPhase: .acute, painLogs: logs)
        #expect(suggestion != nil)
        #expect(suggestion?.suggestedPhase == .rehab)
    }

    @Test func acuteToRehabNotReady() {
        let logs = makeLogs(levels: [6, 4, 5])
        let suggestion = PhaseTransitionAdvisor.evaluateTransition(injuryID: "i1", currentPhase: .acute, painLogs: logs)
        #expect(suggestion == nil)
    }

    @Test func rehabToLightLoad() {
        let logs = makeLogs(levels: [2, 3, 2])
        let suggestion = PhaseTransitionAdvisor.evaluateTransition(injuryID: "i1", currentPhase: .rehab, painLogs: logs)
        #expect(suggestion?.suggestedPhase == .lightLoad)
    }

    @Test func lightLoadToReturnToPlay() {
        let logs = makeLogs(levels: [1, 2, 1])
        let suggestion = PhaseTransitionAdvisor.evaluateTransition(injuryID: "i1", currentPhase: .lightLoad, painLogs: logs)
        #expect(suggestion?.suggestedPhase == .returnToPlay)
    }

    @Test func returnToPlayToResolved() {
        let logs = makeLogs(levels: [0, 1, 0, 1, 0])
        let suggestion = PhaseTransitionAdvisor.evaluateTransition(injuryID: "i1", currentPhase: .returnToPlay, painLogs: logs)
        #expect(suggestion?.suggestedPhase == .resolved)
    }

    @Test func returnToPlayNotEnoughLogs() {
        let logs = makeLogs(levels: [0, 1])
        let suggestion = PhaseTransitionAdvisor.evaluateTransition(injuryID: "i1", currentPhase: .returnToPlay, painLogs: logs)
        #expect(suggestion == nil)
    }

    @Test func resolvedReturnsNil() {
        let logs = makeLogs(levels: [0, 0, 0])
        let suggestion = PhaseTransitionAdvisor.evaluateTransition(injuryID: "i1", currentPhase: .resolved, painLogs: logs)
        #expect(suggestion == nil)
    }

    @Test func meetsThresholdEdgeCases() {
        #expect(PhaseTransitionAdvisor.meetsThreshold([], count: 1, maxPain: 5) == false)
        let logs = makeLogs(levels: [5, 5, 5])
        #expect(PhaseTransitionAdvisor.meetsThreshold(logs, count: 3, maxPain: 5) == true)
        #expect(PhaseTransitionAdvisor.meetsThreshold(logs, count: 3, maxPain: 4) == false)
    }
}

// MARK: - RehabSessionGenerator Tests

@Suite("RehabSessionGenerator")
struct RehabSessionGeneratorTests {
    private func makeInjury(location: String, phase: RecoveryPhase = .rehab) -> InjuryProfile {
        let injury = InjuryProfile(id: UUID().uuidString, userID: "u1", location: location)
        injury.recoveryPhase = phase
        return injury
    }

    @Test func generatesSessionForRehabPhase() {
        let session = RehabSessionGenerator.generateSession(injuries: [makeInjury(location: "knee")])
        #expect(session != nil)
        #expect(session!.exercises.count >= 2)
        #expect(session!.sessionType == "recovery")
    }

    @Test func generatesSessionForLightLoadPhase() {
        let session = RehabSessionGenerator.generateSession(injuries: [makeInjury(location: "shoulder", phase: .lightLoad)])
        #expect(session != nil)
    }

    @Test func returnsNilForAcutePhase() {
        let session = RehabSessionGenerator.generateSession(injuries: [makeInjury(location: "knee", phase: .acute)])
        #expect(session == nil)
    }

    @Test func returnsNilForResolvedPhase() {
        let session = RehabSessionGenerator.generateSession(injuries: [makeInjury(location: "knee", phase: .resolved)])
        #expect(session == nil)
    }

    @Test func returnsNilForEmptyInjuries() {
        let session = RehabSessionGenerator.generateSession(injuries: [])
        #expect(session == nil)
    }

    @Test func combinesMultipleInjuries() {
        let injuries = [makeInjury(location: "knee"), makeInjury(location: "shoulder")]
        let session = RehabSessionGenerator.generateSession(injuries: injuries)
        #expect(session != nil)
        #expect(session!.exercises.count >= 4)
    }
}

// MARK: - InjuryAdaptationEngine Extended Tests

@Suite("InjuryAdaptationEngine Extended")
struct InjuryAdaptationEngineExtendedTests {
    private func makeInjury(location: String, phase: RecoveryPhase = .acute) -> InjuryProfile {
        let injury = InjuryProfile(id: UUID().uuidString, userID: "u1", location: location)
        injury.recoveryPhase = phase
        return injury
    }

    private func makeProgram(_ exerciseName: String) -> Program {
        let ex = ProgramExercise(exercise: exerciseName, variant: nil, sets: .fixed(3), reps: .fixed(5), percent1RM: 0.80, restMinutes: 3, notes: nil)
        let session = ProgramSession(sessionID: "s1", sessionName: "Day 1", sessionType: "strength", focus: "Lower", exercises: [ex])
        let week = ProgramWeek(week: 1, phaseID: nil, isTestWeek: nil, sessions: [session])
        return Program(id: "p1", name: "Test", category: "Test", description: "", durationWeeks: 1, sessionsPerWeek: 1, difficulty: "beginner", phases: [], weeks: [week], cycleAdjustmentProfile: nil)
    }

    @Test func normalizedBodyRegionsBasicLocations() {
        let regions = InjuryAdaptationEngine.normalizedBodyRegions(from: [makeInjury(location: "knee")])
        #expect(regions.contains("knee"))
    }

    @Test func normalizedBodyRegionsClinicalSynonyms() {
        let regions = InjuryAdaptationEngine.normalizedBodyRegions(from: [makeInjury(location: "ACL tear")])
        #expect(regions.contains("knee"))
    }

    @Test func normalizedBodyRegionsRotatorCuff() {
        let regions = InjuryAdaptationEngine.normalizedBodyRegions(from: [makeInjury(location: "rotator cuff")])
        #expect(regions.contains("shoulder"))
    }

    @Test func normalizedBodyRegionsLumbar() {
        let regions = InjuryAdaptationEngine.normalizedBodyRegions(from: [makeInjury(location: "lumbar disc")])
        #expect(regions.contains("back"))
    }

    @Test func normalizedBodyRegionsMultiple() {
        let injuries = [makeInjury(location: "knee"), makeInjury(location: "shoulder")]
        let regions = InjuryAdaptationEngine.normalizedBodyRegions(from: injuries)
        #expect(regions.contains("knee"))
        #expect(regions.contains("shoulder"))
    }

    @Test func resolvedInjuriesIgnored() {
        let program = makeProgram("Back Squat")
        let resolved = makeInjury(location: "knee", phase: .resolved)
        let adapted = InjuryAdaptationEngine.adaptProgram(program, activeInjuries: [resolved])
        let exercise = adapted.weeks.first?.sessions.first?.exercises.first?.exercise ?? ""
        #expect(exercise == "Back Squat")
    }

    @Test func rehabPhaseAddsRecoveryPrepBlock() {
        let program = makeProgram("Back Squat")
        let rehab = makeInjury(location: "knee", phase: .rehab)
        let adapted = InjuryAdaptationEngine.adaptProgram(program, activeInjuries: [rehab])
        // Should have more exercises than original due to recovery prep block
        let exercises = adapted.weeks.first?.sessions.first?.exercises ?? []
        #expect(exercises.count > 1)
    }

    @Test func returnToPlayAddsWarmupOnly() {
        let program = makeProgram("Back Squat")
        let rtp = makeInjury(location: "knee", phase: .returnToPlay)
        let adapted = InjuryAdaptationEngine.adaptProgram(program, activeInjuries: [rtp])
        let exercises = adapted.weeks.first?.sessions.first?.exercises ?? []
        // returnToPlay: no replacement but adds warmup
        #expect(exercises.count > 1)
        // The original exercise should still be there (last one)
        #expect(exercises.last?.exercise == "Back Squat")
    }

    @Test func adaptProgramWithMetadataTracksReplacements() {
        let program = makeProgram("Romanian Deadlift (No Straps)")
        let result = InjuryAdaptationEngine.adaptProgramWithMetadata(program, activeInjuries: [makeInjury(location: "back")])
        #expect(!result.adaptedExercises.isEmpty)
    }

    @Test func adaptProgramWithMetadataNoInjuries() {
        let program = makeProgram("Back Squat")
        let result = InjuryAdaptationEngine.adaptProgramWithMetadata(program, activeInjuries: [])
        #expect(result.adaptedExercises.isEmpty)
        #expect(result.program.weeks.first?.sessions.first?.exercises.first?.exercise == "Back Squat")
    }

    @Test func mostRestrictivePhase() {
        let result = InjuryAdaptationEngine.mostRestrictive(phases: [.rehab, .lightLoad, .returnToPlay])
        #expect(result == .rehab)
    }

    @Test func mostRestrictivePhaseEmpty() {
        let result = InjuryAdaptationEngine.mostRestrictive(phases: [])
        #expect(result == nil)
    }

    @Test func mostRestrictivePhaseSingle() {
        let result = InjuryAdaptationEngine.mostRestrictive(phases: [.resolved])
        #expect(result == .resolved)
    }
}

// MARK: - PainLog Model Tests

@Suite("PainLog Model")
struct PainLogModelTests {
    @Test func initDefaults() {
        let log = PainLog(injuryProfileID: "i1", painLevel: 5)
        #expect(log.injuryProfileID == "i1")
        #expect(log.painLevel == 5)
        #expect(log.workoutID == nil)
        #expect(log.notes == nil)
        #expect(log.triggerExercise == nil)
        #expect(log.symptomType == nil)
        #expect(log.intensityContext == nil)
    }

    @Test func initWithTriggerFields() {
        let log = PainLog(
            injuryProfileID: "i1",
            painLevel: 7,
            triggerExercise: "Back Squat",
            symptomType: .sharp,
            intensityContext: .duringWorkSet
        )
        #expect(log.triggerExercise == "Back Squat")
        #expect(log.symptomType == .sharp)
        #expect(log.intensityContext == .duringWorkSet)
        #expect(log.symptomTypeRaw == "sharp")
        #expect(log.intensityContextRaw == "during_work_set")
    }

    @Test func symptomTypeSetterGetter() {
        let log = PainLog(injuryProfileID: "i1", painLevel: 5)
        log.symptomType = .stiffness
        #expect(log.symptomTypeRaw == "stiffness")
        #expect(log.symptomType == .stiffness)
        log.symptomType = nil
        #expect(log.symptomTypeRaw == nil)
    }

    @Test func intensityContextSetterGetter() {
        let log = PainLog(injuryProfileID: "i1", painLevel: 5)
        log.intensityContext = .postWorkout
        #expect(log.intensityContextRaw == "post_workout")
        #expect(log.intensityContext == .postWorkout)
    }
}

// MARK: - SymptomType & IntensityContext Tests

@Suite("SymptomType")
struct SymptomTypeTests {
    @Test func allCases() {
        #expect(SymptomType.allCases.count == 4)
    }

    @Test func displayNames() {
        #expect(SymptomType.sharp.displayName == "Sharp")
        #expect(SymptomType.dull.displayName == "Dull")
        #expect(SymptomType.stiffness.displayName == "Stiffness")
        #expect(SymptomType.instability.displayName == "Instability")
    }
}

@Suite("IntensityContext")
struct IntensityContextTests {
    @Test func allCases() {
        #expect(IntensityContext.allCases.count == 3)
    }

    @Test func displayNames() {
        #expect(IntensityContext.duringWarmup.displayName == "During Warmup")
        #expect(IntensityContext.duringWorkSet.displayName == "During Work Set")
        #expect(IntensityContext.postWorkout.displayName == "Post Workout")
    }

    @Test func rawValues() {
        #expect(IntensityContext.duringWarmup.rawValue == "during_warmup")
        #expect(IntensityContext.duringWorkSet.rawValue == "during_work_set")
        #expect(IntensityContext.postWorkout.rawValue == "post_workout")
    }
}

// MARK: - InjuryProfile Extended Tests

@Suite("InjuryProfile Extended")
struct InjuryProfileExtendedTests {
    @Test func recoveryPhaseDefaultsToAcute() {
        let injury = InjuryProfile(id: "i1", userID: "u1")
        #expect(injury.recoveryPhase == .acute)
        #expect(injury.recoveryPhaseRaw == "acute")
    }

    @Test func recoveryPhaseSetterGetter() {
        let injury = InjuryProfile(id: "i1", userID: "u1")
        injury.recoveryPhase = .rehab
        #expect(injury.recoveryPhaseRaw == "rehab")
        #expect(injury.recoveryPhase == .rehab)
    }

    @Test func isActiveDerivedFromRecoveryPhase() {
        let injury = InjuryProfile(id: "i1", userID: "u1")
        #expect(injury.isActive == true)
        injury.recoveryPhase = .rehab
        #expect(injury.isActive == true)
        injury.recoveryPhase = .lightLoad
        #expect(injury.isActive == true)
        injury.recoveryPhase = .returnToPlay
        #expect(injury.isActive == true)
        injury.recoveryPhase = .resolved
        #expect(injury.isActive == false)
    }

    @Test func locationRegionsDefaultsEmpty() {
        let injury = InjuryProfile(id: "i1", userID: "u1")
        #expect(injury.locationRegions.isEmpty)
        #expect(injury.locationRegionsRaw == "")
    }

    @Test func locationRegionsSetterGetter() {
        let injury = InjuryProfile(id: "i1", userID: "u1")
        injury.locationRegions = [.leftKnee, .rightShoulder]
        #expect(injury.locationRegionsRaw.contains("leftKnee"))
        #expect(injury.locationRegionsRaw.contains("rightShoulder"))
        #expect(injury.locationRegions.count == 2)
    }

    @Test func invalidRecoveryPhaseRawDefaultsToAcute() {
        let injury = InjuryProfile(id: "i1", userID: "u1")
        injury.recoveryPhaseRaw = "invalid"
        #expect(injury.recoveryPhase == .acute)
    }
}

// MARK: - ReadinessMetrics Tests

@Suite("ReadinessMetrics")
struct ReadinessMetricsTests {
    @Test func allNilsReturnNilScore() {
        let metrics = ReadinessMetrics(sleepHours: nil, hrvRMSSD: nil, restingHeartRate: nil)
        #expect(metrics.readinessScore == nil)
    }

    @Test func sleepOnlyScore() {
        let metrics = ReadinessMetrics(sleepHours: 8.0, hrvRMSSD: nil, restingHeartRate: nil)
        let score = metrics.readinessScore
        #expect(score != nil)
        #expect(score! > 0)
    }

    @Test func hrvOnlyScore() {
        let metrics = ReadinessMetrics(sleepHours: nil, hrvRMSSD: 60.0, restingHeartRate: nil)
        let score = metrics.readinessScore
        #expect(score != nil)
        #expect(score! > 0)
    }

    @Test func rhrOnlyScore() {
        let metrics = ReadinessMetrics(sleepHours: nil, hrvRMSSD: nil, restingHeartRate: 60.0)
        let score = metrics.readinessScore
        #expect(score != nil)
        #expect(score! > 0)
    }

    @Test func allMetricsScore() {
        let metrics = ReadinessMetrics(sleepHours: 8.0, hrvRMSSD: 60.0, restingHeartRate: 60.0)
        let score = metrics.readinessScore
        #expect(score != nil)
        #expect(score! > 5.0)
    }

    @Test func poorMetricsLowScore() {
        let metrics = ReadinessMetrics(sleepHours: 3.0, hrvRMSSD: 10.0, restingHeartRate: 90.0)
        let score = metrics.readinessScore
        #expect(score != nil)
        #expect(score! < 5.0)
    }
}
