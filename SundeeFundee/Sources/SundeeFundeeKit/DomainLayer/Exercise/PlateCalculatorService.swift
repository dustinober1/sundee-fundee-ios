import Foundation

// MARK: - PlateCount

/// Represents a plate size and the quantity loaded on EACH side of the barbell.
public struct PlateCount: Sendable, Equatable, Hashable {
    public let weight: Double
    public let countPerSide: Int

    public init(weight: Double, countPerSide: Int) {
        self.weight = weight
        self.countPerSide = countPerSide
    }
}

// MARK: - PlateCalculationResult

/// The outcome of calculating plates for a target barbell load.
public struct PlateCalculationResult: Sendable, Equatable {
    public let targetWeight: Double
    public let barWeight: Double
    public let weightPerSide: Double
    public let platesPerSide: [PlateCount]
    public let totalLoadedWeight: Double
    public let remainder: Double
    public let isExact: Bool

    public init(
        targetWeight: Double,
        barWeight: Double,
        weightPerSide: Double,
        platesPerSide: [PlateCount],
        totalLoadedWeight: Double,
        remainder: Double
    ) {
        self.targetWeight = targetWeight
        self.barWeight = barWeight
        self.weightPerSide = weightPerSide
        self.platesPerSide = platesPerSide
        self.totalLoadedWeight = totalLoadedWeight
        self.remainder = remainder
        self.isExact = abs(remainder) < 0.001
    }
}

// MARK: - PlateCalculatorService

/// Pure domain service calculating barbell plate loading configurations.
public struct PlateCalculatorService: Sendable {

    /// Standard Imperial Olympic plate inventory in pounds (lbs).
    public static let defaultImperialPlates: [Double] = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]

    /// Standard Metric Olympic plate inventory in kilograms (kg).
    public static let defaultMetricPlates: [Double] = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25]

    /// Calculates the required plates per side to reach or approach a target barbell weight.
    ///
    /// - Parameters:
    ///   - targetWeight: The total target weight to load on the barbell.
    ///   - barWeight: The unloaded weight of the bar (e.g. 45 lbs, 35 lbs, 20 kg, etc.).
    ///   - availablePlates: The plate sizes available in the gym.
    /// - Returns: A `PlateCalculationResult` describing the plate stack and any unachievable remainder.
    public static func calculate(
        targetWeight: Double,
        barWeight: Double = 45.0,
        availablePlates: [Double] = defaultImperialPlates
    ) -> PlateCalculationResult {
        guard targetWeight > barWeight else {
            let remainder = (targetWeight - barWeight).rounded(toPlaces: 3)
            return PlateCalculationResult(
                targetWeight: targetWeight,
                barWeight: barWeight,
                weightPerSide: 0,
                platesPerSide: [],
                totalLoadedWeight: barWeight,
                remainder: remainder
            )
        }

        let neededWeight = targetWeight - barWeight
        let neededPerSide = (neededWeight / 2.0).rounded(toPlaces: 3)

        let sortedPlates = availablePlates
            .filter { $0 > 0 }
            .sorted(by: >)

        var remainingPerSide = neededPerSide
        var calculatedPlates: [PlateCount] = []

        for plate in sortedPlates {
            // Epsilon helps prevent floating point truncation (e.g. 24.9999999 / 25)
            let count = Int((remainingPerSide + 0.0001) / plate)
            if count > 0 {
                calculatedPlates.append(PlateCount(weight: plate, countPerSide: count))
                remainingPerSide = (remainingPerSide - Double(count) * plate).rounded(toPlaces: 3)
            }
        }

        let loadedPerSide = calculatedPlates.reduce(0.0) { $0 + Double($1.countPerSide) * $1.weight }
        let totalLoaded = (barWeight + loadedPerSide * 2.0).rounded(toPlaces: 3)
        let remainder = (targetWeight - totalLoaded).rounded(toPlaces: 3)

        return PlateCalculationResult(
            targetWeight: targetWeight,
            barWeight: barWeight,
            weightPerSide: loadedPerSide,
            platesPerSide: calculatedPlates,
            totalLoadedWeight: totalLoaded,
            remainder: remainder
        )
    }
}

// MARK: - Private Helpers

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
