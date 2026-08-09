import Foundation

// MARK: - ReportNarrator

/// Turns the structured output of the insight services into short, plain
/// sentences for the shareable training report.
///
/// The insight services were built to drive in-app charts, where a label and
/// a value sit next to a graph that supplies the context. A report has no
/// chart and may be read by someone who has never opened the app — a physical
/// therapist, a doctor, a trainer — so each figure has to carry its own
/// context in a sentence.
///
/// Narration is rule-based and deterministic: every sentence is derived from
/// a known insight identifier or a computed figure, never from parsing the
/// prose an insight already carries. Unknown identifiers fall back to a
/// readable generic form rather than being dropped, so a new insight added
/// upstream degrades gracefully instead of silently vanishing from a report
/// someone is relying on.
///
/// Language rules, consistent with the rest of the app: describe what was
/// observed, never interpret it clinically. No diagnosis, no treatment
/// advice, no claims about causes.
public enum ReportNarrator {
    // MARK: - Session Overview

    /// Narrates the session-overview figures as standalone sentences.
    ///
    /// - Parameters:
    ///   - overview: The computed overview figures.
    ///   - calendar: Calendar used for date arithmetic and formatting.
    ///     Injectable so the sentences are deterministic under test.
    public static func narrateOverview(
        _ overview: TrainingReportContent.Overview,
        calendar: Calendar = .current
    ) -> [String] {
        var sentences: [String] = []

        let window = "\(formatDate(overview.rangeStart, calendar: calendar)) "
            + "and \(formatDate(lastCoveredDay(of: overview.rangeEnd, notBefore: overview.rangeStart, calendar: calendar), calendar: calendar))"

        if overview.completedWorkoutCount == 0 {
            sentences.append("No training sessions were logged between \(window).")
        } else {
            let sessionWord = overview.completedWorkoutCount == 1 ? "session was" : "sessions were"
            var sentence = "\(overview.completedWorkoutCount) training \(sessionWord) "
                + "logged between \(window)"
            if let perWeek = sessionsPerWeek(overview, calendar: calendar) {
                sentence += " — an average of \(perWeek) per week."
            } else {
                sentence += "."
            }
            sentences.append(sentence)
        }

        if overview.totalVolume > 0 {
            sentences.append(
                "Total training volume over this period was "
                    + "\(formatNumber(overview.totalVolume)) (weight lifted × repetitions)."
            )
        }

        if overview.personalRecordCount > 0 {
            let recordWord = overview.personalRecordCount == 1 ? "record was" : "records were"
            sentences.append(
                "\(overview.personalRecordCount) new maximum-lift \(recordWord) logged."
            )
        }

        return sentences
    }

    /// Describes how training volume moved across the reporting window.
    ///
    /// Compares the first half of the window against the second. Returns nil
    /// when there are too few sessions for a split to mean anything — a
    /// two-session "trend" would be noise dressed up as a finding, which is
    /// exactly what this report should not hand to a clinician.
    public static func narrateVolumeTrend(
        completedWorkouts: [Workout],
        rangeStart: Date,
        rangeEnd: Date
    ) -> String? {
        guard completedWorkouts.count >= 4 else { return nil }

        let midpoint = Date(
            timeIntervalSince1970: (rangeStart.timeIntervalSince1970 + rangeEnd.timeIntervalSince1970) / 2
        )

        var firstHalf = 0.0
        var secondHalf = 0.0
        for workout in completedWorkouts {
            guard let completedAt = workout.completedAt else { continue }
            if completedAt < midpoint {
                firstHalf += workout.totalVolume
            } else {
                secondHalf += workout.totalVolume
            }
        }

        guard firstHalf > 0 else { return nil }

        let changePercent = ((secondHalf - firstHalf) / firstHalf) * 100
        let magnitude = Int(abs(changePercent).rounded())

        if magnitude < 10 {
            return "Training volume stayed roughly steady across this period."
        }

        let direction = changePercent > 0 ? "higher" : "lower"
        return "Training volume in the second half of this period was about "
            + "\(magnitude)% \(direction) than in the first half."
    }

    // MARK: - Cycle-Aware Insights

    /// Narrates one cycle-aware insight as a plain sentence.
    ///
    /// Keyed on the insight's stable identifier rather than its display text,
    /// so wording changes upstream do not silently change the report. The
    /// insight's own subtitle is appended where it carries evidence the lead
    /// sentence does not (a workout count, a logged weight).
    public static func narrate(cycleInsight insight: CycleAwareProgressInsight) -> String {
        let phase = insight.value.lowercased()
        let subtitle = normalize(insight.subtitle)

        switch insight.id {
        case "needs-more-data":
            return "There is not yet enough phase-linked training data to describe cycle patterns reliably. "
                + "At least two logged workouts per cycle phase are needed before any trend is meaningful."

        case "strongest-phase":
            return join("Training volume was highest during the \(phase) phase.", subtitle)

        case "lowest-phase":
            return join(
                "Training volume was lowest during the \(phase) phase, "
                    + "which may be a useful window to plan lighter sessions in advance.",
                subtitle
            )

        case "latest-pr":
            return join("The most recent maximum-lift record logged was for \(insight.value).", subtitle)

        case "consistency":
            return join("Logged training so far: \(phase).", subtitle)

        default:
            // Unknown insight from a newer version of the insight service.
            // Keep it readable rather than dropping data from the report.
            return join("\(insight.title): \(insight.value).", subtitle)
        }
    }

    // MARK: - Symptom Insights

    /// Prepares a symptom insight for the report.
    ///
    /// These messages are already written as plain, non-diagnostic sentences,
    /// so narration here is deliberately minimal — rewriting them would risk
    /// changing carefully-worded copy. Whitespace is normalized because the
    /// upstream service composes messages by concatenation and appends an
    /// empty phase-context string when the cycle phase is unknown, which
    /// leaves a trailing space.
    public static func narrate(symptomInsight insight: SymptomTrainingInsight) -> String {
        normalize(insight.message)
    }

    // MARK: - Return-to-Lifting Ramps

    /// Narrates a return-to-lifting ramp as a sentence a clinician can read
    /// without knowing the app's vocabulary.
    public static func narrate(ramp: ReturnToLiftingRampRecord) -> String {
        let percent = Int((ramp.maxLoadPercent * 100).rounded())
        let setWord = ramp.maxWorkingSets == 1 ? "set" : "sets"
        return "Week \(ramp.currentWeek) of a gradual return to training: working loads are capped "
            + "at \(percent)% of usual working weight, with up to \(ramp.maxWorkingSets) working "
            + "\(setWord) per exercise."
    }

    // MARK: - Shared Date Formatting

    /// Formats a single date in the report's date style.
    public static func formatDate(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    /// A label for the report's window, e.g. "June 1, 2026 – June 29, 2026".
    public static func dateRangeLabel(
        rangeStart: Date,
        rangeEnd: Date,
        calendar: Calendar = .current
    ) -> String {
        let end = lastCoveredDay(of: rangeEnd, notBefore: rangeStart, calendar: calendar)
        return "\(formatDate(rangeStart, calendar: calendar)) – \(formatDate(end, calendar: calendar))"
    }

    /// The last day the report actually covers.
    ///
    /// Report ranges are half-open (end exclusive), so the final covered day
    /// is the day before `rangeEnd`. Printing `rangeEnd` itself would claim a
    /// day of data the report does not include. Single source of truth for
    /// this rule — every date shown to a reader goes through here.
    private static func lastCoveredDay(
        of rangeEnd: Date,
        notBefore rangeStart: Date,
        calendar: Calendar
    ) -> Date {
        let previousDay = calendar.date(byAdding: .day, value: -1, to: rangeEnd) ?? rangeEnd
        return max(previousDay, rangeStart)
    }

    // MARK: - Private Helpers

    /// Average sessions per week, or nil when the window is too short for the
    /// average to say anything useful.
    private static func sessionsPerWeek(
        _ overview: TrainingReportContent.Overview,
        calendar: Calendar
    ) -> String? {
        let days = calendar.dateComponents(
            [.day],
            from: overview.rangeStart,
            to: overview.rangeEnd
        ).day ?? 0
        guard days >= 7 else { return nil }

        let weeks = Double(days) / 7.0
        let perWeek = Double(overview.completedWorkoutCount) / weeks
        return String(format: "%.1f", perWeek)
    }

    /// Joins a lead sentence with supporting detail, dropping the detail when
    /// it is empty.
    private static func join(_ lead: String, _ detail: String) -> String {
        detail.isEmpty ? lead : "\(lead) \(detail)"
    }

    /// Collapses runs of whitespace and trims the edges.
    private static func normalize(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        // en_US_POSIX does not turn grouping on by default, and training
        // volumes run to five and six figures where it matters for legibility.
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}
