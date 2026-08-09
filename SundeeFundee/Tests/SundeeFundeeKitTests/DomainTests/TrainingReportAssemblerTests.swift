import XCTest
@testable import SundeeFundeeKit

/// Tests for `TrainingReportRange` and `TrainingReportAssembler` — the step
/// that runs the existing insight services and feeds `TrainingReportBuilder`.
final class TrainingReportAssemblerTests: XCTestCase {

    // MARK: - Fixtures

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Fixed "today" so range arithmetic is deterministic.
    private var referenceDate: Date {
        Self.utcCalendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 14))!
    }

    private func date(_ day: Int, month: Int = 6, year: Int = 2026) -> Date {
        Self.utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeWorkout(completedAt: Date?, volume: Double = 1000) -> Workout {
        Workout(
            date: completedAt ?? Date(),
            name: "Session",
            exercises: [
                Exercise(
                    id: UUID().uuidString,
                    name: "Back Squat",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(
                            reps: 1,
                            prescribedWeight: 0,
                            type: .fixed,
                            completedWeight: volume,
                            isComplete: true
                        )
                    ]
                )
            ],
            completedAt: completedAt
        )
    }

    private func assemble(
        _ data: ExportedData,
        range: TrainingReportRange = .last30Days,
        includeCycleDetail: Bool = false
    ) -> TrainingReportContent {
        TrainingReportAssembler.assemble(
            exportedData: data,
            range: range,
            includeCycleDetail: includeCycleDetail,
            referenceDate: referenceDate,
            calendar: Self.utcCalendar
        )
    }

    // MARK: - Range Arithmetic

    func testRange_EndsAtStartOfTomorrowSoTodayCounts() {
        let (_, end) = TrainingReportRange.last30Days.interval(
            endingAt: referenceDate,
            calendar: Self.utcCalendar
        )

        XCTAssertEqual(end, date(16).addingTimeInterval(-12 * 3600),
                       "Range should end at the start of tomorrow, not the current instant")
    }

    func testRange_SpansTheStatedNumberOfDays() {
        for range in TrainingReportRange.allCases {
            let (start, end) = range.interval(endingAt: referenceDate, calendar: Self.utcCalendar)
            let days = Self.utcCalendar.dateComponents([.day], from: start, to: end).day

            XCTAssertEqual(days, range.days, "\(range.displayName) should span \(range.days) days")
        }
    }

    func testRange_MapsToMatchingAnalyticsWindow() {
        XCTAssertEqual(TrainingReportRange.last30Days.chartTimeRange, .lastMonth)
        XCTAssertEqual(TrainingReportRange.last90Days.chartTimeRange, .lastThreeMonths)
        XCTAssertEqual(TrainingReportRange.lastYear.chartTimeRange, .lastYear)
    }

    func testRange_WorkoutCompletedTodayIsIncluded() {
        var data = ExportedData()
        data.workouts = [makeWorkout(completedAt: date(15))]

        XCTAssertEqual(assemble(data).overview.completedWorkoutCount, 1,
                       "A session logged earlier today must appear in the report")
    }

    func testRange_WorkoutOlderThanWindowIsExcluded() {
        var data = ExportedData()
        data.workouts = [
            makeWorkout(completedAt: date(10)),
            makeWorkout(completedAt: date(1, month: 3)),
        ]

        XCTAssertEqual(assemble(data, range: .last30Days).overview.completedWorkoutCount, 1)
        XCTAssertEqual(assemble(data, range: .lastYear).overview.completedWorkoutCount, 2,
                       "A wider range should pick the older session back up")
    }

    // MARK: - Privacy

    func testCycleDetailOff_ProducesNoCycleOrSymptomContent() {
        var data = ExportedData()
        data.workouts = (1...6).map { makeWorkout(completedAt: date($0 + 1)) }
        data.cyclePhaseInfo = []
        data.symptomCheckInRecords = []

        let content = assemble(data, includeCycleDetail: false)

        XCTAssertTrue(content.cycleAwarePatternSummary.isEmpty)
        XCTAssertTrue(content.symptomTrainingNotes.isEmpty)
        XCTAssertFalse(content.includesCycleDetail)
    }

    func testCycleDetailOn_RunsTheCycleInsightService() {
        var data = ExportedData()
        data.workouts = (1...6).map { makeWorkout(completedAt: date($0 + 1)) }

        let content = assemble(data, includeCycleDetail: true)

        XCTAssertTrue(content.includesCycleDetail)
        XCTAssertFalse(content.cycleAwarePatternSummary.isEmpty,
                       "With cycle detail on, the insight service should contribute at least its "
                           + "needs-more-data guidance rather than an empty section")
    }

    func testCycleDetailOff_StillReportsTrainingAndPain() {
        var data = ExportedData()
        data.workouts = [makeWorkout(completedAt: date(10), volume: 1500)]
        data.painLogs = [
            DailyPainLog(id: "p1", locationIds: "knee_left", intensity: 6,
                         painType: .aching, date: date(11), notes: nil)
        ]

        let content = assemble(data, includeCycleDetail: false)

        XCTAssertEqual(content.overview.completedWorkoutCount, 1)
        XCTAssertEqual(content.painAndInjuryTimeline.count, 1,
                       "Pain history is not cycle detail and stays in the report")
        XCTAssertFalse(content.sessionSummary.isEmpty)
    }

    // MARK: - Monthly Reviews

    func testMonthlyReviews_CoverEveryMonthTheRangeTouches() {
        var data = ExportedData()
        // Range is May 17 – June 16, touching two months.
        data.workouts = [
            makeWorkout(completedAt: date(20, month: 5)),
            makeWorkout(completedAt: date(10)),
        ]

        let content = assemble(data, range: .last30Days)

        XCTAssertFalse(content.monthlyHighlights.isEmpty,
                       "A range spanning May and June should produce reviews for both")
    }

    // MARK: - Empty State

    func testEmptyData_ProducesAValidEmptyReport() {
        let content = assemble(ExportedData())

        XCTAssertEqual(content.overview.completedWorkoutCount, 0)
        XCTAssertTrue(content.painAndInjuryTimeline.isEmpty)
        XCTAssertEqual(content.sessionSummary.count, 1)
        XCTAssertTrue(content.sessionSummary[0].hasPrefix("No training sessions were logged"))
    }

    func testEmptyData_DocumentStillRenders() {
        let document = TrainingReportDocument.make(
            from: assemble(ExportedData()),
            calendar: Self.utcCalendar
        )

        XCTAssertEqual(document.blocks.first, .title("Training Summary"))
        XCTAssertTrue(document.blocks.contains(.footnote(TrainingReportDocument.disclaimer)))
    }

    // MARK: - End to End

    func testFullPipeline_ProducesEverySection() {
        var data = ExportedData()
        data.workouts = (1...8).map { makeWorkout(completedAt: date($0 + 2), volume: Double($0) * 250) }
        data.oneRepMaxRecords = [
            OneRepMaxRecord(id: "m1", exerciseName: "Deadlift", weight: 315, unit: .lbs, date: date(9))
        ]
        data.painLogs = [
            DailyPainLog(id: "p1", locationIds: "knee_left", intensity: 7,
                         painType: .sharp, date: date(6), notes: "After squats")
        ]
        data.injuries = [
            Injury(id: "i1", locationIds: "shoulder_right", name: "Rotator cuff strain",
                   recoveryPhase: .rehab, dateCreated: date(8), phaseUpdated: date(8), notes: nil)
        ]
        data.returnToLiftingRampRecords = [
            ReturnToLiftingRampRecord(
                id: "r1",
                locationIds: "knee_left",
                movementPatternRaw: WorkoutMovementPattern.squat.rawValue,
                currentWeek: 2,
                maxLoadPercent: 0.55,
                maxWorkingSets: 3,
                dateCreated: date(5),
                dateUpdated: date(12)
            )
        ]

        let content = assemble(data, range: .last90Days, includeCycleDetail: true)
        let document = TrainingReportDocument.make(from: content, calendar: Self.utcCalendar)

        XCTAssertEqual(content.overview.completedWorkoutCount, 8)
        XCTAssertEqual(content.overview.personalRecordCount, 1)
        XCTAssertEqual(content.painAndInjuryTimeline.count, 2)
        XCTAssertEqual(content.activeReturnToLiftingRamps.count, 1)

        let headings = document.blocks.compactMap { block -> String? in
            if case .heading(let text) = block { return text }
            return nil
        }
        XCTAssertTrue(headings.contains(TrainingReportDocument.Section.sessionOverview))
        XCTAssertTrue(headings.contains(TrainingReportDocument.Section.painTimeline))
        XCTAssertTrue(headings.contains(TrainingReportDocument.Section.returnToTraining))
    }
}
