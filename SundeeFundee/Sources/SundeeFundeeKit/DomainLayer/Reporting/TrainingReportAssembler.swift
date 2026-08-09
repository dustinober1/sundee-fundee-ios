import Foundation

// MARK: - TrainingReportAssembler

/// Runs the existing insight services over exported data and hands their
/// output to `TrainingReportBuilder`.
///
/// `TrainingReportBuilder` deliberately takes already-computed insights so it
/// stays a pure assembly step. This type is the piece that actually calls the
/// services — the one place that knows a report needs cycle correlation from
/// `ChartDataAggregator`, a `MonthlyReview` per month touched, and symptom
/// trends. Pure and synchronous: all I/O happened upstream in
/// `DataExportService.exportAll()`.
public enum TrainingReportAssembler {
    /// Builds report content for a range.
    ///
    /// - Parameter includeCycleDetail: When false, cycle-linked insights are
    ///   never computed at all, rather than computed and then discarded. The
    ///   report pipeline should not handle data the user declined to share.
    public static func assemble(
        exportedData: ExportedData,
        range: TrainingReportRange,
        includeCycleDetail: Bool,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> TrainingReportContent {
        let (rangeStart, rangeEnd) = range.interval(endingAt: referenceDate, calendar: calendar)

        let monthlyReviews = months(from: rangeStart, to: rangeEnd, calendar: calendar).map { month in
            MonthlyReviewService.build(
                month: month,
                workouts: exportedData.workouts,
                painLogs: exportedData.painLogs,
                effortLogs: exportedData.workoutEffortLogs,
                symptomLogs: exportedData.symptomCheckInRecords,
                calendar: calendar
            )
        }

        var cycleInsights: [CycleAwareProgressInsight] = []
        var symptomInsights: [SymptomTrainingInsight] = []

        if includeCycleDetail {
            let cycleData = ChartDataAggregator.cycleCorrelation(
                from: exportedData.workouts,
                phases: exportedData.cyclePhaseInfo,
                timeRange: range.chartTimeRange,
                referenceDate: referenceDate
            )
            cycleInsights = CycleAwareProgressInsightService.build(
                cycleData: cycleData,
                workouts: exportedData.workouts,
                maxRecords: exportedData.oneRepMaxRecords
            )

            // Note: this service reports on a rolling 7-day window of its own,
            // regardless of the report's range. Its sentences say "this week"
            // explicitly, so they stay accurate inside a longer report — but
            // they describe recent days, not the whole window.
            symptomInsights = SymptomTrainingTrendService.insights(
                symptoms: exportedData.symptomCheckInRecords,
                workouts: exportedData.workouts,
                cyclePhase: nil
            )
        }

        return TrainingReportBuilder.build(
            exportedData: exportedData,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            cycleInsights: cycleInsights,
            monthlyReviews: monthlyReviews,
            symptomInsights: symptomInsights,
            includeCycleDetail: includeCycleDetail,
            calendar: calendar
        )
    }

    // MARK: - Private Helpers

    /// The first instant of each month the range touches.
    private static func months(from start: Date, to end: Date, calendar: Calendar) -> [Date] {
        guard var cursor = calendar.dateInterval(of: .month, for: start)?.start else { return [] }
        var result: [Date] = []
        while cursor < end {
            result.append(cursor)
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }
}
