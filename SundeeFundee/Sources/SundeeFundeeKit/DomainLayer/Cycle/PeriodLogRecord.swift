import Foundation

// MARK: - PeriodLogRecord

/// A manually-entered period log with start and end dates.
/// Stored as "PeriodLogRecord" in the data client.
/// Supplements HealthKit data for users who prefer manual tracking.
public struct PeriodLogRecord: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let startDate: Date
    public var endDate: Date?

    public init(id: String = UUID().uuidString, startDate: Date, endDate: Date? = nil) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
    }

    /// Whether this period is still active (no end date set).
    public var isActive: Bool {
        endDate == nil
    }

    /// Convert to the domain PeriodLog type used by cycle calculations.
    public func toPeriodLog() -> PeriodLog {
        PeriodLog(startDate: startDate, endDate: endDate)
    }
}
