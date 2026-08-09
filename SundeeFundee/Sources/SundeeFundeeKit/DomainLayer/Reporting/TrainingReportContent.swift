import Foundation

// MARK: - TrainingReportContent

/// A plain-data snapshot of a shareable training report.
///
/// Built from data the user has already logged, plus the already-computed
/// output of `CycleAwareProgressInsightService`, `MonthlyReviewService`, and
/// `SymptomTrainingTrendService` — this type does not recompute anything
/// those services already own. Pure value type: no I/O, no rendering
/// concerns. A later rendering step (PDF, etc.) consumes this type.
public struct TrainingReportContent: Sendable, Equatable {
    // MARK: - Overview

    public struct Overview: Sendable, Equatable {
        public let rangeStart: Date
        public let rangeEnd: Date
        public let completedWorkoutCount: Int
        public let totalVolume: Double
        public let personalRecordCount: Int

        public init(
            rangeStart: Date,
            rangeEnd: Date,
            completedWorkoutCount: Int,
            totalVolume: Double,
            personalRecordCount: Int
        ) {
            self.rangeStart = rangeStart
            self.rangeEnd = rangeEnd
            self.completedWorkoutCount = completedWorkoutCount
            self.totalVolume = totalVolume
            self.personalRecordCount = personalRecordCount
        }
    }

    // MARK: - Pain / Injury Timeline

    /// A single dated entry in the report's pain-and-injury timeline. Built
    /// from either a `DailyPainLog` or an `Injury` — the two are merged and
    /// sorted chronologically by `TrainingReportBuilder`.
    public struct PainTimelineEntry: Sendable, Equatable, Identifiable {
        public let id: String
        public let date: Date
        public let summary: String
        public let note: String?

        public init(id: String, date: Date, summary: String, note: String?) {
            self.id = id
            self.date = date
            self.summary = summary
            self.note = note
        }
    }

    // MARK: - Sections

    public let generatedAt: Date
    public let overview: Overview

    /// Plain-language narration of the `overview` figures, including the
    /// volume trend across the window. The `overview` numbers are kept
    /// alongside these sentences so a renderer can show figures, prose, or
    /// both.
    public let sessionSummary: [String]

    /// Plain-language narration of `CycleAwareProgressInsight` values.
    /// Empty when `includesCycleDetail` is false.
    public let cycleAwarePatternSummary: [String]

    /// Top wins and patterns pulled from `MonthlyReview` values in range.
    public let monthlyHighlights: [String]

    /// Plain-language narration of `SymptomTrainingInsight` messages.
    /// Empty when `includesCycleDetail` is false.
    public let symptomTrainingNotes: [String]

    /// Merged, chronologically sorted pain log and injury entries.
    public let painAndInjuryTimeline: [PainTimelineEntry]

    /// Human-readable status lines for any return-to-lifting ramps active
    /// or updated within the report's date range.
    public let activeReturnToLiftingRamps: [String]

    /// Whether cycle-specific detail (phase-linked patterns, symptom notes)
    /// was included in this report. Defaults to false — sharing context
    /// with a clinician is not the same as personal in-app use, so cycle
    /// detail is opt-in per report rather than included by default.
    public let includesCycleDetail: Bool

    public init(
        generatedAt: Date,
        overview: Overview,
        sessionSummary: [String] = [],
        cycleAwarePatternSummary: [String],
        monthlyHighlights: [String],
        symptomTrainingNotes: [String],
        painAndInjuryTimeline: [PainTimelineEntry],
        activeReturnToLiftingRamps: [String],
        includesCycleDetail: Bool
    ) {
        self.generatedAt = generatedAt
        self.overview = overview
        self.sessionSummary = sessionSummary
        self.cycleAwarePatternSummary = cycleAwarePatternSummary
        self.monthlyHighlights = monthlyHighlights
        self.symptomTrainingNotes = symptomTrainingNotes
        self.painAndInjuryTimeline = painAndInjuryTimeline
        self.activeReturnToLiftingRamps = activeReturnToLiftingRamps
        self.includesCycleDetail = includesCycleDetail
    }

    /// A valid empty-state report — no logged data in range.
    ///
    /// Still narrates the (empty) overview, so an empty report reads as a
    /// deliberate "nothing was logged in this window" rather than a blank
    /// page that looks like a rendering failure.
    public static func empty(
        generatedAt: Date = Date(),
        rangeStart: Date,
        rangeEnd: Date,
        calendar: Calendar = .current
    ) -> TrainingReportContent {
        let overview = Overview(
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            completedWorkoutCount: 0,
            totalVolume: 0,
            personalRecordCount: 0
        )
        return TrainingReportContent(
            generatedAt: generatedAt,
            overview: overview,
            sessionSummary: ReportNarrator.narrateOverview(overview, calendar: calendar),
            cycleAwarePatternSummary: [],
            monthlyHighlights: [],
            symptomTrainingNotes: [],
            painAndInjuryTimeline: [],
            activeReturnToLiftingRamps: [],
            includesCycleDetail: false
        )
    }
}
