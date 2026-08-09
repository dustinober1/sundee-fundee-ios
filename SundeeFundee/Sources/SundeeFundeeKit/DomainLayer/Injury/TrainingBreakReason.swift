import Foundation

// MARK: - TrainingBreakReason

/// Why someone is coming back to training after time away.
///
/// The ramp machinery in `ReturnToLiftingRampService` was built for injury
/// returns, where the affected body region determines which movement patterns
/// get capped. A general break has no affected region — it affects everything —
/// so this type supplies the starting point instead.
///
/// Deliberately a small, broad set rather than a single postpartum mode. The
/// app should serve people returning for any reason without making specific
/// physiological claims about any of them; the differences below are caution
/// levels, not clinical timelines.
///
/// Not persisted on `ReturnToLiftingRampRecord`. That record is an existing
/// CloudKit shape, and adding a field to it would mutate a deployed record
/// type. The reason is supplied per call by whoever asks for recommendations.
public enum TrainingBreakReason: String, Codable, Sendable, CaseIterable, Identifiable {
    case postpartum
    case illness
    case extendedTimeOff
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .postpartum: return "After having a baby"
        case .illness: return "After being unwell"
        case .extendedTimeOff: return "After time away"
        case .other: return "Something else"
        }
    }

    /// Short label for pickers and program subtitles.
    public var shortLabel: String {
        switch self {
        case .postpartum: return "Postpartum"
        case .illness: return "Illness"
        case .extendedTimeOff: return "Time off"
        case .other: return "Other"
        }
    }

    /// Fraction of usual working load to start at.
    ///
    /// These sit inside the same 0.30–0.60 band the injury paths already use,
    /// so a break-driven ramp can never start heavier than the most permissive
    /// injury ramp. Postpartum starts lowest purely as caution, not as a claim
    /// about recovery.
    public var startingLoadPercent: Double {
        switch self {
        case .postpartum: return 0.40
        case .illness: return 0.50
        case .extendedTimeOff: return 0.60
        case .other: return 0.55
        }
    }

    /// Working sets to start with.
    public var startingWorkingSets: Int {
        switch self {
        case .postpartum: return 2
        case .illness: return 3
        case .extendedTimeOff: return 3
        case .other: return 3
        }
    }

    /// Non-clinical explanation of why the first weeks are lighter.
    ///
    /// Describes the plan, never the body. No claims about what is happening
    /// physiologically, no timelines, no advice that could read as medical.
    public func rampReason(for pattern: WorkoutMovementPattern) -> String {
        switch self {
        case .postpartum:
            return "Easing back into \(pattern.displayName) movements after time away. "
                + "Starting light and building gradually, paced by how you're feeling."
        case .illness:
            return "Coming back to \(pattern.displayName) movements after being unwell. "
                + "Starting light and adding load as your energy returns."
        case .extendedTimeOff:
            return "Returning to \(pattern.displayName) movements after a break. "
                + "Starting conservatively and building back week by week."
        case .other:
            return "Easing back into \(pattern.displayName) movements. "
                + "Starting light and building gradually."
        }
    }
}
