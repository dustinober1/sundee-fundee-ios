import XCTest
@testable import SundeeFundeeKit

/// Tests for the return-to-training schedule and the program generated from it.
///
/// The point of this program is that its loads are *derived* from the ramp
/// service rather than authored, so most of these assert relationships between
/// the schedule and the ramp rather than fixed numbers.
final class ReturnToTrainingProgramTests: XCTestCase {

    // MARK: - Schedule Shape

    func testSchedule_StartsAtTheBreakReasonStartingPoint() throws {
        for reason in TrainingBreakReason.allCases {
            let first = try XCTUnwrap(ReturnToTrainingSchedule.weeks(for: reason).first)

            XCTAssertEqual(first.week, 1)
            XCTAssertEqual(first.loadPercent, reason.startingLoadPercent, accuracy: 0.001)
            XCTAssertEqual(first.workingSets, reason.startingWorkingSets)
        }
    }

    func testSchedule_RunsUntilFullLoad() throws {
        for reason in TrainingBreakReason.allCases {
            let last = try XCTUnwrap(ReturnToTrainingSchedule.weeks(for: reason).last)

            XCTAssertEqual(last.loadPercent, 1.0, accuracy: 0.001,
                           "\(reason.rawValue) should finish back at usual working loads")
        }
    }

    func testSchedule_NumbersWeeksConsecutivelyFromOne() {
        for reason in TrainingBreakReason.allCases {
            let weeks = ReturnToTrainingSchedule.weeks(for: reason)
            XCTAssertEqual(weeks.map(\.week), Array(1...weeks.count))
        }
    }

    func testSchedule_MoreCautiousStartProducesALongerBlock() {
        let postpartum = ReturnToTrainingSchedule.weeks(for: .postpartum).count
        let timeOff = ReturnToTrainingSchedule.weeks(for: .extendedTimeOff).count

        XCTAssertGreaterThan(postpartum, timeOff,
                             "A lighter start should mean more weeks, not a steeper climb")
    }

    func testSchedule_RespectsTheLengthCap() {
        for reason in TrainingBreakReason.allCases {
            XCTAssertLessThanOrEqual(
                ReturnToTrainingSchedule.weeks(for: reason).count,
                ReturnToTrainingSchedule.maximumWeeks
            )
        }
    }

    // MARK: - Progression Bounds
    //
    // The plan's requirement: week-over-week progression must stay inside the
    // same bounds the injury ramps already enforce.

    func testSchedule_ProgressionStaysWithinInjuryRampBounds() {
        for reason in TrainingBreakReason.allCases {
            let weeks = ReturnToTrainingSchedule.weeks(for: reason)

            for (previous, current) in zip(weeks, weeks.dropFirst()) {
                let increase = current.loadPercent - previous.loadPercent

                XCTAssertGreaterThan(increase, 0,
                                     "\(reason.rawValue) week \(current.week) should progress")
                XCTAssertLessThanOrEqual(increase, 0.10,
                                         "\(reason.rawValue) week \(current.week) exceeded 10% per week")
                XCTAssertLessThanOrEqual(current.loadPercent, 1.0,
                                         "\(reason.rawValue) week \(current.week) exceeded full load")
                XCTAssertGreaterThanOrEqual(current.workingSets, previous.workingSets,
                                            "\(reason.rawValue) sets should never decrease")
                XCTAssertLessThanOrEqual(current.workingSets, 5,
                                         "\(reason.rawValue) exceeded the injury-path set ceiling")
            }
        }
    }

    func testSchedule_MatchesTheRampServiceStepForStep() {
        // The schedule must be the ramp service's output, not a parallel table
        // that could drift from it.
        for reason in TrainingBreakReason.allCases {
            let weeks = ReturnToTrainingSchedule.weeks(for: reason)
            var record = ReturnToLiftingRampRecord(
                id: "expected",
                locationIds: "",
                movementPatternRaw: "",
                currentWeek: 1,
                maxLoadPercent: reason.startingLoadPercent,
                maxWorkingSets: reason.startingWorkingSets,
                dateCreated: Date(),
                dateUpdated: Date()
            )

            for week in weeks {
                XCTAssertEqual(week.loadPercent, record.maxLoadPercent, accuracy: 0.0001,
                               "\(reason.rawValue) week \(week.week) diverged from the ramp service")
                XCTAssertEqual(week.workingSets, record.maxWorkingSets)
                record = ReturnToLiftingRampService.advanceRamp(record)
            }
        }
    }

    // MARK: - Week Copy

    func testFirstWeekFocus_CarriesTheBreakReasonFraming() {
        for reason in TrainingBreakReason.allCases {
            let first = ReturnToTrainingSchedule.weeks(for: reason).first

            XCTAssertEqual(first?.focus.hasPrefix(reason.programOpening), true,
                           "\(reason.rawValue) should open with its own framing, got: \(first?.focus ?? "nil")")
        }
    }

    func testEveryWeekFocus_StatesTheLoadTarget() {
        for week in ReturnToTrainingSchedule.weeks(for: .postpartum) {
            let percent = Int((week.loadPercent * 100).rounded())
            let mentionsLoad = week.focus.contains("\(percent)%")
                || week.focus.contains("usual working weights")

            XCTAssertTrue(mentionsLoad,
                          "Week \(week.week) should say what the load target is, got: \(week.focus)")
        }
    }

    func testWeekCopy_AvoidsMedicalLanguage() {
        let forbidden = ["treat", "heal", "diagnose", "medical", "therapy", "rehabilitate", "cleared"]

        for reason in TrainingBreakReason.allCases {
            for week in ReturnToTrainingSchedule.weeks(for: reason) {
                let lowered = week.focus.lowercased()
                for term in forbidden {
                    XCTAssertFalse(lowered.contains(term),
                                   "\(reason.rawValue) week \(week.week) copy contains '\(term)': \(week.focus)")
                }
            }
        }
    }

    func testPhaseNames_TrackTheLoadBand() throws {
        let weeks = ReturnToTrainingSchedule.weeks(for: .postpartum)

        XCTAssertEqual(weeks.first?.phaseName, "Easing In")
        XCTAssertEqual(weeks.last?.phaseName, "Back to Full Load")
    }

    // MARK: - Generated Program

    func testProgram_HasOneWeekPerScheduleWeek() {
        for reason in TrainingBreakReason.allCases {
            let schedule = ReturnToTrainingSchedule.weeks(for: reason)
            let program = generateReturnToTrainingProgram(breakReason: reason)

            XCTAssertEqual(program.durationWeeks, schedule.count)
            XCTAssertEqual(program.weeks.count, schedule.count)
            XCTAssertEqual(program.phases.count, schedule.count)
        }
    }

    func testProgram_HasThreeSessionsEveryWeek() {
        let program = generateReturnToTrainingProgram(breakReason: .illness)

        XCTAssertEqual(program.sessionsPerWeek, 3)
        for week in program.weeks {
            XCTAssertEqual(week.sessions.count, 3, "Week \(week.week) should have three sessions")
            XCTAssertTrue(week.sessions.allSatisfy { !$0.exercises.isEmpty })
        }
    }

    func testProgram_LoadedLiftsUseTheWeeksRampPercentage() throws {
        let reason = TrainingBreakReason.postpartum
        let schedule = ReturnToTrainingSchedule.weeks(for: reason)
        let program = generateReturnToTrainingProgram(breakReason: reason)

        for (week, scheduled) in zip(program.weeks, schedule) {
            let loaded = week.sessions.flatMap(\.exercises).filter { !$0.bodyweightOnly }
            XCTAssertFalse(loaded.isEmpty, "Week \(week.week) should have loaded lifts")

            for exercise in loaded where exercise.percent1RM != nil {
                XCTAssertEqual(try XCTUnwrap(exercise.percent1RM), scheduled.loadPercent,
                               accuracy: 0.0001,
                               "\(exercise.exercise) in week \(week.week) should use the ramp load")
            }
        }
    }

    func testProgram_MainLiftSetsFollowTheRampCap() throws {
        let reason = TrainingBreakReason.postpartum
        let schedule = ReturnToTrainingSchedule.weeks(for: reason)
        let program = generateReturnToTrainingProgram(breakReason: reason)

        for (week, scheduled) in zip(program.weeks, schedule) {
            let mainLifts = week.sessions.flatMap(\.exercises).filter { $0.percent1RM != nil }

            for lift in mainLifts {
                guard case .fixed(let sets) = lift.sets else {
                    return XCTFail("Main lifts should prescribe a fixed set count")
                }
                XCTAssertEqual(sets, scheduled.workingSets,
                               "\(lift.exercise) week \(week.week) should respect the ramp set cap")
            }
        }
    }

    func testProgram_NeverAsksForAMaxTest() {
        // A return block should not send someone straight at a one-rep max.
        for reason in TrainingBreakReason.allCases {
            let program = generateReturnToTrainingProgram(breakReason: reason)
            let exercises = program.weeks.flatMap(\.sessions).flatMap(\.exercises)

            XCTAssertFalse(exercises.contains { ($0.percent1RM ?? 0) > 1.0 },
                           "\(reason.rawValue) should never prescribe above usual working load")
            XCTAssertFalse(exercises.contains { exercise in
                if case .amrap = exercise.reps { return true }
                return false
            }, "\(reason.rawValue) should not include max-rep tests")
        }
    }

    func testProgram_KeepsMovementsConsistentAcrossWeeks() throws {
        let program = generateReturnToTrainingProgram(breakReason: .extendedTimeOff)
        let firstWeek = try XCTUnwrap(program.weeks.first)
        let names = firstWeek.sessions.flatMap { $0.exercises.map(\.exercise) }

        for week in program.weeks.dropFirst() {
            XCTAssertEqual(week.sessions.flatMap { $0.exercises.map(\.exercise) }, names,
                           "Movements should stay familiar week to week; only load and sets move")
        }
    }

    func testProgram_IsNotPartOfThePrintableCatalog() {
        // The printable catalog is fixed plans hosted as PDFs. This program is
        // derived per person, so it must not leak into that enum.
        XCTAssertFalse(ProgramTemplate.allCases.map(\.stableID).contains(returnToTrainingProgramID))
    }

    func testProgram_UsesItsStableIdentifier() {
        XCTAssertEqual(
            generateReturnToTrainingProgram(breakReason: .other).id,
            returnToTrainingProgramID
        )
    }

    func testProgram_DescriptionStatesTheLengthAndFraming() {
        for reason in TrainingBreakReason.allCases {
            let program = generateReturnToTrainingProgram(breakReason: reason)
            let weeks = ReturnToTrainingSchedule.weeks(for: reason).count

            XCTAssertTrue(program.description.contains("\(weeks)-week"),
                          "Description should state the real length, got: \(program.description)")
            XCTAssertTrue(program.description.contains(reason.programOpening))
        }
    }
}
