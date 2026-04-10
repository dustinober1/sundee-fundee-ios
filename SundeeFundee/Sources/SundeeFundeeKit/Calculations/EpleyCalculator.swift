import Foundation

/// Estimates one-rep max using the Epley formula: weight × (1 + reps / 30).
///
/// Only valid when reps > 1 and weight > 0.
/// Returns nil for bodyweight exercises (weight == 0) or single-rep sets (reps <= 1).
public func estimatedOneRepMax(weight: Double, reps: Int) -> Double? {
    guard reps > 1, weight > 0 else { return nil }
    return weight * (1.0 + Double(reps) / 30.0)
}
