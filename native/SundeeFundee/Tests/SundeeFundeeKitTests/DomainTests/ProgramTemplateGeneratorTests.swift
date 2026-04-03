import XCTest
@testable import SundeeFundeeKit

final class ProgramTemplateGeneratorTests: XCTestCase {

    // MARK: - Default generations

    func testAllTemplates_CorrectDefaults() {
        for template in ProgramTemplate.allCases {
            let defaults = templateDefaults[template]!
            let program = generateProgram(template: template, name: "Test \(template)")
            XCTAssertEqual(program.durationWeeks, defaults.durationWeeks, "\(template) should have correct weeks")
            XCTAssertEqual(program.sessionsPerWeek, defaults.sessionsPerWeek, "\(template) should have correct sessions")
            XCTAssertEqual(program.weeks.count, defaults.durationWeeks, "\(template) should generate correct week count")
            for week in program.weeks {
                XCTAssertEqual(week.sessions.count, defaults.sessionsPerWeek, "\(template) week \(week.week) should have correct session count")
            }
        }
    }

    func testCustomDurationAndSessions() {
        let program = generateProgram(template: .strength, name: "Custom", durationWeeks: 8, sessionsPerWeek: 4)
        XCTAssertEqual(program.durationWeeks, 8)
        XCTAssertEqual(program.sessionsPerWeek, 4)
        XCTAssertEqual(program.weeks.count, 8)
        for week in program.weeks {
            XCTAssertEqual(week.sessions.count, 4)
        }
    }

    // MARK: - Linear template

    func testLinear_DecreasingReps() {
        let program = generateProgram(template: .linear, name: "Linear Test")
        let week1Ex = program.weeks[0].sessions[0].exercises[0]
        let lastWeekEx = program.weeks[program.durationWeeks - 1].sessions[0].exercises[0]

        if case .fixed(let w1Reps) = week1Ex.reps, case .fixed(let lastReps) = lastWeekEx.reps {
            XCTAssertGreaterThan(w1Reps, lastReps, "Linear should decrease reps over time")
        } else {
            XCTFail("Expected fixed rep values")
        }
    }

    func testLinear_IncreasingLoad() {
        let program = generateProgram(template: .linear, name: "Linear Test")
        let week1Pct = program.weeks[0].sessions[0].exercises.first { !$0.bodyweightOnly }?.percent1RM
        let lastPct = program.weeks[program.durationWeeks - 1].sessions[0].exercises.first { !$0.bodyweightOnly }?.percent1RM

        XCTAssertNotNil(week1Pct)
        XCTAssertNotNil(lastPct)
        XCTAssertGreaterThan(lastPct!, week1Pct!, "Linear should increase load over time")
    }

    // MARK: - Block template

    func testBlock_HasPhases() {
        let program = generateProgram(template: .block, name: "Block Test")
        XCTAssertEqual(program.phases.count, 3)
        XCTAssertEqual(program.phases[0].id, "accumulation")
        XCTAssertEqual(program.phases[1].id, "intensification")
        XCTAssertEqual(program.phases[2].id, "peaking")
    }

    func testBlock_WeeksHavePhaseIds() {
        let program = generateProgram(template: .block, name: "Block Test")
        for week in program.weeks {
            XCTAssertNotNil(week.phaseId, "Block week \(week.week) should have a phaseId")
        }
    }

    // MARK: - DUP template

    func testDUP_SessionNames() {
        let program = generateProgram(template: .dup, name: "DUP Test")
        let names = program.weeks[0].sessions.map(\.sessionName)
        XCTAssertTrue(names[0].contains("Heavy"))
        XCTAssertTrue(names[1].contains("Moderate"))
        XCTAssertTrue(names[2].contains("Volume"))
    }

    // MARK: - Exercises present

    func testStrength_HasExercises() {
        let program = generateProgram(template: .strength, name: "Str Test")
        for week in program.weeks {
            for session in week.sessions {
                XCTAssertFalse(session.exercises.isEmpty, "Session \(session.sessionId) should have exercises")
            }
        }
    }

    // MARK: - Program metadata

    func testProgram_HasCorrectCategory() {
        let program = generateProgram(template: .strength, name: "Test")
        XCTAssertEqual(program.category, "custom")
    }

    func testProgram_HasDescription() {
        let program = generateProgram(template: .hypertrophy, name: "Hyp Test")
        XCTAssertTrue(program.description.contains("Hypertrophy"))
        XCTAssertTrue(program.description.contains("6 weeks"))
    }
}
