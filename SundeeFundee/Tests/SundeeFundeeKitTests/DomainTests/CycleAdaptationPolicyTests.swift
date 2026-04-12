import XCTest
@testable import SundeeFundeeKit

final class CycleAdaptationPolicyTests: XCTestCase {

    // MARK: - Phase Multipliers

    func testPhaseMultipliers_Menstrual() {
        let m = phaseMultipliers[.menstrual]!
        XCTAssertEqual(m.load, 0.90, accuracy: 0.01)
        XCTAssertEqual(m.sets, 0.90, accuracy: 0.01)
        XCTAssertEqual(m.reps, 0.90, accuracy: 0.01)
    }

    func testPhaseMultipliers_Follicular() {
        let m = phaseMultipliers[.follicular]!
        XCTAssertEqual(m.load, 1.00, accuracy: 0.01)
        XCTAssertEqual(m.sets, 1.00, accuracy: 0.01)
        XCTAssertEqual(m.reps, 1.00, accuracy: 0.01)
    }

    func testPhaseMultipliers_Ovulation() {
        let m = phaseMultipliers[.ovulation]!
        XCTAssertEqual(m.load, 1.12, accuracy: 0.01)
        XCTAssertEqual(m.sets, 1.05, accuracy: 0.01)
        XCTAssertEqual(m.reps, 0.95, accuracy: 0.01)
    }

    func testPhaseMultipliers_Luteal() {
        let m = phaseMultipliers[.luteal]!
        XCTAssertEqual(m.load, 0.97, accuracy: 0.01)
        XCTAssertEqual(m.sets, 0.95, accuracy: 0.01)
        XCTAssertEqual(m.reps, 0.92, accuracy: 0.01)
    }

    // MARK: - resolveReadinessTier

    func testReadinessTier_Low() {
        XCTAssertEqual(resolveReadinessTier(score: 1), .low)
        XCTAssertEqual(resolveReadinessTier(score: 3), .low)
        XCTAssertEqual(resolveReadinessTier(score: 0), .low)
    }

    func testReadinessTier_High() {
        XCTAssertEqual(resolveReadinessTier(score: 8), .high)
        XCTAssertEqual(resolveReadinessTier(score: 10), .high)
    }

    func testReadinessTier_Neutral() {
        XCTAssertEqual(resolveReadinessTier(score: 4), .neutral)
        XCTAssertEqual(resolveReadinessTier(score: 5), .neutral)
        XCTAssertEqual(resolveReadinessTier(score: 7), .neutral)
    }

    func testReadinessTier_Nil() {
        XCTAssertEqual(resolveReadinessTier(score: nil), .neutral)
    }

    // MARK: - resolveConfidence

    func testConfidence_ZeroLogs_Low() {
        XCTAssertEqual(resolveConfidence(currentPhase: nil, lastKnownPhase: nil, periodLogCount: 0, lastPeriodStart: nil), .low)
    }

    func testConfidence_HighWith3PlusLogs() {
        XCTAssertEqual(resolveConfidence(currentPhase: .follicular, lastKnownPhase: nil, periodLogCount: 3, lastPeriodStart: Date()), .high)
    }

    func testConfidence_MediumWithFewerLogs() {
        XCTAssertEqual(resolveConfidence(currentPhase: .follicular, lastKnownPhase: nil, periodLogCount: 2, lastPeriodStart: Date()), .medium)
    }

    func testConfidence_MediumForStaleData() {
        let old = Date().addingTimeInterval(-61 * 86400)
        XCTAssertEqual(resolveConfidence(currentPhase: .follicular, lastKnownPhase: nil, periodLogCount: 5, lastPeriodStart: old), .medium)
    }

    func testConfidence_LowWithNoPhase() {
        XCTAssertEqual(resolveConfidence(currentPhase: nil, lastKnownPhase: nil, periodLogCount: 2, lastPeriodStart: Date()), .low)
    }

    // MARK: - applyPhaseAdjustment

    func testApplyPhaseAdjustment_Follicular_Neutral_High_NoChange() {
        let result = applyPhaseAdjustment(
            sets: .fixed(value: 4),
            reps: .fixed(value: 8),
            percent1RM: 0.75,
            phase: .follicular,
            readinessTier: .neutral,
            confidence: .high
        )
        // Follicular is 1.0 for all, so blendMultiplier = 1.0 + (1.0 - 1.0) * 1.0 * 1.0 = 1.0
        XCTAssertEqual(result.sets, .fixed(value: 4))
        XCTAssertEqual(result.reps, .fixed(value: 8))
        XCTAssertEqual(result.percent1RM!, 0.75, accuracy: 0.01)
    }

    func testApplyPhaseAdjustment_Menstrual_LowReadiness() {
        let result = applyPhaseAdjustment(
            sets: .fixed(value: 5),
            reps: .fixed(value: 10),
            percent1RM: 0.80,
            phase: .menstrual,
            readinessTier: .low,
            confidence: .high
        )
        // Menstrual load = 0.90. blendMultiplier = 1.0 + (0.90 - 1.0) * 0.6 * 1.0 = 0.94
        // Sets/reps should be reduced
        if case .fixed(let v) = result.sets {
            XCTAssertLessThanOrEqual(v, 5)
        }
        if case .fixed(let v) = result.reps {
            XCTAssertLessThanOrEqual(v, 10)
        }
    }

    func testApplyPhaseAdjustment_NilPercent1RM() {
        let result = applyPhaseAdjustment(
            sets: .fixed(value: 3),
            reps: .fixed(value: 8),
            percent1RM: nil,
            phase: .ovulation,
            readinessTier: .high,
            confidence: .high
        )
        XCTAssertNil(result.percent1RM)
    }

    // MARK: - Exercise Region Classification

    func testClassifyExerciseRegion_LowerBody() {
        XCTAssertEqual(classifyExerciseRegion("Back Squat"), .lower)
        XCTAssertEqual(classifyExerciseRegion("Conventional Deadlift (No Straps)"), .lower)
        XCTAssertEqual(classifyExerciseRegion("Leg Press"), .lower)
        XCTAssertEqual(classifyExerciseRegion("Hip Thrust"), .lower)
    }

    func testClassifyExerciseRegion_UpperBody() {
        XCTAssertEqual(classifyExerciseRegion("Flat Barbell Bench Press"), .upper)
        XCTAssertEqual(classifyExerciseRegion("Barbell Row"), .upper)
        XCTAssertEqual(classifyExerciseRegion("Pull-Up"), .upper)
        XCTAssertEqual(classifyExerciseRegion("Dumbbell Overhead Press"), .upper)
    }

    func testClassifyExerciseRegion_Core() {
        XCTAssertEqual(classifyExerciseRegion("Plank Hold"), .core)
        XCTAssertEqual(classifyExerciseRegion("V-up"), .core)
    }

    // MARK: - Region-Specific Multipliers

    func testApplyPhaseAdjustment_LowerBody_MenstrualPhase_BiggerReduction() {
        let lowerResult = applyPhaseAdjustment(
            sets: .fixed(value: 4),
            reps: .fixed(value: 8),
            percent1RM: 0.80,
            phase: .menstrual,
            readinessTier: .neutral,
            confidence: .high,
            exerciseRegion: .lower
        )
        let upperResult = applyPhaseAdjustment(
            sets: .fixed(value: 4),
            reps: .fixed(value: 8),
            percent1RM: 0.80,
            phase: .menstrual,
            readinessTier: .neutral,
            confidence: .high,
            exerciseRegion: .upper
        )
        // Lower body should get a bigger reduction during menstrual phase
        XCTAssertLessThan(lowerResult.percent1RM!, upperResult.percent1RM!,
                          "Lower body should have bigger menstrual reduction than upper body")
    }

    func testApplyPhaseAdjustment_UpperBody_MenstrualPhase_SmallerReduction() {
        let upperResult = applyPhaseAdjustment(
            sets: .fixed(value: 4),
            reps: .fixed(value: 8),
            percent1RM: 0.80,
            phase: .menstrual,
            readinessTier: .neutral,
            confidence: .high,
            exerciseRegion: .upper
        )
        let defaultResult = applyPhaseAdjustment(
            sets: .fixed(value: 4),
            reps: .fixed(value: 8),
            percent1RM: 0.80,
            phase: .menstrual,
            readinessTier: .neutral,
            confidence: .high
        )
        // Upper body should have a smaller reduction than the default
        XCTAssertGreaterThan(upperResult.percent1RM!, defaultResult.percent1RM!,
                             "Upper body should have smaller menstrual reduction than default")
    }

    // MARK: - Phase Transition Blending

    func testBlendedMultiplier_AtPhaseBoundary_Interpolates() {
        let settings = CycleSettings()
        let boundaries = getPhaseBoundaries(settings: settings)
        let follicularEnd = boundaries[.follicular]!.end

        // At the end of follicular (transition to ovulation), should blend
        let blended = blendedMultiplier(
            phase: .follicular,
            cycleDay: follicularEnd,
            settings: settings
        )
        let follicular = resolvePhaseMultipliers(phase: .follicular)
        let ovulation = resolvePhaseMultipliers(phase: .ovulation)

        // Blended load should be between follicular (1.0) and ovulation (1.12)
        XCTAssertGreaterThan(blended.load, follicular.load,
                             "Blended load at transition should be above follicular")
        XCTAssertLessThan(blended.load, ovulation.load,
                          "Blended load at transition should be below ovulation")
    }

    func testBlendedMultiplier_MidPhase_UsesExactMultiplier() {
        let settings = CycleSettings()
        let boundaries = getPhaseBoundaries(settings: settings)
        let follicularMid = (boundaries[.follicular]!.start + boundaries[.follicular]!.end) / 2

        let result = blendedMultiplier(
            phase: .follicular,
            cycleDay: follicularMid,
            settings: settings
        )
        let expected = resolvePhaseMultipliers(phase: .follicular)

        // Mid-phase should use exact multipliers, no blending
        XCTAssertEqual(result.load, expected.load, accuracy: 0.001)
        XCTAssertEqual(result.sets, expected.sets, accuracy: 0.001)
        XCTAssertEqual(result.reps, expected.reps, accuracy: 0.001)
    }
}
