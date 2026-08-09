import XCTest
@testable import SundeeFundeeKit

/// Tests for the non-injury return paths added to `ReturnToLiftingRampService`.
///
/// Kept separate from `ReturnToLiftingRampServiceTests` so that file stays
/// untouched — the requirement for this change is that existing injury
/// behavior does not move, and an unmodified test file is the evidence.
final class ReturnToLiftingRampBreakReasonTests: XCTestCase {

    // MARK: - Helpers

    private func makePainLog(
        locationIds: String,
        intensity: Int,
        date: Date = Date()
    ) -> DailyPainLog {
        DailyPainLog(
            id: UUID().uuidString,
            locationIds: locationIds,
            intensity: intensity,
            painType: .acute,
            date: date,
            notes: nil
        )
    }

    private func makeRamp(
        locationIds: String,
        movementPattern: WorkoutMovementPattern,
        currentWeek: Int = 5,
        maxLoadPercent: Double = 0.80,
        maxWorkingSets: Int = 4
    ) -> ReturnToLiftingRampRecord {
        ReturnToLiftingRampRecord(
            id: UUID().uuidString,
            locationIds: locationIds,
            movementPatternRaw: movementPattern.rawValue,
            currentWeek: currentWeek,
            maxLoadPercent: maxLoadPercent,
            maxWorkingSets: maxWorkingSets,
            dateCreated: Date(),
            dateUpdated: Date()
        )
    }

    private func recommendations(
        painLogs: [DailyPainLog] = [],
        injuries: [Injury] = [],
        activeRamps: [ReturnToLiftingRampRecord] = [],
        breakReason: TrainingBreakReason?
    ) -> [ReturnToLiftingRampRecommendation] {
        ReturnToLiftingRampService.recommendations(
            painLogs: painLogs,
            injuries: injuries,
            activeRamps: activeRamps,
            breakReason: breakReason
        )
    }

    // MARK: - Additive Behavior

    func testNilBreakReason_BehavesExactlyAsBefore() {
        XCTAssertTrue(recommendations(breakReason: nil).isEmpty,
                      "Omitting a break reason must leave the injury-only behavior untouched")
    }

    func testBreakReason_AppliesToEveryMovementPattern() {
        let recs = recommendations(breakReason: .extendedTimeOff)

        XCTAssertEqual(Set(recs.map(\.movementPattern)),
                       Set(WorkoutMovementPattern.allCases),
                       "A break has no affected body region, so every pattern ramps")
    }

    func testBreakReason_UsesItsStartingLoadAndSets() throws {
        for reason in TrainingBreakReason.allCases {
            let recs = recommendations(breakReason: reason)
            let squat = try XCTUnwrap(recs.first { $0.movementPattern == .squat })

            XCTAssertEqual(squat.maxLoadPercent, reason.startingLoadPercent, accuracy: 0.001,
                           "\(reason.rawValue) should start at its own load")
            XCTAssertEqual(squat.maxWorkingSets, reason.startingWorkingSets)
        }
    }

    // MARK: - Interaction With Pain and Injury

    func testMoreCautiousBreakWins_OverLessCautiousPain() throws {
        // Moderate knee pain caps squat at 0.60; postpartum starts at 0.40.
        let recs = recommendations(
            painLogs: [makePainLog(locationIds: "knee_left", intensity: 5)],
            breakReason: .postpartum
        )
        let squat = try XCTUnwrap(recs.first { $0.movementPattern == .squat })

        XCTAssertEqual(squat.maxLoadPercent, 0.40, accuracy: 0.001,
                       "The more cautious of the two should govern")
        XCTAssertTrue(squat.reason.contains("time away"),
                      "The reason shown must match the value shown, got: \(squat.reason)")
    }

    func testMoreCautiousPainWins_OverLessCautiousBreak() throws {
        // Extreme knee pain caps squat at 0.30; time off would start at 0.60.
        let recs = recommendations(
            painLogs: [makePainLog(locationIds: "knee_left", intensity: 10)],
            breakReason: .extendedTimeOff
        )
        let squat = try XCTUnwrap(recs.first { $0.movementPattern == .squat })

        XCTAssertEqual(squat.maxLoadPercent, 0.30, accuracy: 0.001)
        XCTAssertTrue(squat.reason.contains("discomfort"),
                      "Pain-driven caution should keep its own explanation, got: \(squat.reason)")
    }

    func testUnaffectedPatternsStillGetTheBreakRamp() throws {
        let recs = recommendations(
            painLogs: [makePainLog(locationIds: "knee_left", intensity: 10)],
            breakReason: .extendedTimeOff
        )
        let push = try XCTUnwrap(recs.first { $0.movementPattern == .push })

        XCTAssertEqual(push.maxLoadPercent, 0.60, accuracy: 0.001,
                       "Knee pain does not touch pushing, so the break ramp governs there")
    }

    func testWorkingSetsTakeTheLowerOfBothCaps() throws {
        // Extreme pain allows 2 sets; illness would allow 3.
        let recs = recommendations(
            painLogs: [makePainLog(locationIds: "knee_left", intensity: 10)],
            breakReason: .illness
        )
        let squat = try XCTUnwrap(recs.first { $0.movementPattern == .squat })

        XCTAssertEqual(squat.maxWorkingSets, 2)
    }

    func testActiveRampRecord_IsNotWalkedBackByABreakReason() throws {
        // Someone at week 5 and 80% should not be dropped to 40% because they
        // also picked a break reason — that record is earned progress.
        let recs = recommendations(
            activeRamps: [makeRamp(locationIds: "knee_left", movementPattern: .squat)],
            breakReason: .postpartum
        )
        let squat = try XCTUnwrap(recs.first { $0.movementPattern == .squat })

        XCTAssertEqual(squat.maxLoadPercent, 0.80, accuracy: 0.001)
        XCTAssertEqual(squat.maxWorkingSets, 4)
    }

    // MARK: - Caution Ordering

    func testPostpartumIsTheMostCautiousStartingPoint() {
        let others = TrainingBreakReason.allCases.filter { $0 != .postpartum }

        for reason in others {
            XCTAssertLessThanOrEqual(
                TrainingBreakReason.postpartum.startingLoadPercent,
                reason.startingLoadPercent,
                "Postpartum should never start heavier than \(reason.rawValue)"
            )
        }
    }

    func testEveryBreakReasonStartsInsideTheInjuryBand() {
        // The injury paths span 0.30 (extreme pain) to 0.60 (moderate pain and
        // resolved injuries). A break-driven ramp must not start heavier than
        // the most permissive injury ramp.
        for reason in TrainingBreakReason.allCases {
            XCTAssertGreaterThanOrEqual(reason.startingLoadPercent, 0.30, "\(reason.rawValue)")
            XCTAssertLessThanOrEqual(reason.startingLoadPercent, 0.60, "\(reason.rawValue)")
            XCTAssertGreaterThanOrEqual(reason.startingWorkingSets, 1, "\(reason.rawValue)")
            XCTAssertLessThanOrEqual(reason.startingWorkingSets, 5, "\(reason.rawValue)")
        }
    }

    // MARK: - Progression Bounds

    func testBreakRampsAdvanceWithinTheSameBoundsAsInjuryRamps() {
        for reason in TrainingBreakReason.allCases {
            var ramp = ReturnToLiftingRampRecord(
                id: "ramp-\(reason.rawValue)",
                locationIds: "",
                movementPatternRaw: WorkoutMovementPattern.squat.rawValue,
                currentWeek: 1,
                maxLoadPercent: reason.startingLoadPercent,
                maxWorkingSets: reason.startingWorkingSets,
                dateCreated: Date(),
                dateUpdated: Date()
            )

            for week in 1...12 {
                let previous = ramp
                ramp = ReturnToLiftingRampService.advanceRamp(ramp)

                let increase = ramp.maxLoadPercent - previous.maxLoadPercent
                if previous.maxLoadPercent < 1.0 {
                    XCTAssertGreaterThan(increase, 0,
                                         "\(reason.rawValue) week \(week) should progress")
                    XCTAssertLessThanOrEqual(increase, 0.10,
                                             "\(reason.rawValue) week \(week) exceeded 10% per week")
                }
                XCTAssertLessThanOrEqual(ramp.maxLoadPercent, 1.0,
                                         "\(reason.rawValue) week \(week) exceeded full load")
                XCTAssertGreaterThanOrEqual(ramp.maxWorkingSets, previous.maxWorkingSets,
                                            "\(reason.rawValue) sets should never decrease")
                XCTAssertLessThanOrEqual(ramp.maxWorkingSets, 5,
                                         "\(reason.rawValue) sets exceeded the injury-path ceiling")
            }
        }
    }

    func testBreakRampReachesFullLoadEventually() {
        var ramp = ReturnToLiftingRampRecord(
            id: "ramp-1",
            locationIds: "",
            movementPatternRaw: WorkoutMovementPattern.squat.rawValue,
            currentWeek: 1,
            maxLoadPercent: TrainingBreakReason.postpartum.startingLoadPercent,
            maxWorkingSets: TrainingBreakReason.postpartum.startingWorkingSets,
            dateCreated: Date(),
            dateUpdated: Date()
        )

        for _ in 1...20 {
            ramp = ReturnToLiftingRampService.advanceRamp(ramp)
        }

        XCTAssertEqual(ramp.maxLoadPercent, 1.0, accuracy: 0.001,
                       "A ramp that never tops out would trap someone below their usual loads")
    }

    // MARK: - Copy Discipline

    func testBreakReasonCopy_NamesTheMovementPattern() {
        for reason in TrainingBreakReason.allCases {
            let text = reason.rampReason(for: .hinge)
            XCTAssertTrue(text.contains("hinge"),
                          "\(reason.rawValue) copy should name the pattern, got: \(text)")
        }
    }

    func testBreakReasonCopy_AvoidsMedicalLanguage() {
        // Mirrors the forbidden-term check the injury paths already enforce.
        let forbidden = ["treat", "heal", "diagnose", "medical", "therapy",
                         "rehabilitate", "recovery time", "cleared", "safe to"]

        for reason in TrainingBreakReason.allCases {
            for pattern in WorkoutMovementPattern.allCases {
                let lowered = reason.rampReason(for: pattern).lowercased()
                for term in forbidden {
                    XCTAssertFalse(lowered.contains(term),
                                   "\(reason.rawValue) copy must not imply clinical judgment "
                                       + "('\(term)'): \(lowered)")
                }
            }
        }
    }

    func testBreakReasonCopy_UsesEasingLanguage() {
        for reason in TrainingBreakReason.allCases {
            let lowered = reason.rampReason(for: .squat).lowercased()
            let easing = lowered.contains("easing") || lowered.contains("gradual")
                || lowered.contains("starting light") || lowered.contains("conservatively")
                || lowered.contains("building")
            XCTAssertTrue(easing, "\(reason.rawValue) should use easing language, got: \(lowered)")
        }
    }

    func testPostpartumCopy_MakesNoPhysiologicalClaim() {
        // The plan defers postpartum-specific physiological modeling. The copy
        // must not imply any of it has happened.
        let text = TrainingBreakReason.postpartum.rampReason(for: .core).lowercased()
        let claims = ["pelvic", "core strength", "abdominal", "weeks postpartum",
                      "doctor", "birth", "delivery"]

        for claim in claims {
            XCTAssertFalse(text.contains(claim),
                           "Postpartum copy must make no physiological claim ('\(claim)'): \(text)")
        }
    }
}
