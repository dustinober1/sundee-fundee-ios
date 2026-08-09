import XCTest
@testable import SundeeFundeeKit

/// Tests for `TrainingReportBuilder` — the pure assembly step behind the
/// coach-shareable training report.
///
/// Three fixture shapes are covered per the feature plan: empty-state input,
/// partial data, and a full-history fixture. Range filtering and the
/// cycle-detail privacy toggle get dedicated coverage because both are
/// correctness-critical: the report is the one artifact in the app that
/// leaves the device.
final class TrainingReportBuilderTests: XCTestCase {

    // MARK: - Fixtures

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Deterministic date in June 2026 so range boundaries are exact.
    private func makeDate(day: Int, month: Int = 6, year: Int = 2026) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        return Self.utcCalendar.date(from: components)!
    }

    private var rangeStart: Date { makeDate(day: 1) }
    private var rangeEnd: Date { makeDate(day: 30) }

    /// A workout whose `totalVolume` is exactly `volume` — one set of one rep
    /// at `volume` weight, so assertions can use precise expected numbers.
    private func makeWorkout(
        id: String = UUID().uuidString,
        name: String = "Test Workout",
        date: Date,
        completedAt: Date?,
        volume: Double = 1000
    ) -> Workout {
        Workout(
            id: id,
            date: date,
            name: name,
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

    private func makeMaxRecord(
        id: String = UUID().uuidString,
        exerciseName: String = "Back Squat",
        weight: Double = 225,
        date: Date
    ) -> OneRepMaxRecord {
        OneRepMaxRecord(
            id: id,
            exerciseName: exerciseName,
            weight: weight,
            unit: .lbs,
            date: date
        )
    }

    private func makePainLog(
        id: String = UUID().uuidString,
        locationIds: String = "knee_left",
        intensity: Int,
        painType: PainType = .acute,
        date: Date,
        notes: String? = nil
    ) -> DailyPainLog {
        DailyPainLog(
            id: id,
            locationIds: locationIds,
            intensity: intensity,
            painType: painType,
            date: date,
            notes: notes
        )
    }

    private func makeInjury(
        id: String = UUID().uuidString,
        locationIds: String = "shoulder_right",
        name: String = "Rotator cuff strain",
        recoveryPhase: RecoveryPhase = .rehab,
        dateCreated: Date,
        notes: String? = nil
    ) -> Injury {
        Injury(
            id: id,
            locationIds: locationIds,
            name: name,
            recoveryPhase: recoveryPhase,
            dateCreated: dateCreated,
            phaseUpdated: dateCreated,
            notes: notes
        )
    }

    private func makeRamp(
        id: String = UUID().uuidString,
        locationIds: String = "knee_left",
        movementPattern: WorkoutMovementPattern = .squat,
        currentWeek: Int = 3,
        maxLoadPercent: Double = 0.65,
        maxWorkingSets: Int = 3,
        dateUpdated: Date
    ) -> ReturnToLiftingRampRecord {
        ReturnToLiftingRampRecord(
            id: id,
            locationIds: locationIds,
            movementPatternRaw: movementPattern.rawValue,
            currentWeek: currentWeek,
            maxLoadPercent: maxLoadPercent,
            maxWorkingSets: maxWorkingSets,
            dateCreated: dateUpdated,
            dateUpdated: dateUpdated
        )
    }

    private func makeCycleInsight(id: String = "phase-strength") -> CycleAwareProgressInsight {
        CycleAwareProgressInsight(
            id: id,
            title: "Follicular Strength",
            value: "+8%",
            subtitle: "Squat volume trends higher in your follicular phase."
        )
    }

    private func makeSymptomInsight() -> SymptomTrainingInsight {
        SymptomTrainingInsight(
            title: "Cramps and Rest",
            message: "You rested on days you logged high cramps.",
            relatedSignal: "cramps"
        )
    }

    private func makeMonthlyReview(
        monthTitle: String = "June 2026",
        topWins: [String] = ["Hit 3 sessions a week"],
        patterns: [String] = ["Mondays are your strongest day"]
    ) -> MonthlyReview {
        MonthlyReview(
            monthTitle: monthTitle,
            workoutCount: 12,
            personalRecordCount: 2,
            topWins: topWins,
            patterns: patterns,
            nextMonthSuggestions: ["Add a fourth session"]
        )
    }

    // MARK: - Empty State

    func testEmptyExportedData_ProducesZeroedReport() {
        let report = TrainingReportBuilder.build(
            exportedData: ExportedData(),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.overview.completedWorkoutCount, 0)
        XCTAssertEqual(report.overview.totalVolume, 0, accuracy: 0.001)
        XCTAssertEqual(report.overview.personalRecordCount, 0)
        XCTAssertTrue(report.cycleAwarePatternSummary.isEmpty)
        XCTAssertTrue(report.monthlyHighlights.isEmpty)
        XCTAssertTrue(report.symptomTrainingNotes.isEmpty)
        XCTAssertTrue(report.painAndInjuryTimeline.isEmpty)
        XCTAssertTrue(report.activeReturnToLiftingRamps.isEmpty)
        XCTAssertFalse(report.includesCycleDetail)
    }

    func testEmptyExportedData_PreservesRequestedRange() {
        let report = TrainingReportBuilder.build(
            exportedData: ExportedData(),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.overview.rangeStart, rangeStart)
        XCTAssertEqual(report.overview.rangeEnd, rangeEnd)
    }

    func testEmptyFactory_MatchesBuiltEmptyReport() {
        let built = TrainingReportBuilder.build(
            exportedData: ExportedData(),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false,
            calendar: Self.utcCalendar
        )
        let factory = TrainingReportContent.empty(
            generatedAt: built.generatedAt,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            calendar: Self.utcCalendar
        )

        XCTAssertEqual(built, factory,
                       "The empty() factory should describe the same report the builder produces from empty data")
    }

    func testEmptyState_StillHonorsCycleDetailFlag() {
        let report = TrainingReportBuilder.build(
            exportedData: ExportedData(),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: true
        )

        XCTAssertTrue(report.includesCycleDetail,
                      "An empty report should still record that cycle detail was opted into")
    }

    // MARK: - Range Filtering

    func testWorkouts_OutsideRangeAreExcluded() {
        let inRange = makeWorkout(date: makeDate(day: 10), completedAt: makeDate(day: 10), volume: 1000)
        let beforeRange = makeWorkout(date: makeDate(day: 20, month: 5), completedAt: makeDate(day: 20, month: 5), volume: 500)
        let afterRange = makeWorkout(date: makeDate(day: 5, month: 7), completedAt: makeDate(day: 5, month: 7), volume: 700)

        var data = ExportedData()
        data.workouts = [inRange, beforeRange, afterRange]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.overview.completedWorkoutCount, 1)
        XCTAssertEqual(report.overview.totalVolume, 1000, accuracy: 0.001,
                       "Volume should sum only workouts completed inside the range")
    }

    func testWorkouts_RangeStartIsInclusiveAndEndIsExclusive() {
        let atStart = makeWorkout(date: rangeStart, completedAt: rangeStart, volume: 100)
        let atEnd = makeWorkout(date: rangeEnd, completedAt: rangeEnd, volume: 200)

        var data = ExportedData()
        data.workouts = [atStart, atEnd]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.overview.completedWorkoutCount, 1,
                       "rangeStart is inclusive, rangeEnd is exclusive")
        XCTAssertEqual(report.overview.totalVolume, 100, accuracy: 0.001)
    }

    func testWorkouts_IncompleteWorkoutsAreExcluded() {
        let completed = makeWorkout(date: makeDate(day: 10), completedAt: makeDate(day: 10), volume: 1000)
        let planned = makeWorkout(date: makeDate(day: 11), completedAt: nil, volume: 9999)

        var data = ExportedData()
        data.workouts = [completed, planned]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.overview.completedWorkoutCount, 1,
                       "A workout with no completedAt was never performed and must not count")
        XCTAssertEqual(report.overview.totalVolume, 1000, accuracy: 0.001,
                       "Planned-but-unperformed volume must not inflate the report")
    }

    func testPersonalRecords_FilteredByRange() {
        var data = ExportedData()
        data.oneRepMaxRecords = [
            makeMaxRecord(date: makeDate(day: 5)),
            makeMaxRecord(date: makeDate(day: 25)),
            makeMaxRecord(date: makeDate(day: 5, month: 7)),
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.overview.personalRecordCount, 2)
    }

    // MARK: - Cycle Detail Privacy Toggle

    func testCycleDetailOff_OmitsCycleAndSymptomNarration() {
        let report = TrainingReportBuilder.build(
            exportedData: ExportedData(),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            cycleInsights: [makeCycleInsight()],
            symptomInsights: [makeSymptomInsight()],
            includeCycleDetail: false
        )

        XCTAssertTrue(report.cycleAwarePatternSummary.isEmpty,
                      "Cycle narration must be omitted when the user has not opted in")
        XCTAssertTrue(report.symptomTrainingNotes.isEmpty,
                      "Symptom narration must be omitted when the user has not opted in")
        XCTAssertFalse(report.includesCycleDetail)
    }

    func testCycleDetailOn_IncludesCycleAndSymptomNarration() {
        let report = TrainingReportBuilder.build(
            exportedData: ExportedData(),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            cycleInsights: [makeCycleInsight()],
            symptomInsights: [makeSymptomInsight()],
            includeCycleDetail: true
        )

        XCTAssertEqual(report.cycleAwarePatternSummary.count, 1)
        XCTAssertEqual(report.symptomTrainingNotes, ["You rested on days you logged high cramps."])
        XCTAssertTrue(report.includesCycleDetail)
    }

    func testCycleDetailOff_DoesNotSuppressClinicallyUsefulSections() {
        var data = ExportedData()
        data.workouts = [makeWorkout(date: makeDate(day: 10), completedAt: makeDate(day: 10), volume: 1000)]
        data.painLogs = [makePainLog(intensity: 7, date: makeDate(day: 12))]
        data.injuries = [makeInjury(dateCreated: makeDate(day: 14))]
        data.returnToLiftingRampRecords = [makeRamp(dateUpdated: makeDate(day: 15))]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            monthlyReviews: [makeMonthlyReview()],
            includeCycleDetail: false
        )

        XCTAssertEqual(report.overview.completedWorkoutCount, 1)
        XCTAssertEqual(report.painAndInjuryTimeline.count, 2,
                       "Pain and injury history is the section most useful to a clinician and is not cycle detail")
        XCTAssertFalse(report.activeReturnToLiftingRamps.isEmpty)
        XCTAssertFalse(report.monthlyHighlights.isEmpty,
                       "Monthly highlights are not cycle-specific and should survive the privacy toggle")
    }

    // MARK: - Pain and Injury Timeline

    func testTimeline_MergesPainLogsAndInjuriesChronologically() {
        var data = ExportedData()
        data.painLogs = [
            makePainLog(id: "pain-late", intensity: 5, date: makeDate(day: 20)),
            makePainLog(id: "pain-early", intensity: 7, date: makeDate(day: 3)),
        ]
        data.injuries = [
            makeInjury(id: "injury-mid", dateCreated: makeDate(day: 10))
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.painAndInjuryTimeline.map(\.id),
                       ["pain-early", "injury-mid", "pain-late"],
                       "Timeline should merge both sources and sort by date ascending")
    }

    func testTimeline_FiltersByRange() {
        var data = ExportedData()
        data.painLogs = [
            makePainLog(id: "in", intensity: 5, date: makeDate(day: 10)),
            makePainLog(id: "out", intensity: 5, date: makeDate(day: 10, month: 7)),
        ]
        data.injuries = [
            makeInjury(id: "injury-out", dateCreated: makeDate(day: 10, month: 4))
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.painAndInjuryTimeline.map(\.id), ["in"])
    }

    func testTimeline_PainEntryDescribesLevelAndType() throws {
        var data = ExportedData()
        data.painLogs = [
            makePainLog(intensity: 7, painType: .sharp, date: makeDate(day: 10), notes: "Felt it on the descent")
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        let entry = try XCTUnwrap(report.painAndInjuryTimeline.first)
        XCTAssertEqual(entry.summary, "Severe sharp pain",
                       "Intensity 7 is severe; the pain type reads in lower case inside the sentence")
        XCTAssertEqual(entry.note, "Felt it on the descent")
    }

    func testTimeline_InjuryEntryDescribesNameAndPhase() {
        var data = ExportedData()
        data.injuries = [
            makeInjury(name: "Rotator cuff strain", recoveryPhase: .lightLoad, dateCreated: makeDate(day: 10))
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.painAndInjuryTimeline.first?.summary, "Rotator cuff strain (Light Load)")
    }

    func testTimeline_CarriesNilNoteThrough() {
        var data = ExportedData()
        data.painLogs = [makePainLog(intensity: 5, date: makeDate(day: 10), notes: nil)]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertNil(report.painAndInjuryTimeline.first?.note)
    }

    // MARK: - Return-to-Lifting Ramps

    func testRamps_FilteredByUpdateDate() {
        var data = ExportedData()
        data.returnToLiftingRampRecords = [
            makeRamp(dateUpdated: makeDate(day: 10)),
            makeRamp(dateUpdated: makeDate(day: 10, month: 7)),
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.activeReturnToLiftingRamps.count, 1)
    }

    func testRampSummary_StatesWeekLoadAndSets() {
        var data = ExportedData()
        data.returnToLiftingRampRecords = [
            makeRamp(currentWeek: 4, maxLoadPercent: 0.65, maxWorkingSets: 3, dateUpdated: makeDate(day: 10))
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(
            report.activeReturnToLiftingRamps.first,
            "Week 4 of a gradual return to training: working loads are capped at 65% of usual "
                + "working weight, with up to 3 working sets per exercise."
        )
    }

    // MARK: - Monthly Highlights

    func testMonthlyHighlights_CombineWinsAndPatterns() {
        let report = TrainingReportBuilder.build(
            exportedData: ExportedData(),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            monthlyReviews: [makeMonthlyReview(topWins: ["Win A"], patterns: ["Pattern A"])],
            includeCycleDetail: false
        )

        XCTAssertEqual(report.monthlyHighlights, ["Win A", "Pattern A"])
    }

    func testMonthlyHighlights_CappedAtSixEntries() {
        let wins = (1...4).map { "Win \($0)" }
        let patterns = (1...4).map { "Pattern \($0)" }
        let reviews = [
            makeMonthlyReview(monthTitle: "May 2026", topWins: wins, patterns: patterns),
            makeMonthlyReview(monthTitle: "June 2026", topWins: wins, patterns: patterns),
        ]

        let report = TrainingReportBuilder.build(
            exportedData: ExportedData(),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            monthlyReviews: reviews,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.monthlyHighlights.count, 6,
                       "A shareable report should stay readable; highlights are capped")
        XCTAssertEqual(report.monthlyHighlights.first, "Win 1")
    }

    // MARK: - Partial Data

    func testPartialData_WorkoutsOnlyStillProducesValidReport() {
        var data = ExportedData()
        data.workouts = [
            makeWorkout(date: makeDate(day: 5), completedAt: makeDate(day: 5), volume: 1200),
            makeWorkout(date: makeDate(day: 12), completedAt: makeDate(day: 12), volume: 800),
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.overview.completedWorkoutCount, 2)
        XCTAssertEqual(report.overview.totalVolume, 2000, accuracy: 0.001)
        XCTAssertEqual(report.overview.personalRecordCount, 0)
        XCTAssertTrue(report.painAndInjuryTimeline.isEmpty,
                      "No pain history should read as an empty section, not a failure")
    }

    func testPartialData_PainHistoryWithNoTrainingIsStillReported() {
        var data = ExportedData()
        data.painLogs = [makePainLog(intensity: 6, date: makeDate(day: 8))]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        XCTAssertEqual(report.overview.completedWorkoutCount, 0)
        XCTAssertEqual(report.painAndInjuryTimeline.count, 1,
                       "A user who logged pain but did not train still has something worth showing a clinician")
    }

    // MARK: - Full History

    func testFullHistory_PopulatesEverySection() {
        var data = ExportedData()
        data.workouts = [
            makeWorkout(date: makeDate(day: 2), completedAt: makeDate(day: 2), volume: 1000),
            makeWorkout(date: makeDate(day: 9), completedAt: makeDate(day: 9), volume: 1500),
            makeWorkout(date: makeDate(day: 16), completedAt: makeDate(day: 16), volume: 1250),
            makeWorkout(date: makeDate(day: 23), completedAt: nil, volume: 999),
        ]
        data.oneRepMaxRecords = [
            makeMaxRecord(exerciseName: "Back Squat", weight: 245, date: makeDate(day: 9)),
            makeMaxRecord(exerciseName: "Deadlift", weight: 315, date: makeDate(day: 23)),
        ]
        data.painLogs = [
            makePainLog(intensity: 6, painType: .aching, date: makeDate(day: 4), notes: "After squats"),
            makePainLog(intensity: 3, painType: .soreness, date: makeDate(day: 18)),
        ]
        data.injuries = [
            makeInjury(name: "Rotator cuff strain", recoveryPhase: .rehab, dateCreated: makeDate(day: 11))
        ]
        data.returnToLiftingRampRecords = [
            makeRamp(currentWeek: 2, maxLoadPercent: 0.55, maxWorkingSets: 3, dateUpdated: makeDate(day: 20))
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            cycleInsights: [makeCycleInsight()],
            monthlyReviews: [makeMonthlyReview()],
            symptomInsights: [makeSymptomInsight()],
            includeCycleDetail: true
        )

        XCTAssertEqual(report.overview.completedWorkoutCount, 3)
        XCTAssertEqual(report.overview.totalVolume, 3750, accuracy: 0.001)
        XCTAssertEqual(report.overview.personalRecordCount, 2)
        XCTAssertEqual(report.painAndInjuryTimeline.count, 3)
        XCTAssertEqual(report.activeReturnToLiftingRamps.count, 1)
        XCTAssertFalse(report.cycleAwarePatternSummary.isEmpty)
        XCTAssertFalse(report.monthlyHighlights.isEmpty)
        XCTAssertFalse(report.symptomTrainingNotes.isEmpty)
        XCTAssertTrue(report.includesCycleDetail)
    }

    func testFullHistory_TimelineStaysSorted() {
        var data = ExportedData()
        data.painLogs = (1...5).map { day in
            makePainLog(intensity: 5, date: makeDate(day: day * 4))
        }
        data.injuries = (1...3).map { day in
            makeInjury(dateCreated: makeDate(day: day * 6))
        }

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )

        let dates = report.painAndInjuryTimeline.map(\.date)
        XCTAssertEqual(dates, dates.sorted(), "Merged timeline must stay chronologically ordered")
        XCTAssertEqual(dates.count, 8)
    }

    // MARK: - Narrated Session Summary

    func testSessionSummary_NarratesOverviewFigures() {
        var data = ExportedData()
        data.workouts = [
            makeWorkout(date: makeDate(day: 5), completedAt: makeDate(day: 5), volume: 1200),
            makeWorkout(date: makeDate(day: 12), completedAt: makeDate(day: 12), volume: 800),
        ]
        data.oneRepMaxRecords = [makeMaxRecord(date: makeDate(day: 12))]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false,
            calendar: Self.utcCalendar
        )

        XCTAssertEqual(report.sessionSummary, [
            "2 training sessions were logged between June 1, 2026 and June 29, 2026 — "
                + "an average of 0.5 per week.",
            "Total training volume over this period was 2,000 (weight lifted × repetitions).",
            "1 new maximum-lift record was logged.",
        ])
    }

    func testSessionSummary_EmptyRangeReadsAsDeliberate() {
        let report = TrainingReportBuilder.build(
            exportedData: ExportedData(),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false,
            calendar: Self.utcCalendar
        )

        XCTAssertEqual(report.sessionSummary,
                       ["No training sessions were logged between June 1, 2026 and June 29, 2026."],
                       "An empty report should say nothing was logged, not render as a blank page")
    }

    func testSessionSummary_AppendsVolumeTrendWhenEnoughSessions() {
        var data = ExportedData()
        // Four sessions: first half light, second half heavy.
        data.workouts = [
            makeWorkout(date: makeDate(day: 3), completedAt: makeDate(day: 3), volume: 500),
            makeWorkout(date: makeDate(day: 7), completedAt: makeDate(day: 7), volume: 500),
            makeWorkout(date: makeDate(day: 20), completedAt: makeDate(day: 20), volume: 1000),
            makeWorkout(date: makeDate(day: 24), completedAt: makeDate(day: 24), volume: 1000),
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false,
            calendar: Self.utcCalendar
        )

        XCTAssertEqual(report.sessionSummary.last,
                       "Training volume in the second half of this period was about 100% higher "
                           + "than in the first half.")
    }

    func testSessionSummary_OmitsVolumeTrendWhenTooFewSessions() {
        var data = ExportedData()
        data.workouts = [
            makeWorkout(date: makeDate(day: 3), completedAt: makeDate(day: 3), volume: 500),
            makeWorkout(date: makeDate(day: 24), completedAt: makeDate(day: 24), volume: 2000),
        ]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false,
            calendar: Self.utcCalendar
        )

        XCTAssertFalse(
            report.sessionSummary.contains { $0.contains("second half") },
            "Two sessions cannot support a trend claim, however large the difference looks"
        )
    }

    func testSessionSummary_IsNotGatedByCycleDetailToggle() {
        var data = ExportedData()
        data.workouts = [makeWorkout(date: makeDate(day: 5), completedAt: makeDate(day: 5), volume: 900)]

        let report = TrainingReportBuilder.build(
            exportedData: data,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false,
            calendar: Self.utcCalendar
        )

        XCTAssertFalse(report.sessionSummary.isEmpty,
                       "Session counts carry no cycle information and must survive the privacy toggle")
    }

    // MARK: - Generation Metadata

    func testGeneratedAt_IsStampedAtBuildTime() {
        let before = Date()
        let report = TrainingReportBuilder.build(
            exportedData: ExportedData(),
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            includeCycleDetail: false
        )
        let after = Date()

        XCTAssertGreaterThanOrEqual(report.generatedAt, before)
        XCTAssertLessThanOrEqual(report.generatedAt, after)
    }
}
