import Foundation

/// Standard plate sizes in lbs
public let standardPlates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5]

/// Represents a plate weight and how many are needed per side
public struct Plate: Equatable {
    public let weight: Double
    public let count: Int

    public init(weight: Double, count: Int) {
        self.weight = weight
        self.count = count
    }
}

/// Calculates which plates to load on ONE SIDE of a barbell
/// - Parameters:
///   - targetWeight: The total target weight in lbs
///   - barWeight: The weight of the barbell in lbs (default: 45)
/// - Returns: Array of plates needed per side, sorted largest to smallest
public func calculatePlates(targetWeight: Double, barWeight: Double = 45) -> [Plate] {
    // If target is less than bar, no plates needed
    if targetWeight <= barWeight {
        return []
    }

    let weightPerSide = (targetWeight - barWeight) / 2
    var remaining = weightPerSide
    var plates: [Plate] = []

    for plateSize in standardPlates {
        let count = Int(remaining / plateSize)
        if count > 0 {
            plates.append(Plate(weight: plateSize, count: count))
            remaining -= Double(count) * plateSize
        }

        if remaining < 2.4 { // Less than smallest plate/2
            break
        }
    }

    return plates
}
