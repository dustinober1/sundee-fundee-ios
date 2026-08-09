import XCTest
@testable import SundeeFundeeKit

/// Tests for `ReportNarrator` — the rules that turn chart-oriented insight
/// output into sentences a reader outside the app can understand.
///
/// Narration is the report's differentiator, so these tests assert on exact
/// sentences rather than substrings: the wording is the feature, and a silent
/// change to it should fail loudly.
final class ReportNarratorTests: XCTestCase {

    // MARK: - Fixtures

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func makeDate(day: Int, month: Int = 6, year: Int = 2026) -> Date {
        Self.utcCalendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makeOverview(
        rangeStart: Date? = nil,
        rangeEnd: Date? = nil,
        completedWorkoutCount: Int = 0,
        totalVolume: Double = 0,
        personalRecordCount: Int = 0
    ) -> TrainingReportContent.Overview {
        TrainingReportContent.Overview(
            rangeStart: rangeStart ?? makeDate(day: 1),
            rangeEnd: rangeEnd ?? makeDate(day: 30),
            completedWorkoutCount: completedWorkoutCount,
            totalVolume: totalVolume,
            personalRecordCount: personalRecordCount
        )
    }

    private func narrate(_ overview: TrainingReportContent.Overview) -> [String] {
        ReportNarrator.narrateOverview(overview, calendar: Self.utcCalendar)
    }

    private func makeWorkout(completedAt: Date?, volume: Double) -> Workout {
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

    // MARK: - Overview: Session Count

    func testOverview_NoSessionsReadsAsDeliberateStatement() {
        XCTAssertEqual(
            narrate(makeOverview(completedWorkoutCount: 0)),
            ["No training sessions were logged between June 1, 2026 and June 29, 2026."]
        )
    }

    func testOverview_SingleSessionUsesSingularVerb() {
        let sentences = narrate(makeOverview(completedWorkoutCount: 1))
        XCTAssertEqual(
            sentences.first,
            "1 training session was logged between June 1, 2026 and June 29, 2026 — "
                + "an average of 0.2 per week."
        )
    }

    func testOverview_MultipleSessionsUsePluralVerb() {
        let sentences = narrate(makeOverview(completedWorkoutCount: 12))
        XCTAssertEqual(
            sentences.first,
            "12 training sessions were logged between June 1, 2026 and June 29, 2026 — "
                + "an average of 2.9 per week."
        )
    }

    func testOverview_EndDateIsReportedInclusively() {
        // The build range is half-open. Printing rangeEnd itself would claim a
        // day the report does not cover.
        let sentences = narrate(makeOverview(
            rangeStart: makeDate(day: 1),
            rangeEnd: makeDate(day: 8),
            completedWorkoutCount: 3
        ))

        XCTAssertTrue(sentences[0].contains("June 1, 2026 and June 7, 2026"),
                      "Exclusive end date must be reported as the last covered day, got: \(sentences[0])")
    }

    func testOverview_ShortWindowOmitsWeeklyAverage() {
        let sentences = narrate(makeOverview(
            rangeStart: makeDate(day: 1),
            rangeEnd: makeDate(day: 4),
            completedWorkoutCount: 2
        ))

        XCTAssertEqual(sentences.first,
                       "2 training sessions were logged between June 1, 2026 and June 3, 2026.")
        XCTAssertFalse(sentences[0].contains("per week"),
                       "A three-day window cannot support a per-week average")
    }

    // MARK: - Overview: Volume and Records

    func testOverview_VolumeIsGroupedAndUnitQualified() {
        let sentences = narrate(makeOverview(completedWorkoutCount: 5, totalVolume: 128_500))

        XCTAssertTrue(
            sentences.contains(
                "Total training volume over this period was 128,500 (weight lifted × repetitions)."
            ),
            "Volume needs a thousands separator and an explanation of what the number is, got: \(sentences)"
        )
    }

    func testOverview_ZeroVolumeIsOmittedRatherThanStatedAsZero() {
        let sentences = narrate(makeOverview(completedWorkoutCount: 2, totalVolume: 0))

        XCTAssertFalse(sentences.contains { $0.contains("Total training volume") },
                       "A zero-volume line adds nothing to a report and should be left out")
    }

    func testOverview_SingleRecordUsesSingularVerb() {
        let sentences = narrate(makeOverview(completedWorkoutCount: 5, personalRecordCount: 1))
        XCTAssertTrue(sentences.contains("1 new maximum-lift record was logged."))
    }

    func testOverview_MultipleRecordsUsePluralVerb() {
        let sentences = narrate(makeOverview(completedWorkoutCount: 5, personalRecordCount: 4))
        XCTAssertTrue(sentences.contains("4 new maximum-lift records were logged."))
    }

    func testOverview_NoRecordsOmitsTheLine() {
        let sentences = narrate(makeOverview(completedWorkoutCount: 5, personalRecordCount: 0))
        XCTAssertFalse(sentences.contains { $0.contains("maximum-lift") })
    }

    // MARK: - Volume Trend

    func testVolumeTrend_NilBelowFourSessions() {
        let workouts = [
            makeWorkout(completedAt: makeDate(day: 3), volume: 100),
            makeWorkout(completedAt: makeDate(day: 25), volume: 5000),
        ]

        XCTAssertNil(
            ReportNarrator.narrateVolumeTrend(
                completedWorkouts: workouts,
                rangeStart: makeDate(day: 1),
                rangeEnd: makeDate(day: 30)
            ),
            "Three sessions or fewer cannot support a trend claim in a clinical report"
        )
    }

    func testVolumeTrend_ReportsIncrease() {
        let workouts = [
            makeWorkout(completedAt: makeDate(day: 3), volume: 1000),
            makeWorkout(completedAt: makeDate(day: 7), volume: 1000),
            makeWorkout(completedAt: makeDate(day: 20), volume: 1500),
            makeWorkout(completedAt: makeDate(day: 24), volume: 1500),
        ]

        XCTAssertEqual(
            ReportNarrator.narrateVolumeTrend(
                completedWorkouts: workouts,
                rangeStart: makeDate(day: 1),
                rangeEnd: makeDate(day: 30)
            ),
            "Training volume in the second half of this period was about 50% higher than in the first half."
        )
    }

    func testVolumeTrend_ReportsDecrease() {
        let workouts = [
            makeWorkout(completedAt: makeDate(day: 3), volume: 2000),
            makeWorkout(completedAt: makeDate(day: 7), volume: 2000),
            makeWorkout(completedAt: makeDate(day: 20), volume: 500),
            makeWorkout(completedAt: makeDate(day: 24), volume: 500),
        ]

        XCTAssertEqual(
            ReportNarrator.narrateVolumeTrend(
                completedWorkouts: workouts,
                rangeStart: makeDate(day: 1),
                rangeEnd: makeDate(day: 30)
            ),
            "Training volume in the second half of this period was about 75% lower than in the first half."
        )
    }

    func testVolumeTrend_SmallChangeReadsAsSteady() {
        let workouts = [
            makeWorkout(completedAt: makeDate(day: 3), volume: 1000),
            makeWorkout(completedAt: makeDate(day: 7), volume: 1000),
            makeWorkout(completedAt: makeDate(day: 20), volume: 1020),
            makeWorkout(completedAt: makeDate(day: 24), volume: 1020),
        ]

        XCTAssertEqual(
            ReportNarrator.narrateVolumeTrend(
                completedWorkouts: workouts,
                rangeStart: makeDate(day: 1),
                rangeEnd: makeDate(day: 30)
            ),
            "Training volume stayed roughly steady across this period.",
            "A 2% swing is noise and must not be narrated as a direction"
        )
    }

    func testVolumeTrend_NilWhenFirstHalfHasNoVolume() {
        let workouts = [
            makeWorkout(completedAt: makeDate(day: 20), volume: 1000),
            makeWorkout(completedAt: makeDate(day: 21), volume: 1000),
            makeWorkout(completedAt: makeDate(day: 24), volume: 1000),
            makeWorkout(completedAt: makeDate(day: 26), volume: 1000),
        ]

        XCTAssertNil(
            ReportNarrator.narrateVolumeTrend(
                completedWorkouts: workouts,
                rangeStart: makeDate(day: 1),
                rangeEnd: makeDate(day: 30)
            ),
            "Percent change from a zero baseline is undefined and must not be invented"
        )
    }

    // MARK: - Cycle Insight Narration

    private func makeCycleInsight(
        id: String,
        title: String = "Title",
        value: String = "Value",
        subtitle: String = ""
    ) -> CycleAwareProgressInsight {
        CycleAwareProgressInsight(id: id, title: title, value: value, subtitle: subtitle)
    }

    func testCycleInsight_NeedsMoreDataExplainsWhatIsMissing() {
        let sentence = ReportNarrator.narrate(cycleInsight: makeCycleInsight(
            id: "needs-more-data",
            title: "Cycle Insight Needs More Data",
            value: "Log 2+ workouts per phase",
            subtitle: "More phase-linked workouts are needed before trend guidance is reliable."
        ))

        XCTAssertEqual(
            sentence,
            "There is not yet enough phase-linked training data to describe cycle patterns reliably. "
                + "At least two logged workouts per cycle phase are needed before any trend is meaningful."
        )
    }

    func testCycleInsight_StrongestPhaseNamesThePhaseInASentence() {
        let sentence = ReportNarrator.narrate(cycleInsight: makeCycleInsight(
            id: "strongest-phase",
            title: "Strongest Phase",
            value: "Follicular",
            subtitle: "Highest average volume with 4 tracked workouts."
        ))

        XCTAssertEqual(
            sentence,
            "Training volume was highest during the follicular phase. "
                + "Highest average volume with 4 tracked workouts."
        )
    }

    func testCycleInsight_LowestPhaseAvoidsClinicalFraming() {
        let sentence = ReportNarrator.narrate(cycleInsight: makeCycleInsight(
            id: "lowest-phase",
            title: "Most Challenging Phase",
            value: "Luteal",
            subtitle: "Lowest average volume; consider pre-planned modifications in this window."
        ))

        XCTAssertTrue(sentence.hasPrefix("Training volume was lowest during the luteal phase,"))
        XCTAssertTrue(sentence.contains("plan lighter sessions in advance"))
    }

    func testCycleInsight_LatestPRKeepsTheLoggedWeight() {
        let sentence = ReportNarrator.narrate(cycleInsight: makeCycleInsight(
            id: "latest-pr",
            title: "Latest PR Context",
            value: "Deadlift",
            subtitle: "Most recent max log: 315 lbs."
        ))

        XCTAssertEqual(
            sentence,
            "The most recent maximum-lift record logged was for Deadlift. Most recent max log: 315 lbs.",
            "The weight lives only in the subtitle, so dropping it would lose the number that matters"
        )
    }

    func testCycleInsight_UnknownIdentifierStillProducesReadableText() {
        let sentence = ReportNarrator.narrate(cycleInsight: makeCycleInsight(
            id: "some-future-insight",
            title: "Recovery Streak",
            value: "6 days",
            subtitle: "Longest streak this quarter."
        ))

        XCTAssertEqual(sentence, "Recovery Streak: 6 days. Longest streak this quarter.",
                       "An insight added upstream must degrade gracefully, not vanish from the report")
    }

    func testCycleInsight_EmptySubtitleLeavesNoTrailingSpace() {
        let sentence = ReportNarrator.narrate(cycleInsight: makeCycleInsight(
            id: "strongest-phase",
            value: "Ovulation",
            subtitle: ""
        ))

        XCTAssertEqual(sentence, "Training volume was highest during the ovulation phase.")
    }

    // MARK: - Symptom Insight Narration

    func testSymptomInsight_NormalizesTrailingWhitespaceFromEmptyPhaseContext() {
        // SymptomTrainingTrendService composes messages by concatenation and
        // appends an empty string when the cycle phase is unknown.
        let insight = SymptomTrainingInsight(
            title: "Movement Patterns This Week",
            message: "Cramps have been prominent this week and no workouts were logged. "
                + "Gentle movement like walking or stretching can sometimes help. ",
            relatedSignal: "cramps"
        )

        let sentence = ReportNarrator.narrate(symptomInsight: insight)

        XCTAssertFalse(sentence.hasSuffix(" "), "Trailing space would render as a stray gap in the PDF")
        XCTAssertEqual(
            sentence,
            "Cramps have been prominent this week and no workouts were logged. "
                + "Gentle movement like walking or stretching can sometimes help."
        )
    }

    func testSymptomInsight_CollapsesInternalDoubleSpaces() {
        let insight = SymptomTrainingInsight(
            title: "Rest and Balance",
            message: "Fatigue has been elevated this week.  Listening to your body matters.",
            relatedSignal: "fatigue"
        )

        XCTAssertEqual(
            ReportNarrator.narrate(symptomInsight: insight),
            "Fatigue has been elevated this week. Listening to your body matters."
        )
    }

    func testSymptomInsight_PreservesCarefullyWordedCopy() {
        let message = "Energy levels have been high and 4 workouts were completed this week. "
            + "This is a great rhythm — keep it going."
        let insight = SymptomTrainingInsight(
            title: "Strong Consistency",
            message: message,
            relatedSignal: "energy"
        )

        XCTAssertEqual(ReportNarrator.narrate(symptomInsight: insight), message,
                       "Non-diagnostic copy is deliberate and must pass through unrewritten")
    }

    // MARK: - Ramp Narration

    func testRamp_ExplainsCapsWithoutAppJargon() {
        let ramp = ReturnToLiftingRampRecord(
            id: "ramp-1",
            locationIds: "knee_left",
            movementPatternRaw: WorkoutMovementPattern.squat.rawValue,
            currentWeek: 3,
            maxLoadPercent: 0.6,
            maxWorkingSets: 2,
            dateCreated: makeDate(day: 1),
            dateUpdated: makeDate(day: 15)
        )

        XCTAssertEqual(
            ReportNarrator.narrate(ramp: ramp),
            "Week 3 of a gradual return to training: working loads are capped at 60% of usual "
                + "working weight, with up to 2 working sets per exercise."
        )
    }

    func testRamp_SingleSetUsesSingularNoun() {
        let ramp = ReturnToLiftingRampRecord(
            id: "ramp-2",
            locationIds: "shoulder_right",
            movementPatternRaw: WorkoutMovementPattern.push.rawValue,
            currentWeek: 1,
            maxLoadPercent: 0.3,
            maxWorkingSets: 1,
            dateCreated: makeDate(day: 1),
            dateUpdated: makeDate(day: 2)
        )

        XCTAssertTrue(ReportNarrator.narrate(ramp: ramp).hasSuffix("up to 1 working set per exercise."))
    }

    // MARK: - Language Discipline

    func testNarration_AvoidsClinicalClaims() {
        // Mirrors the forbidden-term check already enforced on
        // ReturnToLiftingRampService copy. A report handed to a clinician is
        // exactly where an implied diagnosis would do the most damage.
        let forbidden = ["diagnose", "diagnosis", "treat", "treatment", "cure",
                         "heal", "therapy", "rehabilitate", "condition", "disorder"]

        var sentences = narrate(makeOverview(
            completedWorkoutCount: 12,
            totalVolume: 50_000,
            personalRecordCount: 3
        ))
        sentences += ["needs-more-data", "strongest-phase", "lowest-phase", "latest-pr", "consistency"]
            .map { ReportNarrator.narrate(cycleInsight: makeCycleInsight(id: $0, value: "Luteal")) }
        sentences.append(ReportNarrator.narrate(ramp: ReturnToLiftingRampRecord(
            id: "ramp-3",
            locationIds: "knee_left",
            movementPatternRaw: WorkoutMovementPattern.squat.rawValue,
            currentWeek: 2,
            maxLoadPercent: 0.5,
            maxWorkingSets: 3,
            dateCreated: makeDate(day: 1),
            dateUpdated: makeDate(day: 8)
        )))

        for sentence in sentences {
            let lowered = sentence.lowercased()
            for term in forbidden {
                XCTAssertFalse(lowered.contains(term),
                               "Report narration must not imply clinical judgment ('\(term)'): \(sentence)")
            }
        }
    }
}
