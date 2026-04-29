import XCTest
@testable import SundeeFundeeKit

final class ProgramTemplateGeneratorTests: XCTestCase {

    func testProgramTemplateAllCasesContainsOnlyV16PrintableCatalog() {
        XCTAssertEqual(ProgramTemplate.allCases, [
            .firstMargarita,
            .beginnerStrength,
            .dumbbellStrength,
            .glutesCoreConditioning,
        ])
    }

    func testProgramTemplateStableIDsMatchWebCatalog() {
        XCTAssertEqual(ProgramTemplate.firstMargarita.stableID, "first-margarita")
        XCTAssertEqual(ProgramTemplate.beginnerStrength.stableID, "beginner-strength")
        XCTAssertEqual(ProgramTemplate.dumbbellStrength.stableID, "dumbbell-strength")
        XCTAssertEqual(ProgramTemplate.glutesCoreConditioning.stableID, "glutes-core-conditioning")
    }

    func testAllTemplatesGenerateExpectedWeekAndSessionCounts() throws {
        let expectedCounts: [ProgramTemplate: (weeks: Int, sessions: Int)] = [
            .firstMargarita: (8, 3),
            .beginnerStrength: (4, 4),
            .dumbbellStrength: (6, 4),
            .glutesCoreConditioning: (8, 4),
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
}
