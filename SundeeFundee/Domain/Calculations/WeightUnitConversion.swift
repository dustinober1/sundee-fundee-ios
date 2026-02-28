import Foundation

enum WeightUnitConversion {
    private static let poundsPerKilogram = 2.2046226218

    static func value(fromKilograms kilograms: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kilograms:
            kilograms
        case .pounds:
            kilograms * poundsPerKilogram
        }
    }

    static func kilograms(from value: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kilograms:
            value
        case .pounds:
            value / poundsPerKilogram
        }
    }

    static func parseInputToKilograms(_ input: String, unit: WeightUnit) -> Double? {
        guard let value = Double(input) else { return nil }
        return kilograms(from: value, unit: unit)
    }

    static func format(
        kilograms: Double,
        unit: WeightUnit,
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int = 1
    ) -> String {
        formatValue(
            value(fromKilograms: kilograms, unit: unit),
            minimumFractionDigits: minimumFractionDigits,
            maximumFractionDigits: maximumFractionDigits
        )
    }

    static func formatWithUnit(
        kilograms: Double,
        unit: WeightUnit,
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int = 1
    ) -> String {
        "\(format(kilograms: kilograms, unit: unit, minimumFractionDigits: minimumFractionDigits, maximumFractionDigits: maximumFractionDigits)) \(unit.symbol)"
    }

    static func formatValue(
        _ value: Double,
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int = 1
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
