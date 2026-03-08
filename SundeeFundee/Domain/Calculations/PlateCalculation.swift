import Foundation

enum PlateCalculation {

    // MARK: - Bar weights

    /// Men's barbell: 45 lb / ~20.4 kg
    static let standardBarKg: Double = 45.0 / WeightUnitConversion.poundsPerKilogram
    /// Women's barbell: 35 lb / ~15.9 kg
    static let womenBarKg: Double = 35.0 / WeightUnitConversion.poundsPerKilogram

    static let standardBarLb: Double = 45.0
    static let womenBarLb: Double = 35.0

    // MARK: - Available plates

    /// Standard lb plate denominations used in most gyms
    static let availablePlatesLb: [Double] = [45, 25, 15, 10, 5, 2.5]

    /// Kg equivalents of the lb plates (for kg-unit calculations)
    static let availablePlatesKg: [Double] = availablePlatesLb.map { $0 / WeightUnitConversion.poundsPerKilogram }

    // MARK: - Plate calculation

    /// Returns the plates needed per side.
    /// All values are in the same unit system (determined by `weightUnit`).
    /// - Parameters:
    ///   - totalWeightKg: The total barbell weight in kilograms.
    ///   - barbellWeightKg: The bar weight in kilograms.
    ///   - weightUnit: The unit system to use for plate selection. Defaults to pounds.
    /// - Returns: Plate weight (in the chosen unit) and count per side.
    static func platesPerSide(
        totalWeightKg: Double,
        barbellWeightKg: Double = standardBarKg,
        weightUnit: WeightUnit = .pounds
    ) -> [(weight: Double, count: Int)] {
        let poundsPerKg = WeightUnitConversion.poundsPerKilogram

        switch weightUnit {
        case .pounds:
            let totalLb = totalWeightKg * poundsPerKg
            let barLb = barbellWeightKg * poundsPerKg
            guard totalLb > barLb else { return [] }
            var remaining = (totalLb - barLb) / 2.0
            var breakdown: [(weight: Double, count: Int)] = []
            for plate in availablePlatesLb {
                guard remaining >= plate - 0.01 else { continue }
                let count = Int((remaining / plate).rounded(.down))
                if count > 0 {
                    breakdown.append((weight: plate, count: count))
                    remaining -= Double(count) * plate
                }
            }
            return breakdown

        case .kilograms:
            guard totalWeightKg > barbellWeightKg else { return [] }
            var remaining = (totalWeightKg - barbellWeightKg) / 2.0
            var breakdown: [(weight: Double, count: Int)] = []
            for plate in availablePlatesKg {
                guard remaining >= plate - 0.01 else { continue }
                let count = Int((remaining / plate).rounded(.down))
                if count > 0 {
                    breakdown.append((weight: plate, count: count))
                    remaining -= Double(count) * plate
                }
            }
            return breakdown
        }
    }

    // MARK: - Legacy kg-only overload (for tests and internal use)

    /// Returns plates in kg for a kg-unit context.
    static func platesPerSideKg(
        totalWeightKg: Double,
        barbellWeightKg: Double = standardBarKg
    ) -> [(weight: Double, count: Int)] {
        platesPerSide(totalWeightKg: totalWeightKg, barbellWeightKg: barbellWeightKg, weightUnit: .kilograms)
    }

    // MARK: - Description (kg legacy)

    /// Human-readable description in kg (legacy / internal use).
    static func description(totalWeightKg: Double, barbellWeightKg: Double = standardBarKg) -> String {
        let plates = platesPerSideKg(totalWeightKg: totalWeightKg, barbellWeightKg: barbellWeightKg)
        let barLb = barbellWeightKg * WeightUnitConversion.poundsPerKilogram
        if plates.isEmpty {
            return "Bar only (\(barLb.rounded())lb)"
        }
        let parts = plates.map { p -> String in
            let lb = p.weight * WeightUnitConversion.poundsPerKilogram
            return "\(p.count)×\(lb.rounded())lb"
        }
        return parts.joined(separator: " + ") + " per side"
    }
}
