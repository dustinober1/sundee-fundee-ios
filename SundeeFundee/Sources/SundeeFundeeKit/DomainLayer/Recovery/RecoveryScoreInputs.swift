import Foundation

// MARK: - RecoveryScoreInputs

/// Input data for recovery score calculation.
///
/// All fields are Optional — the calculator gracefully degrades when
/// inputs are missing by redistributing weights among present inputs.
/// When all inputs are nil, the calculator returns nil (no score).
public struct RecoveryScoreInputs: Sendable, Equatable {

    // MARK: - Properties

    /// Most recent nightly SDNN from HealthKit (milliseconds).
    public let hrvMilliseconds: Double?

    /// Deduplicated total sleep duration (hours).
    public let sleepDurationHours: Double?

    /// Last 4 weeks of training summaries from WeeklyLoadAnalyzer.
    public let weeklySummaries: [WeeklyLoadAnalyzer.WeeklySummary]?

    /// Current cycle phase from CyclePhaseCache.
    public let cyclePhase: CyclePhase?

    /// Pain intensity 1-10 scale from DailyPainLog (per InjuryModels.swift).
    public let painIntensity: Int?

    // MARK: - Initialization

    public init(
        hrvMilliseconds: Double? = nil,
        sleepDurationHours: Double? = nil,
        weeklySummaries: [WeeklyLoadAnalyzer.WeeklySummary]? = nil,
        cyclePhase: CyclePhase? = nil,
        painIntensity: Int? = nil
    ) {
        self.hrvMilliseconds = hrvMilliseconds
        self.sleepDurationHours = sleepDurationHours
        self.weeklySummaries = weeklySummaries
        self.cyclePhase = cyclePhase
        self.painIntensity = painIntensity
    }
}
