import Foundation

enum SessionResult {
    case first
    case success
    case failure
}

enum WeightCalculations {
    /// Round to nearest 5 lbs.
    static func roundToNearestFive(_ value: Double) -> Double {
        (value / 5.0).rounded() * 5.0
    }

    /// Calculate target weight based on 1RM and percentage.
    static func calculateTargetWeight(oneRepMax: Double, percentage: Double) -> Double {
        roundToNearestFive(oneRepMax * percentage)
    }

    /// Get next recommended working weight based on session result.
    /// - first: 70% of 1RM
    /// - success: +5 lbs
    /// - failure: -5 lbs (floor at 50% of 1RM)
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

    /// A set is successful if actualReps >= prescribedReps
    /// AND actualWeight >= prescribedWeight (if prescribed).
    static func wasSetSuccessful(
        actualReps: Int,
        prescribedReps: Int,
        actualWeight: Double,
        prescribedWeight: Double?
    ) -> Bool {
        let repsOk = actualReps >= prescribedReps
        let weightOk = prescribedWeight.map { actualWeight >= $0 } ?? true
        return repsOk && weightOk
    }

    /// Session is successful if ALL sets pass.
    static func wasSessionSuccessful(
        sets: [(actualReps: Int, prescribedReps: Int, actualWeight: Double, prescribedWeight: Double?)]
    ) -> Bool {
        sets.allSatisfy { wasSetSuccessful(actualReps: $0.actualReps, prescribedReps: $0.prescribedReps, actualWeight: $0.actualWeight, prescribedWeight: $0.prescribedWeight) }
    }

    /// Check if a weight represents a new personal record.
    static func isPersonalRecord(weight: Double, previousMax: Double) -> Bool {
        weight > previousMax
    }

    /// Calculate volume load (weight × reps × sets).
    static func calculateVolumeLoad(weight: Double, reps: Int, sets: Int) -> Double {
        weight * Double(reps) * Double(sets)
    }

    /// Plateau detected if last 3 weights vary by less than 5 lbs.
    static func detectPlateau(weights: [Double]) -> Bool {
        guard weights.count >= 3 else { return false }
        let lastThree = Array(weights.suffix(3))
        let maxWeight = lastThree.max() ?? 0
        let minWeight = lastThree.min() ?? 0
        return maxWeight - minWeight < 5
    }
}
