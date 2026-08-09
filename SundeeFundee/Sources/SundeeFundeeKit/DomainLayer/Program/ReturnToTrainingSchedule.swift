import Foundation

// MARK: - ReturnToTrainingWeek

/// One week of a return-to-training block.
public struct ReturnToTrainingWeek: Sendable, Equatable {
    public let week: Int

    /// Fraction of the person's usual working load for this week.
    public let loadPercent: Double

    /// Cap on working sets for the main lifts this week.
    public let workingSets: Int

    /// Short phase name, e.g. "Easing In".
    public let phaseName: String

    /// Plain-language explanation of what this week is for.
    public let focus: String

    public init(
        week: Int,
        loadPercent: Double,
        workingSets: Int,
        phaseName: String,
        focus: String
    ) {
        self.week = week
        self.loadPercent = loadPercent
        self.workingSets = workingSets
        self.phaseName = phaseName
        self.focus = focus
    }
}

// MARK: - ReturnToTrainingSchedule

/// Builds the week-by-week load plan for a return-to-training program.
///
/// The percentages are not authored here. They come from repeatedly applying
/// `ReturnToLiftingRampService.advanceRamp`, the same progression the injury
/// path uses — so the program inherits the ramp's pacing and bounds for free,
/// and a change to the ramp rules moves the program with it rather than
/// leaving a second hand-maintained table to drift out of sync.
public enum ReturnToTrainingSchedule {
    /// Upper bound on program length.
    ///
    /// At the ramp's ~7% per week, the most cautious start reaches full load
    /// inside nine weeks. The cap is a guard against a future ramp change
    /// producing an unreasonably long block, not a training decision.
    public static let maximumWeeks = 10

    /// The week-by-week plan for returning after `breakReason`.
    ///
    /// Runs until the ramp reaches full load, so a more cautious starting
    /// point produces a longer block rather than a steeper climb.
    public static func weeks(for breakReason: TrainingBreakReason) -> [ReturnToTrainingWeek] {
        // A transient record used only to drive advanceRamp. Empty location
        // and pattern are deliberate: a return-to-training block is whole-body,
        // not scoped to an injured region, and this is never persisted.
        var record = ReturnToLiftingRampRecord(
            id: "return-to-training-\(breakReason.rawValue)",
            locationIds: "",
            movementPatternRaw: "",
            currentWeek: 1,
            maxLoadPercent: breakReason.startingLoadPercent,
            maxWorkingSets: breakReason.startingWorkingSets,
            dateCreated: Date(),
            dateUpdated: Date()
        )

        var result: [ReturnToTrainingWeek] = [make(from: record, breakReason: breakReason)]

        while result.count < maximumWeeks, record.maxLoadPercent < 1.0 {
            record = ReturnToLiftingRampService.advanceRamp(record)
            result.append(make(from: record, breakReason: breakReason))
        }

        return result
    }

    // MARK: - Private Helpers

    private static func make(
        from record: ReturnToLiftingRampRecord,
        breakReason: TrainingBreakReason
    ) -> ReturnToTrainingWeek {
        ReturnToTrainingWeek(
            week: record.currentWeek,
            loadPercent: record.maxLoadPercent,
            workingSets: record.maxWorkingSets,
            phaseName: phaseName(for: record.maxLoadPercent),
            focus: focus(
                week: record.currentWeek,
                loadPercent: record.maxLoadPercent,
                workingSets: record.maxWorkingSets,
                breakReason: breakReason
            )
        )
    }

    private static func phaseName(for loadPercent: Double) -> String {
        switch loadPercent {
        case ..<0.55: return "Easing In"
        case ..<0.75: return "Building"
        case ..<1.0: return "Approaching Normal"
        default: return "Back to Full Load"
        }
    }

    private static func focus(
        week: Int,
        loadPercent: Double,
        workingSets: Int,
        breakReason: TrainingBreakReason
    ) -> String {
        let percent = Int((loadPercent * 100).rounded())
        let setWord = workingSets == 1 ? "set" : "sets"

        if week == 1 {
            return "\(breakReason.programOpening) Starting at \(percent)% of your usual working "
                + "weight, with up to \(workingSets) working \(setWord)."
        }

        if loadPercent >= 1.0 {
            return "Back to your usual working weights, with up to \(workingSets) working "
                + "\(setWord). Keep going from here or start a new block."
        }

        return "Week \(week) at \(percent)% of your usual working weight, with up to "
            + "\(workingSets) working \(setWord). Adding a little each week."
    }
}
