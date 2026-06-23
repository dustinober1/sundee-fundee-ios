import Foundation

// MARK: - BuddyCheckInStatus

/// Status of a buddy check-in entry.
///
/// Only `planned`, `completed`, and `skipped` are valid statuses.
/// This type deliberately excludes any health-related data (cycle phase,
/// pain intensity, HealthKit identifiers, or workout details).
public enum BuddyCheckInStatus: String, Codable, Sendable, Equatable {
    case planned
    case completed
    case skipped
}

// MARK: - BuddyCheckInRecord

/// A lightweight record capturing a buddy check-in for accountability.
///
/// Stores only the display name, status, and an optional message.
/// CloudKit field names: `dateCreated` and `checkInDate` (not `createdAt` or `startDate`).
public struct BuddyCheckInRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let threadID: String
    public let displayName: String
    public let statusRaw: String
    public let message: String?
    public let checkInDate: Date
    public let dateCreated: Date

    /// Computed convenience accessor for the status enum.
    public var status: BuddyCheckInStatus {
        BuddyCheckInStatus(rawValue: statusRaw) ?? .planned
    }

    public init(
        id: String,
        threadID: String,
        displayName: String,
        statusRaw: String,
        message: String?,
        checkInDate: Date,
        dateCreated: Date
    ) {
        self.id = id
        self.threadID = threadID
        self.displayName = displayName
        self.statusRaw = statusRaw
        self.message = message
        self.checkInDate = checkInDate
        self.dateCreated = dateCreated
    }

    // MARK: - Coding Keys

    private enum CodingKeys: String, CodingKey {
        case id
        case threadID
        case displayName
        case statusRaw
        case message
        case checkInDate
        case dateCreated
    }
}
