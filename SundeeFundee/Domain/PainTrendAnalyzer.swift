import Foundation

/// Pure Swift pain trend analysis. No framework dependencies.
enum PainTrendAnalyzer {

    struct TrendResult {
        let trailingAverage: Double
        let isImproving: Bool
        let latestPainLevel: Int?
        let readingCount: Int
    }

    /// Computes trend from pain logs sorted by date (newest first).
    /// - Parameter logs: Pain logs for a single injury, sorted newest first.
    /// - Parameter windowSize: Number of recent readings to consider.
    static func analyzeTrend(
        logs: [PainLog],
        windowSize: Int = 7
    ) -> TrendResult {
        guard !logs.isEmpty else {
            return TrendResult(trailingAverage: 0, isImproving: false, latestPainLevel: nil, readingCount: 0)
        }

        let recent = logs.prefix(windowSize)
        let average = Double(recent.reduce(0) { $0 + $1.painLevel }) / Double(recent.count)
        let latest = logs.first?.painLevel

        // Compare first half vs second half of window to determine trend
        let improving: Bool
        if recent.count >= 2 {
            let midpoint = recent.count / 2
            let newerHalf = recent.prefix(midpoint)
            let olderHalf = recent.dropFirst(midpoint)
            let newerAvg = Double(newerHalf.reduce(0) { $0 + $1.painLevel }) / Double(newerHalf.count)
            let olderAvg = Double(olderHalf.reduce(0) { $0 + $1.painLevel }) / Double(olderHalf.count)
            improving = newerAvg < olderAvg
        } else {
            improving = false
        }

        return TrendResult(
            trailingAverage: average,
            isImproving: improving,
            latestPainLevel: latest,
            readingCount: logs.count
        )
    }

    /// Checks if a pain log has been recorded in the last 24 hours for the given injury.
    static func hasRecentLog(logs: [PainLog], within hours: Double = 24) -> Bool {
        guard let latest = logs.first else { return false }
        return latest.recordedAt.timeIntervalSinceNow > -hours * 3600
    }

    /// Returns the last N pain levels for sparkline display.
    static func sparklineData(logs: [PainLog], count: Int = 7) -> [Int] {
        logs.prefix(count).reversed().map(\.painLevel)
    }
}
