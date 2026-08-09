#if canImport(UIKit)
import CoreGraphics
import Foundation
import UIKit
import XCTest
@testable import SundeeFundeeKit

// MARK: - TrainingReportPDFRendererTests
//
// Content decisions are covered by TrainingReportDocumentTests, which is pure
// and runs everywhere. These tests cover only what needs a real graphics
// context: that a valid, paginated, text-bearing PDF comes out the other side.
//
// Written as XCTest rather than Swift Testing so `xcodebuild test
// -only-testing:` can actually select and run them on a simulator. The
// renderer is compiled out under `swift test` on macOS, so this is the only
// place its runtime behavior gets exercised at all.

@available(iOS 18.0, *)
final class TrainingReportPDFRendererTests: XCTestCase {

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
        sessionSummary: [String] = ["12 training sessions were logged."],
        bullets: [String] = [],
        timeline: [TrainingReportContent.PainTimelineEntry] = [],
        includesCycleDetail: Bool = false
    ) -> TrainingReportContent {
        TrainingReportContent(
            generatedAt: makeDate(day: 30),
            overview: TrainingReportContent.Overview(
                rangeStart: makeDate(day: 1),
                rangeEnd: makeDate(day: 30),
                completedWorkoutCount: 12,
                totalVolume: 50_000,
                personalRecordCount: 2
            ),
            sessionSummary: sessionSummary,
            cycleAwarePatternSummary: [],
            monthlyHighlights: bullets,
            symptomTrainingNotes: [],
            painAndInjuryTimeline: timeline,
            activeReturnToLiftingRamps: [],
            includesCycleDetail: includesCycleDetail
        )
    }

    private func pdfDocument(from data: Data) -> CGPDFDocument? {
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        return CGPDFDocument(provider)
    }

    // MARK: - Validity

    func testProducesWellFormedPDF() {
        let data = TrainingReportPDFRenderer.render(makeContent(), calendar: Self.utcCalendar)

        XCTAssertFalse(data.isEmpty)
        XCTAssertTrue(data.starts(with: Array("%PDF".utf8)),
                      "Output should carry a PDF file signature")
        XCTAssertNotNil(pdfDocument(from: data), "Output should be parseable as a PDF document")
    }

    func testUsesUSLetterGeometry() throws {
        let data = TrainingReportPDFRenderer.render(makeContent(), calendar: Self.utcCalendar)
        let document = try XCTUnwrap(pdfDocument(from: data))
        let page = try XCTUnwrap(document.page(at: 1))
        let box = page.getBoxRect(.mediaBox)

        XCTAssertEqual(box.width, 612)
        XCTAssertEqual(box.height, 792)
    }

    // MARK: - Pagination

    func testShortReportIsOnePage() throws {
        let data = TrainingReportPDFRenderer.render(makeContent(), calendar: Self.utcCalendar)
        let document = try XCTUnwrap(pdfDocument(from: data))

        XCTAssertEqual(document.numberOfPages, 1)
    }

    func testLongReportPaginates() throws {
        let manyEntries = (1...120).map { index in
            TrainingReportContent.PainTimelineEntry(
                id: "entry-\(index)",
                date: makeDate(day: 1 + (index % 28)),
                summary: "Moderate aching in the left knee following session \(index)",
                note: "Noted during the cool-down and again the following morning."
            )
        }
        let data = TrainingReportPDFRenderer.render(
            makeContent(timeline: manyEntries),
            calendar: Self.utcCalendar
        )
        let document = try XCTUnwrap(pdfDocument(from: data))

        XCTAssertGreaterThan(document.numberOfPages, 1,
                             "A 120-entry timeline cannot fit on one page")
    }

    func testEmptyReportRendersOnePage() throws {
        let empty = TrainingReportContent.empty(
            generatedAt: makeDate(day: 30),
            rangeStart: makeDate(day: 1),
            rangeEnd: makeDate(day: 30),
            calendar: Self.utcCalendar
        )
        let data = TrainingReportPDFRenderer.render(empty, calendar: Self.utcCalendar)
        let document = try XCTUnwrap(pdfDocument(from: data))

        XCTAssertEqual(document.numberOfPages, 1)
    }

    // MARK: - Output Characteristics

    func testOutputIsVectorTextNotRasterized() {
        let data = TrainingReportPDFRenderer.render(
            makeContent(bullets: (1...20).map { "Highlight number \($0)" }),
            calendar: Self.utcCalendar
        )

        // A rasterized US Letter page runs to hundreds of kilobytes. Real text
        // is a few. This is the cheapest available proxy for "the clinician can
        // select and search this text".
        XCTAssertLessThan(data.count, 100_000,
                          "Report should be text, not a picture of text: \(data.count) bytes")
    }

    func testCarriesDocumentMetadata() throws {
        let data = TrainingReportPDFRenderer.render(makeContent(), calendar: Self.utcCalendar)
        let document = try XCTUnwrap(pdfDocument(from: data))
        let info = try XCTUnwrap(document.info)

        var title: CGPDFStringRef?
        XCTAssertTrue(CGPDFDictionaryGetString(info, "Title", &title))
    }

    // MARK: - Determinism

    func testRenderingIsStable() throws {
        let content = makeContent(bullets: (1...10).map { "Highlight \($0)" })
        let first = try XCTUnwrap(pdfDocument(from: TrainingReportPDFRenderer.render(
            content, calendar: Self.utcCalendar
        )))
        let second = try XCTUnwrap(pdfDocument(from: TrainingReportPDFRenderer.render(
            content, calendar: Self.utcCalendar
        )))

        XCTAssertEqual(first.numberOfPages, second.numberOfPages)
    }

    // MARK: - End to End

    func testRendersFromAssembledExportData() throws {
        var exported = ExportedData()
        exported.painLogs = (1...5).map { index in
            DailyPainLog(
                id: "pain-\(index)",
                locationIds: "knee_left",
                intensity: 5,
                painType: .aching,
                date: Date().addingTimeInterval(-Double(index) * 86_400),
                notes: nil
            )
        }

        let content = TrainingReportAssembler.assemble(
            exportedData: exported,
            range: .last30Days,
            includeCycleDetail: false
        )
        let data = TrainingReportPDFRenderer.render(content)
        let document = try XCTUnwrap(pdfDocument(from: data))

        XCTAssertGreaterThanOrEqual(document.numberOfPages, 1)
    }
}
#endif
