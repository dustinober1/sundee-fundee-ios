import Foundation

public enum ReadinessMetricDirection: Sendable, Equatable {
    case higherIsBetter
    case lowerIsBetter
}

public enum ReadinessBaselineNormalizer {
    public static let minimumPersonalObservations = 14

    public static func personalScore(
        _ metric: ReadinessMetricSnapshot,
        direction: ReadinessMetricDirection
    ) -> Int? {
        guard metric.baselineValues.count >= minimumPersonalObservations,
              let baseline = median(metric.baselineValues),
              baseline > 0 else { return nil }

        let delta = (metric.currentValue - baseline) / baseline
        let signedDelta = direction == .higherIsBetter ? delta : -delta
        return clamp(Int((75 + signedDelta * 250).rounded()))
    }

    public static func sleepScore(hours: Double, history: [Double]) -> Int {
        let metric = ReadinessMetricSnapshot(currentValue: hours, baselineValues: history, observedAt: Date())
        if let personal = personalScore(metric, direction: .higherIsBetter) {
            return personal
        }
        switch hours {
        case 9...: return 100
        case 8..<9: return 90
        case 7..<8: return 75
        case 6..<7: return 60
        case 5..<6: return 40
        default: return 20
        }
    }

    public static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? (sorted[middle - 1] + sorted[middle]) / 2
            : sorted[middle]
    }

    public static func mean(_ values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }

    public static func clamp(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}
