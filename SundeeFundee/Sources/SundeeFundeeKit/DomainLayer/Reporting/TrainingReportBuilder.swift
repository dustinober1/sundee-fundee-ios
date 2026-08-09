import Foundation

// MARK: - TrainingReportBuilder

/// Builds a `TrainingReportContent` from exported user data plus the
/// already-computed output of the existing insight services.
///
/// Deliberately takes `cycleInsights`, `monthlyReviews`, and
/// `symptomInsights` as inputs rather than recomputing them from raw data —
/// `CycleAwareProgressInsightService`, `MonthlyReviewService`, and
/// `SymptomTrainingTrendService` already own that logic. This type only
/// narrates and assembles.
public enum TrainingReportBuilder {
    /// - Parameters:
    ///   - exportedData: The full exported data set (see `DataExportService.exportAll()`).
    ///   - rangeStart: Inclusive start of the report window.
    ///   - rangeEnd: Exclusive end of the report window.
    ///   - cycleInsights: Output of `CycleAwareProgressInsightService.build(...)`, if available.
    ///   - monthlyReviews: Output of `MonthlyReviewService.build(...)` for each month touched by the range.
    ///   - symptomInsights: Output of `SymptomTrainingTrendService.insights(...)`, if available.
    ///   - includeCycleDetail: Per-report privacy toggle. When false, cycle-phase and symptom
    ///     narration is omitted from the report even if the insight arrays are non-empty —
    ///     the caller still computes them (for in-app use) but the report simply won't surface
    ///     them. Session overview and pain/injury timeline are not considered cycle detail and
    ///     are always included, since those are the sections most useful to share with a
    ///     clinician or trainer.
    ///   - calendar: Calendar used for date arithmetic in the narrated
    ///     sentences. Injectable so report prose is deterministic under test.
    public static func build(
        exportedData: ExportedData,
        rangeStart: Date,
        rangeEnd: Date,
        cycleInsights: [CycleAwareProgressInsight] = [],
        monthlyReviews: [MonthlyReview] = [],
        symptomInsights: [SymptomTrainingInsight] = [],
        includeCycleDetail: Bool,
        calendar: Calendar = .current
    ) -> TrainingReportContent {
        let completedWorkouts = exportedData.workouts.filter { workout in
            guard let completedAt = workout.completedAt else { return false }
            return completedAt >= rangeStart && completedAt < rangeEnd
        }

        let totalVolume = completedWorkouts.reduce(0.0) { $0 + $1.totalVolume }

        let recordsInRange = exportedData.oneRepMaxRecords.filter {
            $0.date >= rangeStart && $0.date < rangeEnd
        }

        let overview = TrainingReportContent.Overview(
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            completedWorkoutCount: completedWorkouts.count,
            totalVolume: totalVolume,
            personalRecordCount: recordsInRange.count
        )

        var sessionSummary = ReportNarrator.narrateOverview(overview, calendar: calendar)
        if let trend = ReportNarrator.narrateVolumeTrend(
            completedWorkouts: completedWorkouts,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd
        ) {
            sessionSummary.append(trend)
        }

        let cyclePatternSummary = includeCycleDetail
            ? cycleInsights.map(ReportNarrator.narrate(cycleInsight:))
            : []

        let symptomNotes = includeCycleDetail
            ? symptomInsights.map(ReportNarrator.narrate(symptomInsight:))
            : []

        let monthlyHighlights = Array(
            monthlyReviews.flatMap { $0.topWins + $0.patterns }.prefix(6)
        )

        let painTimeline = buildPainTimeline(
            painLogs: exportedData.painLogs,
            injuries: exportedData.injuries,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd
        )

        let rampSummaries = exportedData.returnToLiftingRampRecords
            .filter { $0.dateUpdated >= rangeStart && $0.dateUpdated < rangeEnd }
            .map(ReportNarrator.narrate(ramp:))

        return TrainingReportContent(
            generatedAt: Date(),
            overview: overview,
            sessionSummary: sessionSummary,
            cycleAwarePatternSummary: cyclePatternSummary,
            monthlyHighlights: monthlyHighlights,
            symptomTrainingNotes: symptomNotes,
            painAndInjuryTimeline: painTimeline,
            activeReturnToLiftingRamps: rampSummaries,
            includesCycleDetail: includeCycleDetail
        )
    }

    // MARK: - Private Helpers

    private static func buildPainTimeline(
        painLogs: [DailyPainLog],
        injuries: [Injury],
        rangeStart: Date,
        rangeEnd: Date
    ) -> [TrainingReportContent.PainTimelineEntry] {
        let painEntries = painLogs
            .filter { $0.date >= rangeStart && $0.date < rangeEnd }
            .map { log -> TrainingReportContent.PainTimelineEntry in
                let level = PainLevel.from(intensity: log.intensity)
                return TrainingReportContent.PainTimelineEntry(
                    id: log.id,
                    date: log.date,
                    summary: "\(level.displayName) \(log.painType.displayName.lowercased())",
                    note: log.notes
                )
            }

        let injuryEntries = injuries
            .filter { $0.dateCreated >= rangeStart && $0.dateCreated < rangeEnd }
            .map { injury -> TrainingReportContent.PainTimelineEntry in
                TrainingReportContent.PainTimelineEntry(
                    id: injury.id,
                    date: injury.dateCreated,
                    summary: "\(injury.name) (\(injury.recoveryPhase.displayName))",
                    note: injury.notes
                )
            }

        return (painEntries + injuryEntries).sorted { $0.date < $1.date }
    }
}
