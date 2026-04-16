import Foundation

// MARK: - RecoveryScoreCalculator

/// Pure domain calculator for recovery scores.
///
/// Takes all available biometric and training inputs, scores each dimension
/// 0-100, and produces a weighted total with graceful degradation when
/// inputs are missing. Returns nil when no inputs are present.
public enum RecoveryScoreCalculator {

    /// Calculate recovery score from available inputs.
    ///
    /// - Parameter inputs: Recovery data (all fields optional).
    /// - Returns: Score with sub-scores and recommendation, or nil if all inputs are nil.
    public static func calculate(inputs: RecoveryScoreInputs) -> RecoveryScore? {
        // Stub — returns nil unconditionally for RED phase
        nil
    }
}
