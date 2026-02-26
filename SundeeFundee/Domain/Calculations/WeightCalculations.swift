import Foundation

// MARK: - Weight Calculations

enum SessionResult { case first, success, failure }

enum WeightCalculations {

    static func roundToNearestFive(_ value: Double) -> Double {
        (value / 5.0).rounded() * 5.0
    }

    static func calculateTargetWeight(oneRepMax: Double, percentage: Double) -> Double {
        roundToNearestFive(oneRepMax * percentage)
    }

    static func getNextRecommendedWeight(
        currentWeight: Double,
        result: SessionResult,
        oneRepMax: Double
    ) -> Double {
        switch result {
        case .first:
            return roundToNearestFive(oneRepMax * 0.7)
        case .success:
            return roundToNearestFive(currentWeight + 5)
        case .failure:
            let floor = roundToNearestFive(oneRepMax * 0.5)
            return max(roundToNearestFive(currentWeight - 5), floor)
        }
    }

    static func wasSetSuccessful(
        actualReps: Int,
        prescribedReps: Int,
        actualWeight: Double,
        prescribedWeight: Double?
    ) -> Bool {
        let repsOk   = actualReps >= prescribedReps
        let weightOk = prescribedWeight == nil || actualWeight >= prescribedWeight!
        return repsOk && weightOk
    }

    static func isPersonalRecord(weight: Double, previousMax: Double) -> Bool {
        weight > previousMax
    }

    static func calculateVolumeLoad(weight: Double, reps: Int, sets: Int) -> Double {
        weight * Double(reps) * Double(sets)
    }

    static func detectPlateau(weights: [Double]) -> Bool {
        guard weights.count >= 3 else { return false }
        let last3 = Array(weights.suffix(3))
        return (last3.max()! - last3.min()!) < 5
    }
}

// MARK: - Epley 1RM Formula

enum EpleyFormula {
    /// Estimates 1RM from a submaximal lift.
    /// Formula: weight × (1 + reps / 30)
    /// Only valid for reps > 1 (for reps == 1, the lift itself is the 1RM).
    static func estimated1RM(weight: Double, reps: Int) -> Double {
        guard reps > 1 else { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    /// Returns true if the new estimated 1RM is a PR vs the stored max.
    static func isPR(newEstimate: Double, currentMax: Double?) -> Bool {
        guard let current = currentMax else { return true }
        return newEstimate > current
    }
}
