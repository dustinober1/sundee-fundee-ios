import Foundation

/// Maps rep count to the percentage of 1RM to use
/// - Parameter reps: Number of reps prescribed
/// - Returns: Percentage of 1RM (0.0 to 1.0)
public func defaultPercentage(reps: Int) -> Double {
    let percentageMap: [Int: Double] = [
        1: 1.0,
        2: 0.93,
        3: 0.85,
        4: 0.83,
        5: 0.80,
        6: 0.75,
        7: 0.73,
        8: 0.70,
        9: 0.67,
        10: 0.65,
        11: 0.63,
        12: 0.60
    ]

    if reps <= 1 { return 1.0 }
    if reps >= 12 { return 0.60 }
    return percentageMap[reps] ?? 0.65
}

/// Calculates the prescribed weight for an exercise
/// - Parameters:
///   - max: User's 1RM for this exercise (lbs)
///   - reps: Number of reps prescribed
///   - energyMultiplier: Energy level adjustment (0.85 = low, 1.0 = medium, 1.05 = high)
///   - cycleMultiplier: Cycle phase adjustment (varies by phase)
/// - Returns: Prescribed weight in lbs
public func calculatePrescribedWeight(
    max: Double,
    reps: Int,
    energyMultiplier: Double = 1.0,
    cycleMultiplier: Double = 1.0
) -> Double {
    let percentage = defaultPercentage(reps: reps)
    let baseWeight = max * percentage
    let adjustedWeight = baseWeight * energyMultiplier * cycleMultiplier
    return roundToNearest(adjustedWeight, increment: 5)
}

/// Rounds a value to the nearest increment
/// - Parameters:
///   - value: The value to round
///   - increment: The increment to round to (e.g., 5 for 5-lb plates)
/// - Returns: Rounded value
public func roundToNearest(_ value: Double, increment: Double) -> Double {
    return round(value / increment) * increment
}
