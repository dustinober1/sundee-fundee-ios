import Foundation

// MARK: - Return-to-Lifting Ramp Record

/// Tracks a progressive ramp back to full loading after pain or injury
/// for a specific body region and movement pattern.
public struct ReturnToLiftingRampRecord: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    /// Body regions affected (comma-separated IDs)
    public let locationIds: String
    /// Affected movement pattern (raw value of WorkoutMovementPattern)
    public let movementPatternRaw: String
    /// Current week in the ramp protocol
    public var currentWeek: Int
    /// Maximum load as a fraction of baseline (0.0–1.0)
    public var maxLoadPercent: Double
    /// Maximum working sets per exercise
    public var maxWorkingSets: Int
    /// When the ramp was first created
    public let dateCreated: Date
    /// When the ramp was last advanced or updated
    public var dateUpdated: Date

    public init(
        id: String = UUID().uuidString,
        locationIds: String,
        movementPatternRaw: String,
        currentWeek: Int = 1,
        maxLoadPercent: Double,
        maxWorkingSets: Int,
        dateCreated: Date = Date(),
        dateUpdated: Date = Date()
    ) {
        self.id = id
        self.locationIds = locationIds
        self.movementPatternRaw = movementPatternRaw
        self.currentWeek = currentWeek
        self.maxLoadPercent = maxLoadPercent
        self.maxWorkingSets = maxWorkingSets
        self.dateCreated = dateCreated
        self.dateUpdated = dateUpdated
    }

    /// Resolved movement pattern enum from raw value.
    public var movementPattern: WorkoutMovementPattern? {
        WorkoutMovementPattern(rawValue: movementPatternRaw)
    }

    // MARK: - Codable (CloudKit-compatible)

    private enum CodingKeys: String, CodingKey {
        case id
        case locationIds
        case movementPatternRaw
        case currentWeek
        case maxLoadPercent
        case maxWorkingSets
        case dateCreated
        case dateUpdated
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        locationIds = try container.decode(String.self, forKey: .locationIds)
        movementPatternRaw = try container.decode(String.self, forKey: .movementPatternRaw)
        currentWeek = try container.decode(Int.self, forKey: .currentWeek)
        maxLoadPercent = try container.decode(Double.self, forKey: .maxLoadPercent)
        // CloudKit bool workaround: try Int first, fall back to Bool
        if let setsInt = try? container.decode(Int.self, forKey: .maxWorkingSets) {
            maxWorkingSets = setsInt
        } else if let setsBool = try? container.decode(Bool.self, forKey: .maxWorkingSets) {
            maxWorkingSets = setsBool ? 1 : 0
        } else {
            maxWorkingSets = 3
        }
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        dateUpdated = try container.decode(Date.self, forKey: .dateUpdated)
    }
}
