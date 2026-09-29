import Foundation

// MARK: - SocialMemberSnapshot

/// Privacy-safe snapshot of a member's weekly consistency and workout volume.
///
/// Strictly REDACTS any health signals: cycle phases, symptoms, pain logs,
/// and HealthKit samples are never admitted into this payload.
public struct SocialMemberSnapshot: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let displayName: String
    public let weeklyCompletedWorkouts: Int
    public let currentStreakDays: Int
    public let weeklyGoalTarget: Int
    public let lastActiveDate: Date
    public let dateCreated: Date

    public init(
        id: String,
        displayName: String,
        weeklyCompletedWorkouts: Int,
        currentStreakDays: Int,
        weeklyGoalTarget: Int,
        lastActiveDate: Date,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.weeklyCompletedWorkouts = max(0, weeklyCompletedWorkouts)
        self.currentStreakDays = max(0, currentStreakDays)
        self.weeklyGoalTarget = max(1, weeklyGoalTarget)
        self.lastActiveDate = lastActiveDate
        self.dateCreated = dateCreated
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case weeklyCompletedWorkouts
        case currentStreakDays
        case weeklyGoalTarget
        case lastActiveDate
        case dateCreated
    }
}
