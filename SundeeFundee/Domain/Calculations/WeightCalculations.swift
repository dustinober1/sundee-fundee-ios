import Foundation

// MARK: - Weight Calculations

enum SessionResult { case first, success, failure }

enum WeightCalculations {

    static func roundToNearestFive(_ value: Double) -> Double {
        (value / 5.0).rounded() * 5.0
    }

    // MARK: - Equipment-specific weight snapping

    /// Available dumbbell weights in pounds (the actual inventory).
    static let availableDumbbellWeightsLb: [Double] = [10, 15, 20, 25, 35, 40, 50, 70]

    /// Available kettlebell weights in pounds (24 kg, 36 kg, 52 kg, 70 kg converted).
    static let availableKettlebellWeightsLb: [Double] = [
        24 * 2.2046226218,  // ~52.9 lb
        36 * 2.2046226218,  // ~79.4 lb
        52 * 2.2046226218,  // ~114.6 lb
        70 * 2.2046226218   // ~154.3 lb
    ]

    /// Available kettlebell weights in kg.
    static let availableKettlebellWeightsKg: [Double] = [24, 36, 52, 70]

    /// Snaps a barbell total to the nearest weight that can actually be loaded
    /// using standard plates (45, 25, 15, 10, 5, 2.5 lb), accounting for bar weight.
    /// Plates go on in 2.5 lb increments per side, so valid totals are bar + multiples of 5 lb.
    /// - Parameters:
    ///   - kg: The target weight in kilograms.
    ///   - barLb: Bar weight in pounds (45 for men's, 35 for women's).
    /// - Returns: The nearest loadable total in kilograms.
    static func snapBarbellWeightKg(_ kg: Double, barLb: Double = 45.0) -> Double {
        let lb = kg * 2.2046226218
        // Each side gets plates in 2.5 lb increments, so total plate weight moves in 5 lb steps.
        // Snap to nearest 5 lb total above the bar weight.
        let plateLoadLb = max(0, lb - barLb)
        let snappedPlateLoad = (plateLoadLb / 5.0).rounded() * 5.0
        let snappedTotalLb = barLb + snappedPlateLoad
        return snappedTotalLb / 2.2046226218
    }

    /// Snaps a weight in kg to the nearest available dumbbell weight.
    static func snapDumbbellWeightKg(_ kg: Double) -> Double {
        let lb = kg * 2.2046226218
        let nearest = availableDumbbellWeightsLb.min(by: { abs($0 - lb) < abs($1 - lb) }) ?? lb
        return nearest / 2.2046226218
    }

    /// Snaps a weight in kg to the nearest available kettlebell weight.
    static func snapKettlebellWeightKg(_ kg: Double) -> Double {
        availableKettlebellWeightsKg.min(by: { abs($0 - kg) < abs($1 - kg) }) ?? kg
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
        let repsOk = actualReps >= prescribedReps
        let weightOk: Bool
        if let prescribedWeight {
            weightOk = actualWeight >= prescribedWeight
        } else {
            weightOk = true
        }
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
