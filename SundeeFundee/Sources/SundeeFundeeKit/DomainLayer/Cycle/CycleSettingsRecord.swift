import Foundation

// MARK: - CycleSettingsRecord

/// User's menstrual cycle tracking settings.
///
/// At most one record exists per user. Uses a fixed `id` so every save
/// upserts the same record instead of creating duplicates.
public struct CycleSettingsRecord: Codable, Sendable, Equatable {
    public let id: String
    public let averageCycleLengthDays: Int
    public let lastPeriodStart: Date?

    public init(averageCycleLengthDays: Int, lastPeriodStart: Date? = nil) {
        self.id = "cycle_settings"
        self.averageCycleLengthDays = averageCycleLengthDays
        self.lastPeriodStart = lastPeriodStart
    }
}
