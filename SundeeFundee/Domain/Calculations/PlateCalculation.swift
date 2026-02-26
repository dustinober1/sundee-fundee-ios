import Foundation

enum PlateCalculation {

    static let standardBarKg: Double = 20.0
    static let womenBarKg:    Double = 15.0
    static let availablePlatesKg: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    /// Returns the plates needed per side of the barbell.
    /// Keys are plate weights (kg), values are count per side.
    static func platesPerSide(
        totalWeightKg: Double,
        barbellWeightKg: Double = standardBarKg
    ) -> [(weight: Double, count: Int)] {
        guard totalWeightKg > barbellWeightKg else { return [] }

        var remaining = (totalWeightKg - barbellWeightKg) / 2.0
        var breakdown: [(weight: Double, count: Int)] = []

        for plate in availablePlatesKg {
            guard remaining >= plate else { continue }
            let count = Int(remaining / plate)
            if count > 0 {
                breakdown.append((weight: plate, count: count))
                remaining -= Double(count) * plate
            }
        }
        return breakdown
    }

    /// Human-readable description, e.g. "2×25kg + 1×5kg per side"
    static func description(totalWeightKg: Double, barbellWeightKg: Double = standardBarKg) -> String {
        let plates = platesPerSide(totalWeightKg: totalWeightKg, barbellWeightKg: barbellWeightKg)
        if plates.isEmpty {
            return "Bar only (\(Int(barbellWeightKg))kg)"
        }
        let parts = plates.map { p -> String in
            let w = p.weight.truncatingRemainder(dividingBy: 1) == 0
                  ? "\(Int(p.weight))kg"
                  : "\(p.weight)kg"
            return "\(p.count)×\(w)"
        }
        return parts.joined(separator: " + ") + " per side"
    }
}
