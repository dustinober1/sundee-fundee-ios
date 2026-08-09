import XCTest
@testable import SundeeFundeeKit

/// Tests for `TrainingReportDocument` — the section layout of the report.
///
/// This layer holds the decisions the PDF renderer must not make: which
/// sections appear, in what order, and what is withheld. The renderer is
/// UIKit-only and therefore uncovered by `swift test` on macOS, so keeping
/// those decisions here is what makes them testable at all.
final class TrainingReportDocumentTests: XCTestCase {

    // MARK: - Fixtures

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func makeDate(day: Int, month: Int = 6, year: Int = 2026) -> Date {
        Self.utcCalendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makeContent(
        sessionSummary: [String] = ["2 training sessions were logged."],
        cycleAwarePatternSummary: [String] = [],
        monthlyHighlights: [String] = [],
        symptomTrainingNotes: [String] = [],
        painAndInjuryTimeline: [TrainingReportContent.PainTimelineEntry] = [],
        activeReturnToLiftingRamps: [String] = [],
        includesCycleDetail: Bool = false
    ) -> TrainingReportContent {
        TrainingReportContent(
            generatedAt: makeDate(day: 30),
            overview: TrainingReportContent.Overview(
                rangeStart: makeDate(day: 1),
                rangeEnd: makeDate(day: 30),
                completedWorkoutCount: 2,
                totalVolume: 2000,
                personalRecordCount: 0
            ),
            sessionSummary: sessionSummary,
            cycleAwarePatternSummary: cycleAwarePatternSummary,
            monthlyHighlights: monthlyHighlights,
            symptomTrainingNotes: symptomTrainingNotes,
            painAndInjuryTimeline: painAndInjuryTimeline,
            activeReturnToLiftingRamps: activeReturnToLiftingRamps,
            includesCycleDetail: includesCycleDetail
        )
    }

    private func makeDocument(_ content: TrainingReportContent) -> TrainingReportDocument {
        TrainingReportDocument.make(from: content, calendar: Self.utcCalendar)
    }

    private func headings(of document: TrainingReportDocument) -> [String] {
        document.blocks.compactMap {
            if case .heading(let text) = $0 { return text }
            return nil
        }
    }

    private func footnotes(of document: TrainingReportDocument) -> [String] {
        document.blocks.compactMap {
            if case .footnote(let text) = $0 { return text }
            return nil
        }
    }

    // MARK: - Header

    func testDocument_OpensWithTitleAndDateRange() {
        let document = makeDocument(makeContent())

        XCTAssertEqual(document.blocks.first, .title("Training Summary"))
        XCTAssertEqual(document.blocks[1], .subtitle("June 1, 2026 – June 29, 2026"),
                       "The subtitle must report the last covered day, not the exclusive range end")
    }

    // MARK: - Section Presence and Order

    func testDocument_OmitsEmptySectionsEntirely() {
        let document = makeDocument(makeContent())

        XCTAssertEqual(headings(of: document), [TrainingReportDocument.Section.sessionOverview],
                       "A sparse report should be short, not a run of empty headings")
    }

    func testDocument_SectionsAppearInReadingOrder() {
        let content = makeContent(
            cycleAwarePatternSummary: ["Volume was highest in the follicular phase."],
            monthlyHighlights: ["Hit three sessions a week."],
            symptomTrainingNotes: ["Rested on high-cramp days."],
            painAndInjuryTimeline: [
                .init(id: "p1", date: makeDate(day: 12), summary: "Severe sharp pain", note: nil)
            ],
            activeReturnToLiftingRamps: ["Week 3 of a gradual return to training."],
            includesCycleDetail: true
        )

        XCTAssertEqual(headings(of: makeDocument(content)), [
            TrainingReportDocument.Section.sessionOverview,
            TrainingReportDocument.Section.cyclePatterns,
            TrainingReportDocument.Section.highlights,
            TrainingReportDocument.Section.symptomNotes,
            TrainingReportDocument.Section.painTimeline,
            TrainingReportDocument.Section.returnToTraining,
        ])
    }

    func testDocument_SessionOverviewSurvivesEvenWhenEverythingElseIsEmpty() {
        let document = makeDocument(makeContent(
            sessionSummary: ["No training sessions were logged between June 1, 2026 and June 29, 2026."]
        ))

        XCTAssertTrue(document.blocks.contains(
            .paragraph("No training sessions were logged between June 1, 2026 and June 29, 2026.")
        ))
    }

    func testDocument_BulletSectionsRenderOneBulletPerEntry() {
        let document = makeDocument(makeContent(
            monthlyHighlights: ["Win one", "Win two", "Win three"]
        ))

        let bullets = document.blocks.compactMap { block -> String? in
            if case .bullet(let text) = block { return text }
            return nil
        }
        XCTAssertEqual(bullets, ["Win one", "Win two", "Win three"])
    }

    // MARK: - Pain Timeline

    func testTimelineRows_CarryFormattedDateSummaryAndNote() {
        let content = makeContent(painAndInjuryTimeline: [
            .init(id: "p1", date: makeDate(day: 12), summary: "Severe sharp pain", note: "After squats"),
            .init(id: "i1", date: makeDate(day: 14), summary: "Rotator cuff strain (Rehab)", note: nil),
        ])

        let rows = makeDocument(content).blocks.compactMap { block -> TrainingReportDocument.Block? in
            if case .timelineRow = block { return block }
            return nil
        }

        XCTAssertEqual(rows, [
            .timelineRow(date: "June 12, 2026", summary: "Severe sharp pain", note: "After squats"),
            .timelineRow(date: "June 14, 2026", summary: "Rotator cuff strain (Rehab)", note: nil),
        ])
    }

    // MARK: - Privacy and Disclaimers

    func testDocument_NotesWhenCycleDetailWasWithheld() {
        let document = makeDocument(makeContent(includesCycleDetail: false))

        XCTAssertTrue(footnotes(of: document).contains(TrainingReportDocument.cycleDetailOmittedNote),
                      "A reader should know the omission was a deliberate choice, not missing data")
    }

    func testDocument_OmitsTheWithheldNoteWhenCycleDetailWasIncluded() {
        let document = makeDocument(makeContent(includesCycleDetail: true))

        XCTAssertFalse(footnotes(of: document).contains(TrainingReportDocument.cycleDetailOmittedNote))
    }

    func testDocument_AlwaysCarriesTheDisclaimer() {
        for includesCycleDetail in [true, false] {
            let document = makeDocument(makeContent(includesCycleDetail: includesCycleDetail))
            XCTAssertTrue(footnotes(of: document).contains(TrainingReportDocument.disclaimer),
                          "Every report must state that it is not a medical record")
        }
    }

    func testDisclaimer_DisclaimsClinicalStanding() {
        let disclaimer = TrainingReportDocument.disclaimer.lowercased()
        XCTAssertTrue(disclaimer.contains("not a medical record"))
        XCTAssertTrue(disclaimer.contains("no clinical assessment"))
    }

    func testDocument_StampsGenerationDate() {
        let document = makeDocument(makeContent())

        XCTAssertTrue(footnotes(of: document).contains("Generated June 30, 2026."))
    }

    func testDocument_FootnotesComeLast() {
        let content = makeContent(
            monthlyHighlights: ["Win one"],
            activeReturnToLiftingRamps: ["Week 3 of a gradual return to training."]
        )
        let blocks = makeDocument(content).blocks

        let lastNonFootnote = blocks.lastIndex { block in
            if case .footnote = block { return false }
            return true
        }
        let firstFootnote = blocks.firstIndex { block in
            if case .footnote = block { return true }
            return false
        }

        XCTAssertNotNil(firstFootnote)
        XCTAssertLessThan(lastNonFootnote!, firstFootnote!,
                          "Footnotes belong at the end of the document, after all content")
    }

    // MARK: - Empty State

    func testEmptyContent_StillProducesAReadableDocument() {
        let empty = TrainingReportContent.empty(
            generatedAt: makeDate(day: 30),
            rangeStart: makeDate(day: 1),
            rangeEnd: makeDate(day: 30),
            calendar: Self.utcCalendar
        )
        let document = makeDocument(empty)

        XCTAssertEqual(document.blocks.first, .title("Training Summary"))
        XCTAssertEqual(headings(of: document), [TrainingReportDocument.Section.sessionOverview])
        XCTAssertTrue(document.blocks.contains { block in
            if case .paragraph(let text) = block { return text.contains("No training sessions were logged") }
            return false
        }, "An empty report must say so on the page rather than render as a blank sheet")
        XCTAssertTrue(footnotes(of: document).contains(TrainingReportDocument.disclaimer))
    }

    // MARK: - Full Report

    func testFullContent_ProducesEverySectionExactlyOnce() {
        let content = makeContent(
            sessionSummary: ["12 sessions.", "Volume 50,000.", "Trend steady."],
            cycleAwarePatternSummary: ["Follicular highest."],
            monthlyHighlights: ["Win one", "Win two"],
            symptomTrainingNotes: ["Rested on high-cramp days."],
            painAndInjuryTimeline: [
                .init(id: "p1", date: makeDate(day: 4), summary: "Moderate aching", note: nil),
                .init(id: "i1", date: makeDate(day: 11), summary: "Rotator cuff strain (Rehab)", note: "Left side"),
            ],
            activeReturnToLiftingRamps: ["Week 2 of a gradual return to training."],
            includesCycleDetail: true
        )
        let document = makeDocument(content)

        XCTAssertEqual(Set(headings(of: document)).count, 6)
        XCTAssertEqual(headings(of: document).count, 6, "No section should be emitted twice")
        XCTAssertEqual(footnotes(of: document).count, 2,
                       "Cycle detail was included, so only the disclaimer and generation stamp remain")
    }
}
