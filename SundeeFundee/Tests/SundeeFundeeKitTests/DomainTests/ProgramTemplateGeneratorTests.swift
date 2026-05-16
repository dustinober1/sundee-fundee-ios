import XCTest
@testable import SundeeFundeeKit

final class ProgramTemplateGeneratorTests: XCTestCase {

    func testProgramTemplateAllCasesContainsOnlyV16PrintableCatalog() {
        XCTAssertEqual(ProgramTemplate.allCases, [
            .firstMargarita,
            .beginnerStrength,
            .dumbbellStrength,
            .glutesCoreConditioning,
            .russianSquat,
        ])
    }

    func testProgramTemplateStableIDsMatchWebCatalog() {
        XCTAssertEqual(ProgramTemplate.firstMargarita.stableID, "first-margarita")
        XCTAssertEqual(ProgramTemplate.beginnerStrength.stableID, "beginner-strength")
        XCTAssertEqual(ProgramTemplate.dumbbellStrength.stableID, "dumbbell-strength")
        XCTAssertEqual(ProgramTemplate.glutesCoreConditioning.stableID, "glutes-core-conditioning")
        XCTAssertEqual(ProgramTemplate.russianSquat.stableID, "russian-squat-program")
    }

    func testAllTemplatesGenerateExpectedWeekAndSessionCounts() throws {
        let expectedCounts: [ProgramTemplate: (weeks: Int, sessions: Int)] = [
            .firstMargarita: (8, 3),
            .beginnerStrength: (4, 4),
            .dumbbellStrength: (6, 4),
            .glutesCoreConditioning: (8, 4),
            .russianSquat: (6, 3),
        ]

        for template in ProgramTemplate.allCases {
            let expected = try XCTUnwrap(expectedCounts[template])
            let program = generateProgram(template: template, name: template.displayName)

            XCTAssertEqual(program.id, template.stableID)
            XCTAssertEqual(program.durationWeeks, expected.weeks, "\(template) should have the PDF week count")
            XCTAssertEqual(program.sessionsPerWeek, expected.sessions, "\(template) should have the PDF session count")
            XCTAssertEqual(program.weeks.count, expected.weeks, "\(template) should generate every week")
            XCTAssertEqual(templateDefaults[template]?.durationWeeks, expected.weeks)
            XCTAssertEqual(templateDefaults[template]?.sessionsPerWeek, expected.sessions)

            for week in program.weeks {
                XCTAssertEqual(week.sessions.count, expected.sessions, "\(template) week \(week.week) should have every session")
                XCTAssertTrue(week.sessions.allSatisfy { !$0.exercises.isEmpty })
            }
        }
    }

    func testPrintablePDFURLsAreHostedOnSundeeFundee() throws {
        for template in ProgramTemplate.allCases {
            let url = try XCTUnwrap(template.printablePDFURL)
            XCTAssertEqual(url.scheme, "https")
            XCTAssertEqual(url.host, "sundeefundee.com")
            XCTAssertTrue(url.path.hasPrefix("/workout-plans/"))
            XCTAssertTrue(url.path.hasSuffix(".pdf"))
        }
    }

    func testBeginnerPlanDoesNotRequireMaxes() {
        let program = generateProgram(template: .beginnerStrength, name: "Beginner Strength")
        let allExercises = program.weeks.flatMap(\.sessions).flatMap(\.exercises)

        XCTAssertFalse(allExercises.isEmpty)
        XCTAssertTrue(allExercises.allSatisfy { $0.percent1RM == nil })
    }

    func testRussianSquatProgramMatchesPublishedSessionTable() throws {
        let program = generateProgram(template: .russianSquat, name: ProgramTemplate.russianSquat.displayName)

        XCTAssertEqual(program.name, "Russian Squat")
        XCTAssertEqual(program.category, "Strength")
        XCTAssertEqual(program.difficulty, "Advanced")
        XCTAssertEqual(program.weeks.count, 6)

        let expectedSessions: [(week: Int, percentages: [Double], sets: [Int], reps: [Int])] = [
            (1, [0.80, 0.80, 0.80], [6, 6, 6], [2, 3, 2]),
            (2, [0.80, 0.80, 0.80], [6, 6, 6], [4, 2, 5]),
            (3, [0.80, 0.80, 0.80], [6, 6, 6], [2, 6, 2]),
            (4, [0.85, 0.80, 0.90], [5, 6, 4], [5, 2, 4]),
            (5, [0.80, 0.95, 0.80], [6, 3, 6], [2, 3, 2]),
            (6, [1.00, 0.80, 1.05], [2, 6, 1], [2, 2, 1]),
        ]

        for expected in expectedSessions {
            let week = try XCTUnwrap(program.weeks.first(where: { $0.week == expected.week }))
            XCTAssertEqual(week.sessions.count, 3)

            for (index, session) in week.sessions.enumerated() {
                XCTAssertEqual(session.exercises.count, 1)
                let squat = try XCTUnwrap(session.exercises.first)
                let percent1RM = try XCTUnwrap(squat.percent1RM)
                XCTAssertEqual(squat.exercise, "Back Squat")
                XCTAssertEqual(percent1RM, expected.percentages[index], accuracy: 0.0001)
                XCTAssertEqual(squat.sets, .fixed(value: expected.sets[index]))
                XCTAssertEqual(squat.reps, .fixed(value: expected.reps[index]))
                XCTAssertFalse(squat.bodyweightOnly)
            }
        }
    }
}
