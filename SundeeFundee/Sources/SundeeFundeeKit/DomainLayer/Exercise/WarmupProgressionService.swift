import Foundation

// MARK: - WarmupSet

/// Represents an individual set in a barbell warmup progression.
public struct WarmupSet: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let setNumber: Int
    public let weight: Double
    public let targetReps: Int
    public let percentOfWorking: Double
    public let isWorkingSet: Bool
    public let platesPerSide: [PlateCount]
    public let plateSummary: String

    public init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double,
        targetReps: Int,
        percentOfWorking: Double,
        isWorkingSet: Bool,
        platesPerSide: [PlateCount],
        plateSummary: String
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.targetReps = targetReps
        self.percentOfWorking = percentOfWorking
        self.isWorkingSet = isWorkingSet
        self.platesPerSide = platesPerSide
        self.plateSummary = plateSummary
    }
}

// MARK: - WarmupProgression

/// The complete warmup ramp plan for a barbell movement.
public struct WarmupProgression: Sendable, Equatable {
    public let targetWeight: Double
    public let barWeight: Double
    public let unit: WeightUnit
    public let targetReps: Int
    public let sets: [WarmupSet]

    public init(
        targetWeight: Double,
        barWeight: Double,
        unit: WeightUnit,
        targetReps: Int,
        sets: [WarmupSet]
    ) {
        self.targetWeight = targetWeight
        self.barWeight = barWeight
        self.unit = unit
        self.targetReps = targetReps
        self.sets = sets
    }
}

// MARK: - WarmupProgressionService

/// Pure domain service calculating evidence-based warmup progressions for barbell lifts.
public struct WarmupProgressionService: Sendable {

    /// Generates a structured barbell warmup progression up to the target working weight.
    ///
    /// - Parameters:
    ///   - targetWeight: The target working weight to load.
    ///   - barWeight: The weight of the empty barbell (defaults to 45 lbs or 20 kg).
    ///   - unit: Weight unit (`.lbs` or `.kg`).
    ///   - targetReps: The target rep count for the working sets (defaults to 5).
    /// - Returns: A `WarmupProgression` containing warmup sets and the working set with plate configurations.
    public static func generateProgression(
        targetWeight: Double,
        barWeight: Double? = nil,
        unit: WeightUnit = .lbs,
        targetReps: Int = 5
    ) -> WarmupProgression {
        let resolvedBar = barWeight ?? (unit == .kg ? 20.0 : 45.0)
        let availablePlates = unit == .kg
            ? PlateCalculatorService.defaultMetricPlates
            : PlateCalculatorService.defaultImperialPlates
        let minIncrement = (availablePlates.min() ?? (unit == .kg ? 1.25 : 2.5)) * 2.0

        // If target is less than or equal to bar weight, only the bar set is needed
        if targetWeight <= resolvedBar {
            let workingSetPlates = PlateCalculatorService.calculate(
                targetWeight: targetWeight,
                barWeight: resolvedBar,
                availablePlates: availablePlates
            )
            let set = WarmupSet(
                setNumber: 1,
                weight: targetWeight,
                targetReps: max(1, targetReps),
                percentOfWorking: 1.0,
                isWorkingSet: true,
                platesPerSide: workingSetPlates.platesPerSide,
                plateSummary: formatPlateSummary(workingSetPlates.platesPerSide, unit: unit)
            )
            return WarmupProgression(
                targetWeight: targetWeight,
                barWeight: resolvedBar,
                unit: unit,
                targetReps: targetReps,
                sets: [set]
            )
        }

        // Standard percentages: Empty bar, 50%, 70%, 85%
        // Rep counts: Empty bar -> 10 reps, 50% -> 5 reps, 70% -> 3 reps, 85% -> 1-2 reps (1 if target <= 3, else 2)
        let lastWarmupReps = targetReps <= 3 ? 1 : 2
        let stages: [(percent: Double, reps: Int)] = [
            (0.50, 5),
            (0.70, 3),
            (0.85, lastWarmupReps)
        ]

        var rawWeights: [(weight: Double, reps: Int, percent: Double, isWorking: Bool)] = []
        // Step 1: Empty bar
        rawWeights.append((weight: resolvedBar, reps: 10, percent: resolvedBar / targetWeight, isWorking: false))

        // Steps 2-4: Intermediate ramps
        for stage in stages {
            let idealWeight = targetWeight * stage.percent
            let roundedWeight = roundToIncrement(idealWeight, barWeight: resolvedBar, increment: minIncrement)
            // Only add if it's strictly greater than the previous set and strictly less than targetWeight
            if roundedWeight > (rawWeights.last?.weight ?? 0) && roundedWeight < targetWeight {
                rawWeights.append((
                    weight: roundedWeight,
                    reps: stage.reps,
                    percent: roundedWeight / targetWeight,
                    isWorking: false
                ))
            }
        }

        // Final Step: Working set
        let roundedTarget = roundToIncrement(targetWeight, barWeight: resolvedBar, increment: minIncrement)
        let effectiveTarget = max(roundedTarget, resolvedBar)
        if effectiveTarget > (rawWeights.last?.weight ?? 0) {
            rawWeights.append((
                weight: effectiveTarget,
                reps: targetReps,
                percent: 1.0,
                isWorking: true
            ))
        }

        var resultSets: [WarmupSet] = []
        for (index, item) in rawWeights.enumerated() {
            let calculation = PlateCalculatorService.calculate(
                targetWeight: item.weight,
                barWeight: resolvedBar,
                availablePlates: availablePlates
            )
            let set = WarmupSet(
                setNumber: index + 1,
                weight: item.weight,
                targetReps: item.reps,
                percentOfWorking: item.percent,
                isWorkingSet: item.isWorking,
                platesPerSide: calculation.platesPerSide,
                plateSummary: formatPlateSummary(calculation.platesPerSide, unit: unit)
            )
            resultSets.append(set)
        }

        return WarmupProgression(
            targetWeight: targetWeight,
            barWeight: resolvedBar,
            unit: unit,
            targetReps: targetReps,
            sets: resultSets
        )
    }

    /// Rounds a weight to the nearest achievable barbell load given the bar weight and smallest two-plate jump.
    private static func roundToIncrement(_ weight: Double, barWeight: Double, increment: Double) -> Double {
        if weight <= barWeight { return barWeight }
        let extra = weight - barWeight
        let roundedExtra = (extra / increment).rounded() * increment
        return barWeight + roundedExtra
    }

    /// Formats plate configuration into a readable string (e.g. "Bar only", "45, 25 lb / side").
    public static func formatPlateSummary(_ plates: [PlateCount], unit: WeightUnit) -> String {
        if plates.isEmpty {
            return "Bar only"
        }
        let unitSuffix = unit == .kg ? "kg" : "lb"
        let parts = plates.map { plate in
            let weightString = plate.weight.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(plate.weight))"
                : String(format: "%.1f", plate.weight)
            if plate.countPerSide > 1 {
                return "\(plate.countPerSide)×\(weightString)"
            }
            return weightString
        }
        return "\(parts.joined(separator: ", ")) \(unitSuffix) / side"
    }
}
