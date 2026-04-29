import Foundation

// MARK: - DailyCoachingRecommendationRecord

/// Persisted CloudKit record for the daily coaching recommendation.
public struct DailyCoachingRecommendationRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let recommendationDate: String
    public let statusRaw: String
    public let title: String
    public let summary: String
    public let primaryActionRaw: String
    public let primaryActionTitle: String
    public let reasonCodes: [String]
    public let recoveryScoreTotal: Int?
    public let recoveryRecommendationRaw: String?
    public let cyclePhaseRaw: String?
    public let cycleConfidence: Double?
    public let trainingLoadTrendRaw: String?
    public let painIntensity: Int?
    public let workoutFocusRaw: String?
    public let energyLevelRaw: String?
    public let equipmentRaw: String?
    public let timeMinutes: Int?
    public let dateCreated: String

    public init(
        id: String = UUID().uuidString,
        recommendationDate: String,
        statusRaw: String,
        title: String,
        summary: String,
        primaryActionRaw: String,
        primaryActionTitle: String,
        reasonCodes: [String],
        recoveryScoreTotal: Int? = nil,
        recoveryRecommendationRaw: String? = nil,
        cyclePhaseRaw: String? = nil,
        cycleConfidence: Double? = nil,
        trainingLoadTrendRaw: String? = nil,
        painIntensity: Int? = nil,
        workoutFocusRaw: String? = nil,
        energyLevelRaw: String? = nil,
        equipmentRaw: String? = nil,
        timeMinutes: Int? = nil,
        dateCreated: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.recommendationDate = recommendationDate
        self.statusRaw = statusRaw
        self.title = title
        self.summary = summary
        self.primaryActionRaw = primaryActionRaw
        self.primaryActionTitle = primaryActionTitle
        self.reasonCodes = reasonCodes
        self.recoveryScoreTotal = recoveryScoreTotal
        self.recoveryRecommendationRaw = recoveryRecommendationRaw
        self.cyclePhaseRaw = cyclePhaseRaw
        self.cycleConfidence = cycleConfidence
        self.trainingLoadTrendRaw = trainingLoadTrendRaw
        self.painIntensity = painIntensity
        self.workoutFocusRaw = workoutFocusRaw
        self.energyLevelRaw = energyLevelRaw
        self.equipmentRaw = equipmentRaw
        self.timeMinutes = timeMinutes
        self.dateCreated = dateCreated
    }
}
