import Foundation

// MARK: - TrainingReportDocument

/// The laid-out structure of a training report, one block per line of the
/// finished page, independent of how it is drawn.
///
/// This exists so the decisions that matter — which sections appear, in what
/// order, what a section is called, and what is left out when the user has
/// not opted into sharing cycle detail — live in pure, testable code rather
/// than inside a UIKit renderer. The PDF renderer only turns these blocks
/// into ink; it makes no decisions about content.
public struct TrainingReportDocument: Sendable, Equatable {
    // MARK: - Block

    /// A single renderable element. Deliberately coarse: a report is headings,
    /// sentences, and a dated list, not a general layout engine.
    public enum Block: Sendable, Equatable {
        case title(String)
        case subtitle(String)
        case heading(String)
        case paragraph(String)
        case bullet(String)
        case timelineRow(date: String, summary: String, note: String?)
        case footnote(String)
    }

    // MARK: - Section Titles

    /// Section headings, exposed so tests and callers reference one spelling.
    public enum Section {
        public static let sessionOverview = "Session Overview"
        public static let cyclePatterns = "Cycle-Aware Patterns"
        public static let highlights = "Highlights"
        public static let symptomNotes = "Symptom and Training Notes"
        public static let painTimeline = "Pain and Injury Timeline"
        public static let returnToTraining = "Return to Training"
    }

    /// Shown on every report. States plainly what the document is and is not,
    /// because it may be read by a clinician who has no other context for it.
    public static let disclaimer =
        "This summary describes training activity the user logged themselves. "
            + "It is not a medical record and contains no clinical assessment."

    /// Shown when the user did not opt into including cycle detail, so a
    /// reader knows the omission was a deliberate privacy choice rather than
    /// an absence of data.
    public static let cycleDetailOmittedNote =
        "Cycle-phase information was intentionally excluded from this report."

    // MARK: - Contents

    /// The document's blocks, in render order.
    public let blocks: [Block]

    public init(blocks: [Block]) {
        self.blocks = blocks
    }

    // MARK: - Construction

    /// Lays out a report's content into blocks.
    ///
    /// Empty sections are dropped entirely — heading included — so a sparse
    /// report reads as a short document rather than a long list of blank
    /// headings. The session overview is always present because it always
    /// narrates something, even if only that nothing was logged.
    public static func make(
        from content: TrainingReportContent,
        calendar: Calendar = .current
    ) -> TrainingReportDocument {
        var blocks: [Block] = [
            .title("Training Summary"),
            .subtitle(ReportNarrator.dateRangeLabel(
                rangeStart: content.overview.rangeStart,
                rangeEnd: content.overview.rangeEnd,
                calendar: calendar
            ))
        ]

        blocks.append(.heading(Section.sessionOverview))
        blocks.append(contentsOf: content.sessionSummary.map(Block.paragraph))

        blocks += section(Section.cyclePatterns, bullets: content.cycleAwarePatternSummary)
        blocks += section(Section.highlights, bullets: content.monthlyHighlights)
        blocks += section(Section.symptomNotes, bullets: content.symptomTrainingNotes)

        if !content.painAndInjuryTimeline.isEmpty {
            blocks.append(.heading(Section.painTimeline))
            blocks += content.painAndInjuryTimeline.map { entry in
                .timelineRow(
                    date: ReportNarrator.formatDate(entry.date, calendar: calendar),
                    summary: entry.summary,
                    note: entry.note
                )
            }
        }

        blocks += section(Section.returnToTraining, bullets: content.activeReturnToLiftingRamps)

        if !content.includesCycleDetail {
            blocks.append(.footnote(cycleDetailOmittedNote))
        }
        blocks.append(.footnote(disclaimer))
        blocks.append(.footnote(
            "Generated \(ReportNarrator.formatDate(content.generatedAt, calendar: calendar))."
        ))

        return TrainingReportDocument(blocks: blocks)
    }

    // MARK: - Private Helpers

    private static func section(_ heading: String, bullets: [String]) -> [Block] {
        guard !bullets.isEmpty else { return [] }
        return [.heading(heading)] + bullets.map(Block.bullet)
    }
}
