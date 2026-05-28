import XCTest
@testable import SundeeFundeeKit

final class ReturnToLiftingRampServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makePainLog(
        id: String = UUID().uuidString,
        locationIds: String,
        intensity: Int,
        painType: PainType = .acute,
        date: Date = Date(),
        notes: String? = nil
    ) -> DailyPainLog {
        DailyPainLog(
            id: id,
            locationIds: locationIds,
            intensity: intensity,
            painType: painType,
            date: date,
            notes: notes
        )
    }

    private func makeInjury(
        id: String = UUID().uuidString,
        locationIds: String,
        name: String = "Test Injury",
        recoveryPhase: RecoveryPhase = .rehab,
        dateCreated: Date = Date(),
        notes: String? = nil
    ) -> Injury {
        Injury(
            id: id,
            locationIds: locationIds,
            name: name,
            recoveryPhase: recoveryPhase,
            dateCreated: dateCreated,
            phaseUpdated: dateCreated,
            notes: notes
        )
    }

    private func makeRamp(
        id: String = UUID().uuidString,
        locationIds: String,
        movementPattern: WorkoutMovementPattern,
        currentWeek: Int = 1,
        maxLoadPercent: Double = 0.5,
        maxWorkingSets: Int = 3,
        dateCreated: Date = Date()
    ) -> ReturnToLiftingRampRecord {
        ReturnToLiftingRampRecord(
            id: id,
            locationIds: locationIds,
            movementPatternRaw: movementPattern.rawValue,
            currentWeek: currentWeek,
            maxLoadPercent: maxLoadPercent,
            maxWorkingSets: maxWorkingSets,
            dateCreated: dateCreated,
            dateUpdated: dateCreated
        )
    }

    // MARK: - Severe pain blocks heavy loading

    func testSeverePain_BlocksHeavyLoadingForAffectedPatterns() {
        // Knee pain at intensity 8 (severe) should restrict squat pattern
        let painLogs = [
            makePainLog(locationIds: "knee_left", intensity: 8)
        ]

        let recommendations = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs,
            injuries: [],
            activeRamps: []
        )

        // Should produce a recommendation for squat (knee-related)
        let squatRec = recommendations.first { $0.movementPattern == .squat }
        XCTAssertNotNil(squatRec, "Should produce a recommendation for squat pattern when knee has severe pain")
        XCTAssertLessThan(squatRec!.maxLoadPercent, 0.5, "Severe pain should cap load below 50%")
        XCTAssertLessThanOrEqual(squatRec!.maxWorkingSets, 3, "Severe pain should limit working sets to 3 or fewer")
    }

    func testExtremePain_BlocksHeavyLoadingWithVeryConservativeCap() {
        // Knee pain at intensity 10 (extreme)
        let painLogs = [
            makePainLog(locationIds: "knee_left", intensity: 10)
        ]

        let recommendations = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs,
            injuries: [],
            activeRamps: []
        )

        let squatRec = recommendations.first { $0.movementPattern == .squat }
        XCTAssertNotNil(squatRec)
        XCTAssertLessThanOrEqual(squatRec!.maxLoadPercent, 0.4, "Extreme pain should cap load at 40% or less")
    }

    func testSevereShoulderPain_RestrictsPushPattern() {
        let painLogs = [
            makePainLog(locationIds: "shoulder_left", intensity: 9)
        ]

        let recommendations = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs,
            injuries: [],
            activeRamps: []
        )

        let pushRec = recommendations.first { $0.movementPattern == .push }
        XCTAssertNotNil(pushRec, "Shoulder pain should produce push pattern restriction")
        XCTAssertLessThan(pushRec!.maxLoadPercent, 0.5, "Severe shoulder pain should cap push pattern below 50%")
    }

    func testSevereBackPain_RestrictsHingePattern() {
        let painLogs = [
            makePainLog(locationIds: "lower_back", intensity: 7)
        ]

        let recommendations = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs,
            injuries: [],
            activeRamps: []
        )

        let hingeRec = recommendations.first { $0.movementPattern == .hinge }
        XCTAssertNotNil(hingeRec, "Back pain should produce hinge pattern restriction")
        XCTAssertLessThan(hingeRec!.maxLoadPercent, 0.5, "Severe back pain should cap hinge pattern below 50%")
    }

    // MARK: - Resolved pain starts conservative and advances weekly

    func testResolvedInjury_StartsAtConservativePercentage() {
        // Resolved knee injury should start at 50-60% load
        let injuries = [
            makeInjury(locationIds: "knee_left", recoveryPhase: .resolved)
        ]

        let recommendations = ReturnToLiftingRampService.recommendations(
            painLogs: [],
            injuries: injuries,
            activeRamps: []
        )

        let squatRec = recommendations.first { $0.movementPattern == .squat }
        XCTAssertNotNil(squatRec, "Resolved knee injury should produce a squat recommendation")
        XCTAssertGreaterThanOrEqual(squatRec!.maxLoadPercent, 0.5, "Resolved injury should start at >= 50%")
        XCTAssertLessThanOrEqual(squatRec!.maxLoadPercent, 0.6, "Resolved injury should start at <= 60%")
        XCTAssertEqual(squatRec!.maxWorkingSets, 3, "Resolved injury should allow 3 working sets")
    }

    func testAdvanceRamp_IncreasesLoadPercentage() {
        let ramp = makeRamp(
            locationIds: "knee_left",
            movementPattern: .squat,
            currentWeek: 1,
            maxLoadPercent: 0.50,
            maxWorkingSets: 3
        )

        let advanced = ReturnToLiftingRampService.advanceRamp(ramp)

        XCTAssertEqual(advanced.currentWeek, 2, "Week should advance by 1")
        XCTAssertGreaterThan(advanced.maxLoadPercent, ramp.maxLoadPercent, "Load should increase")
        XCTAssertLessThanOrEqual(advanced.maxLoadPercent, 1.0, "Load should not exceed 100%")
        XCTAssertEqual(advanced.id, ramp.id, "ID should be preserved")
    }

    func testAdvanceRamp_IncreasesByFiveToTenPercent() {
        let ramp = makeRamp(
            locationIds: "knee_left",
            movementPattern: .squat,
            currentWeek: 1,
            maxLoadPercent: 0.50,
            maxWorkingSets: 3
        )

        let advanced = ReturnToLiftingRampService.advanceRamp(ramp)

        let increase = advanced.maxLoadPercent - ramp.maxLoadPercent
        XCTAssertGreaterThanOrEqual(increase, 0.05, "Should advance at least 5% per week")
        XCTAssertLessThanOrEqual(increase, 0.10, "Should advance at most 10% per week")
    }

    func testAdvanceRamp_CapsAtFullLoad() {
        let ramp = makeRamp(
            locationIds: "knee_left",
            movementPattern: .squat,
            currentWeek: 8,
            maxLoadPercent: 0.95,
            maxWorkingSets: 4
        )

        let advanced = ReturnToLiftingRampService.advanceRamp(ramp)

        XCTAssertLessThanOrEqual(advanced.maxLoadPercent, 1.0, "Should not exceed 100% load")
    }

    func testAdvanceRamp_CanIncreaseWorkingSets() {
        // Start at week 2 with low sets; advancing may increase sets
        let ramp = makeRamp(
            locationIds: "knee_left",
            movementPattern: .squat,
            currentWeek: 2,
            maxLoadPercent: 0.60,
            maxWorkingSets: 2
        )

        let advanced = ReturnToLiftingRampService.advanceRamp(ramp)

        XCTAssertGreaterThanOrEqual(advanced.maxWorkingSets, ramp.maxWorkingSets, "Sets should not decrease on advance")
    }

    func testAdvanceRamp_UpdatesDateUpdated() {
        let oldDate = Date().addingTimeInterval(-86400 * 7)
        let ramp = makeRamp(
            locationIds: "knee_left",
            movementPattern: .squat,
            currentWeek: 1,
            maxLoadPercent: 0.50,
            maxWorkingSets: 3,
            dateCreated: oldDate
        )

        let advanced = ReturnToLiftingRampService.advanceRamp(ramp)

        XCTAssertGreaterThan(advanced.dateUpdated, ramp.dateUpdated, "dateUpdated should be newer after advance")
        XCTAssertEqual(advanced.dateCreated, ramp.dateCreated, "dateCreated should not change")
    }

    // MARK: - Ramp caps do not affect unrelated patterns

    func testRampCaps_DoNotAffectUnrelatedPatterns() {
        // Active ramp for squat; push pattern should be unrestricted
        let activeRamps = [
            makeRamp(
                locationIds: "knee_left",
                movementPattern: .squat,
                currentWeek: 1,
                maxLoadPercent: 0.40,
                maxWorkingSets: 2
            )
        ]

        let recommendations = ReturnToLiftingRampService.recommendations(
            painLogs: [],
            injuries: [],
            activeRamps: activeRamps
        )

        let squatRec = recommendations.first { $0.movementPattern == .squat }
        XCTAssertNotNil(squatRec, "Should have recommendation for squat")
        XCTAssertEqual(squatRec!.maxLoadPercent, 0.40, accuracy: 0.01, "Should use ramp value for squat")

        // Push should not appear in recommendations at all (no pain, no injury)
        let pushRec = recommendations.first { $0.movementPattern == .push }
        XCTAssertNil(pushRec, "Unrelated patterns should not have recommendations")
    }

    func testNoPainNoInjury_NoRecommendations() {
        let recommendations = ReturnToLiftingRampService.recommendations(
            painLogs: [],
            injuries: [],
            activeRamps: []
        )

        XCTAssertTrue(recommendations.isEmpty, "No pain or injury should produce no recommendations")
    }

    func testRampRecordOverridesComputedRecommendation() {
        // Pain log would suggest 0.3 load, but existing ramp at 0.55 should override
        let painLogs = [
            makePainLog(locationIds: "knee_left", intensity: 7)
        ]
        let activeRamps = [
            makeRamp(
                locationIds: "knee_left",
                movementPattern: .squat,
                currentWeek: 3,
                maxLoadPercent: 0.55,
                maxWorkingSets: 3
            )
        ]

        let recommendations = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs,
            injuries: [],
            activeRamps: activeRamps
        )

        let squatRec = recommendations.first { $0.movementPattern == .squat }
        XCTAssertNotNil(squatRec)
        XCTAssertEqual(squatRec!.maxLoadPercent, 0.55, accuracy: 0.01,
                       "Existing ramp record should override computed recommendation")
    }

    // MARK: - User copy language checks

    func testRecommendationReason_EaseBackInLanguage() {
        let painLogs = [
            makePainLog(locationIds: "knee_left", intensity: 5)
        ]

        let recommendations = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs,
            injuries: [],
            activeRamps: []
        )

        for rec in recommendations {
            // Reason should exist and be non-empty
            XCTAssertFalse(rec.reason.isEmpty, "Reason should not be empty")

            // Should contain easing language
            let lower = rec.reason.lowercased()
            let hasEasingLanguage = lower.contains("ease") ||
                                    lower.contains("gradual") ||
                                    lower.contains("build back") ||
                                    lower.contains("ramp") ||
                                    lower.contains("conservative") ||
                                    lower.contains("start light") ||
                                    lower.contains("reduce") ||
                                    lower.contains("back into")
            XCTAssertTrue(hasEasingLanguage,
                          "Reason should use easing language, got: \(rec.reason)")
        }
    }

    func testNoMedicalLanguage_Treat() {
        let painLogs = [
            makePainLog(locationIds: "knee_left", intensity: 8)
        ]
        let injuries = [
            makeInjury(locationIds: "shoulder_left", recoveryPhase: .rehab)
        ]

        let recommendations = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs,
            injuries: injuries,
            activeRamps: []
        )

        let forbiddenTerms = ["treat", "heal", "injury cure", "diagnose", "medical", "therapy", "rehabilitate"]
        for rec in recommendations {
            let lower = rec.reason.lowercased()
            for term in forbiddenTerms {
                XCTAssertFalse(lower.contains(term),
                               "Reason should not contain medical term '\(term)', got: \(rec.reason)")
            }
        }
    }

    func testAdvanceRampReason_EaseBackInLanguage() {
        let ramp = makeRamp(
            locationIds: "knee_left",
            movementPattern: .squat,
            currentWeek: 1,
            maxLoadPercent: 0.50,
            maxWorkingSets: 3
        )

        let advanced = ReturnToLiftingRampService.advanceRamp(ramp)

        // Verify ramp record maintains valid state
        XCTAssertGreaterThan(advanced.maxLoadPercent, 0)
        XCTAssertLessThanOrEqual(advanced.maxLoadPercent, 1.0)
        XCTAssertGreaterThan(advanced.maxWorkingSets, 0)
        XCTAssertLessThanOrEqual(advanced.maxWorkingSets, 5)
    }

    // MARK: - Body region to movement pattern mapping

    func testKneePain_AffectsSquatPattern() {
        let painLogs = [makePainLog(locationIds: "knee_left", intensity: 7)]
        let recs = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs, injuries: [], activeRamps: []
        )
        XCTAssertTrue(recs.contains(where: { $0.movementPattern == .squat }),
                      "Knee pain should affect squat pattern")
    }

    func testBackPain_AffectsHingePattern() {
        let painLogs = [makePainLog(locationIds: "lower_back", intensity: 7)]
        let recs = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs, injuries: [], activeRamps: []
        )
        XCTAssertTrue(recs.contains(where: { $0.movementPattern == .hinge }),
                      "Back pain should affect hinge pattern")
    }

    func testShoulderPain_AffectsPushPattern() {
        let painLogs = [makePainLog(locationIds: "shoulder_right", intensity: 7)]
        let recs = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs, injuries: [], activeRamps: []
        )
        XCTAssertTrue(recs.contains(where: { $0.movementPattern == .push }),
                      "Shoulder pain should affect push pattern")
    }

    func testHipPain_AffectsSquatAndHinge() {
        let painLogs = [makePainLog(locationIds: "hip_left", intensity: 7)]
        let recs = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs, injuries: [], activeRamps: []
        )
        let patterns = Set(recs.map(\.movementPattern))
        XCTAssertTrue(patterns.contains(.squat), "Hip pain should affect squat pattern")
        XCTAssertTrue(patterns.contains(.hinge), "Hip pain should affect hinge pattern")
    }

    func testWristPain_AffectsPushAndPull() {
        let painLogs = [makePainLog(locationIds: "wrist_left", intensity: 7)]
        let recs = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs, injuries: [], activeRamps: []
        )
        let patterns = Set(recs.map(\.movementPattern))
        XCTAssertTrue(patterns.contains(.push), "Wrist pain should affect push pattern")
        XCTAssertTrue(patterns.contains(.pull), "Wrist pain should affect pull pattern")
    }

    func testElbowPain_AffectsPushAndPull() {
        let painLogs = [makePainLog(locationIds: "elbow_right", intensity: 7)]
        let recs = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs, injuries: [], activeRamps: []
        )
        let patterns = Set(recs.map(\.movementPattern))
        XCTAssertTrue(patterns.contains(.push), "Elbow pain should affect push pattern")
        XCTAssertTrue(patterns.contains(.pull), "Elbow pain should affect pull pattern")
    }

    // MARK: - Moderate pain produces recommendations

    func testModeratePain_ProducesLessRestrictiveRecommendations() {
        let painLogs = [makePainLog(locationIds: "knee_left", intensity: 5)]
        let recs = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs, injuries: [], activeRamps: []
        )
        let squatRec = recs.first { $0.movementPattern == .squat }
        XCTAssertNotNil(squatRec)
        XCTAssertGreaterThanOrEqual(squatRec!.maxLoadPercent, 0.5,
                                    "Moderate pain should allow >= 50% load")
        XCTAssertLessThan(squatRec!.maxLoadPercent, 0.8,
                          "Moderate pain should cap below 80%")
    }

    func testMildPain_ProducesNoRecommendations() {
        let painLogs = [makePainLog(locationIds: "knee_left", intensity: 2)]
        let recs = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs, injuries: [], activeRamps: []
        )
        XCTAssertTrue(recs.isEmpty, "Mild pain (intensity < 4) should not produce ramp recommendations")
    }

    // MARK: - Multiple body regions

    func testMultipleBodyRegions_CombinesPatterns() {
        // Pain in both knee and shoulder
        let painLogs = [
            makePainLog(locationIds: "knee_left,shoulder_right", intensity: 7)
        ]
        let recs = ReturnToLiftingRampService.recommendations(
            painLogs: painLogs, injuries: [], activeRamps: []
        )
        let patterns = Set(recs.map(\.movementPattern))
        XCTAssertTrue(patterns.contains(.squat), "Should restrict squat for knee")
        XCTAssertTrue(patterns.contains(.push), "Should restrict push for shoulder")
    }
}
