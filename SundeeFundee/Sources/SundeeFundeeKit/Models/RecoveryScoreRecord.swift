import Foundation

// MARK: - RecoveryScoreRecord

/// A persisted daily recovery score record for CloudKit storage.
///
/// Field naming follows CloudKit schema rules: avoids reserved names
/// (createdAt, modifiedAt, startDate, endDate) per CLAUDE.md.
/// Dates are stored as ISO8601 strings since CloudKit auto-created
/// date columns become STRING type when encoded with JSONEncoder.iso8601.
public struct RecoveryScoreRecord: Codable, Sendable, Identifiable {

    // MARK: - Properties

    public let id: String
    /// ISO8601 date string for the day this score represents (NOT "date" or "startDate").
    public let scoreDate: String
    /// Total recovery score 0-100.
    public let totalScore: Int
    /// HRV sub-score, nil when HRV data absent.
    public let hrvSubScore: Int?
    /// Sleep sub-score, nil when sleep data absent.
    public let sleepSubScore: Int?
    /// Training load sub-score, nil when training load absent.
    public let loadSubScore: Int?
    /// Cycle phase sub-score, nil when cycle phase unknown.
    public let cyclePhaseSubScore: Int?
    /// Pain sub-score, nil when pain log absent.
    public let painSubScore: Int?
    /// How many of 5 inputs were available for this score.
    public let presentInputCount: Int
    /// CyclePhase.rawValue for trend chart bands.
    public let cyclePhaseRaw: String?
    /// TrainingRecommendation.rawValue.
    public let recommendationRaw: String
    /// ISO8601 timestamp when record was created (NOT "createdAt").
    public let dateCreated: String

    // MARK: - Initialization

    public init(
        id: String = UUID().uuidString,
        scoreDate: String,
        totalScore: Int,
        hrvSubScore: Int? = nil,
        sleepSubScore: Int? = nil,
        loadSubScore: Int? = nil,
        cyclePhaseSubScore: Int? = nil,
        painSubScore: Int? = nil,
        presentInputCount: Int,
        cyclePhaseRaw: String? = nil,
        recommendationRaw: String,
        dateCreated: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.scoreDate = scoreDate
        self.totalScore = totalScore
        self.hrvSubScore = hrvSubScore
        self.sleepSubScore = sleepSubScore
        self.loadSubScore = loadSubScore
        self.cyclePhaseSubScore = cyclePhaseSubScore
        self.painSubScore = painSubScore
        self.presentInputCount = presentInputCount
        self.cyclePhaseRaw = cyclePhaseRaw
        self.recommendationRaw = recommendationRaw
        self.dateCreated = dateCreated
    }
}
