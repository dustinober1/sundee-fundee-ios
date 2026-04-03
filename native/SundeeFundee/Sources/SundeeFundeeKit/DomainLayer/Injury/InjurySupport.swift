import Foundation

// MARK: - Load Multipliers

/// Load multipliers for injury adaptation
public struct LoadMultipliers: Sendable {
    public let load: Double
    public let sets: Double
    public let reps: Double

    public init(load: Double, sets: Double, reps: Double) {
        self.load = load
        self.sets = sets
        self.reps = reps
    }
}

/// Load multipliers per recovery phase
public let loadMultipliers: [RecoveryPhase: LoadMultipliers] = [
    .acute:        LoadMultipliers(load: 0,    sets: 0,    reps: 0),
    .rehab:        LoadMultipliers(load: 0.30, sets: 0.50, reps: 0.70),
    .lightLoad:    LoadMultipliers(load: 0.50, sets: 0.75, reps: 0.85),
    .returnToPlay: LoadMultipliers(load: 0.80, sets: 0.90, reps: 1.0),
    .resolved:     LoadMultipliers(load: 1.0,  sets: 1.0,  reps: 1.0),
]

// MARK: - Exercise Value Adjustment

/// Adjust an exercise value by a multiplier
public func adjustExerciseValueByMultiplier(_ value: ExerciseValue, multiplier: Double) -> ExerciseValue {
    switch value {
    case .fixed(let v):
        return .fixed(value: max(1, Int(round(Double(v) * multiplier))))
    case .range(let low, let high):
        let newLo = max(1, Int(round(Double(low) * multiplier)))
        let newHi = max(newLo, Int(round(Double(high) * multiplier)))
        return .range(low: newLo, high: newHi)
    case .amrap, .text:
        return value
    }
}

/// Adjust a percent1RM by a multiplier
public func adjustLoad(_ percent1RM: Double?, multiplier: Double) -> Double? {
    guard let percent1RM else { return nil }
    return percent1RM * multiplier
}

// MARK: - Pain Log

/// A pain level log entry
public struct PainLog: Codable, Sendable {
    public let injuryId: String
    public let painLevel: Int  // 0-10
    public let recordedAt: Date

    public init(injuryId: String, painLevel: Int, recordedAt: Date) {
        self.injuryId = injuryId
        self.painLevel = painLevel
        self.recordedAt = recordedAt
    }
}

// MARK: - Pain Trend Analyzer

/// Result of pain trend analysis
public struct TrendResult: Sendable {
    public let trailingAverage: Double
    public let isImproving: Bool
    public let latestPainLevel: Int?
    public let readingCount: Int
}

/// Analyze pain trend from logs. windowSize: number of recent readings to consider.
public func analyzePainTrend(logs: [PainLog], windowSize: Int = 7) -> TrendResult {
    guard !logs.isEmpty else {
        return TrendResult(trailingAverage: 0, isImproving: false, latestPainLevel: nil, readingCount: 0)
    }

    let sorted = logs.sorted { $0.recordedAt > $1.recordedAt }
    let recent = Array(sorted.prefix(windowSize))
    let average = Double(recent.reduce(0) { $0 + $1.painLevel }) / Double(recent.count)
    let latest = recent.first?.painLevel

    var improving = false
    if recent.count >= 2 {
        let midpoint = recent.count / 2
        let newerHalf = Array(recent.prefix(midpoint))
        let olderHalf = Array(recent.suffix(from: midpoint))
        let newerAvg = Double(newerHalf.reduce(0) { $0 + $1.painLevel }) / Double(newerHalf.count)
        let olderAvg = Double(olderHalf.reduce(0) { $0 + $1.painLevel }) / Double(olderHalf.count)
        improving = newerAvg < olderAvg
    }

    return TrendResult(
        trailingAverage: average,
        isImproving: improving,
        latestPainLevel: latest,
        readingCount: logs.count
    )
}

/// Check if a pain log has been recorded within the given hours window.
public func hasRecentLog(logs: [PainLog], referenceDate: Date = Date(), withinHours: Double = 24) -> Bool {
    guard !logs.isEmpty else { return false }
    let cutoff = referenceDate.addingTimeInterval(-withinHours * 3600)
    return logs.contains { $0.recordedAt >= cutoff }
}

/// Returns the last N pain levels in chronological order (oldest first) for sparkline display.
public func sparklineData(logs: [PainLog], count: Int = 7) -> [Int] {
    let sorted = logs.sorted { $0.recordedAt > $1.recordedAt }
    return Array(sorted.prefix(count).map(\.painLevel).reversed())
}

// MARK: - Phase Transition Advisor

/// Suggestion to advance an injury to the next recovery phase
public struct TransitionSuggestion: Sendable {
    public let injuryId: String
    public let currentPhase: RecoveryPhase
    public let suggestedPhase: RecoveryPhase
}

private struct TransitionRule {
    let from: RecoveryPhase
    let to: RecoveryPhase
    let count: Int
    let maxPain: Int
}

private let phaseTransitionRules: [TransitionRule] = [
    TransitionRule(from: .acute,        to: .rehab,        count: 3, maxPain: 5),
    TransitionRule(from: .rehab,        to: .lightLoad,    count: 3, maxPain: 3),
    TransitionRule(from: .lightLoad,    to: .returnToPlay, count: 3, maxPain: 2),
    TransitionRule(from: .returnToPlay, to: .resolved,     count: 5, maxPain: 1),
]

private func meetsThreshold(logs: [PainLog], count: Int, maxPain: Int) -> Bool {
    guard logs.count >= count else { return false }
    return logs.prefix(count).allSatisfy { $0.painLevel <= maxPain }
}

/// Evaluate whether an injury is ready to advance to the next recovery phase.
/// Returns nil if no transition is suggested.
public func evaluateTransition(
    injuryId: String,
    currentPhase: RecoveryPhase,
    painLogs: [PainLog]
) -> TransitionSuggestion? {
    let sorted = painLogs.sorted { $0.recordedAt > $1.recordedAt }
    let recent = Array(sorted.prefix(5))

    guard let rule = phaseTransitionRules.first(where: { $0.from == currentPhase }) else {
        return nil
    }

    if meetsThreshold(logs: recent, count: rule.count, maxPain: rule.maxPain) {
        return TransitionSuggestion(injuryId: injuryId, currentPhase: currentPhase, suggestedPhase: rule.to)
    }
    return nil
}
