import Foundation

// MARK: - RecoveryScore

/// The result of recovery score calculation.
///
/// Contains the total score (0-100), per-input sub-scores, a training
/// recommendation, and human-readable explanations for each sub-score.
public struct RecoveryScore: Sendable, Equatable {

    // MARK: - Properties

    /// Total recovery score, clamped to 0-100.
    public let total: Int

    /// Training recommendation derived from total score.
    public let recommendation: TrainingRecommendation

    /// Per-input sub-scores (0-100 each).
    public let subScores: [RecoveryInput: Int]

    /// Number of inputs that were present (non-nil).
    public let presentInputCount: Int

    /// Total number of possible inputs (always 5).
    public let totalInputCount: Int

    /// Per-input human-readable explanations.
    public let explanations: [RecoveryInput: String]

    // MARK: - Initialization

    public init(
        total: Int,
        recommendation: TrainingRecommendation,
        subScores: [RecoveryInput: Int],
        presentInputCount: Int,
        totalInputCount: Int,
        explanations: [RecoveryInput: String]
    ) {
        self.total = total
        self.recommendation = recommendation
        self.subScores = subScores
        self.presentInputCount = presentInputCount
        self.totalInputCount = totalInputCount
        self.explanations = explanations
    }
}

// MARK: - TrainingRecommendation

/// Training recommendation derived from recovery score total.
public enum TrainingRecommendation: String, Sendable, Equatable {
    /// Total >= 70 — good to train.
    case pushDay
    /// Total 40-69 — moderate readiness.
    case moderate
    /// Total < 40 — prioritize rest.
    case restDay
}

// MARK: - RecoveryInput

/// Identifies each recovery input dimension.
public enum RecoveryInput: String, Sendable, Equatable, CaseIterable {
    case hrv
    case sleep
    case trainingLoad
    case cyclePhase
    case pain
}
