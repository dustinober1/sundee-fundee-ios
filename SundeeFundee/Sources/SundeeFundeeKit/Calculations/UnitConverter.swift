import Foundation

/// Conversion factor: 1 pound = 0.453592 kilograms
private let lbsToKgFactor = 0.453592

/// Converts pounds to kilograms
/// - Parameter lbs: Weight in pounds
/// - Returns: Weight in kilograms
public func lbsToKg(_ lbs: Double) -> Double {
    return lbs * lbsToKgFactor
}

/// Converts kilograms to pounds
/// - Parameter kg: Weight in kilograms
/// - Returns: Weight in pounds
public func kgToLbs(_ kg: Double) -> Double {
    return kg / lbsToKgFactor
}
