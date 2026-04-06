import Foundation

// MARK: - CycleSettingsRecord

/// User's menstrual cycle tracking settings.
///
/// At most one record exists per user. Extracted from SettingsView.swift
/// for shared use across the app.
public struct CycleSettingsRecord: Codable, Sendable, Equatable {
    public let averageCycleLengthDays: Int
    public let lastPeriodStart: Date?

    public init(averageCycleLengthDays: Int, lastPeriodStart: Date? = nil) {
        self.averageCycleLengthDays = averageCycleLengthDays
        self.lastPeriodStart = lastPeriodStart
    }
}
