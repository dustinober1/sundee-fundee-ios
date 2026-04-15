import Foundation

// MARK: - Challenge Type

public enum ChallengeType: String, Codable, Sendable {
    /// Lifetime total volume across all exercises (250K, 500K, 1M lbs).
    case lifetimeVolume
    /// Per-exercise total volume (e.g., Squat 500K lbs).
    case exerciseVolume
    /// User-defined challenge with custom goal and optional timeframe.
    case custom
}

// MARK: - Challenge Status

public enum ChallengeStatus: String, Codable, Sendable {
    case active
    case completed
    case expired
}

// MARK: - Challenge Tier

public struct ChallengeTier: Codable, Sendable, Equatable {
    /// Display name (e.g., "Bronze", "Silver", "Gold").
    public let name: String
    /// Target volume in pounds.
    public let targetVolumeLbs: Double
    /// Sequential order (0-indexed).
    public let ordinal: Int

    public init(name: String, targetVolumeLbs: Double, ordinal: Int) {
        self.name = name
        self.targetVolumeLbs = targetVolumeLbs
        self.ordinal = ordinal
    }
}

// MARK: - Challenge

public struct Challenge: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let type: ChallengeType
    public let title: String
    /// Specific exercise name for per-exercise challenges; nil for lifetime.
    public let exerciseName: String?
    public let tiers: [ChallengeTier]
    public var currentTierIndex: Int
    public var accumulatedVolumeLbs: Double
    public var status: ChallengeStatus
    public let challengeStartDate: Date
    /// Nil = no deadline (lifetime challenges).
    public let challengeEndDate: Date?
    public let dateCreated: Date

    public init(
        id: String = UUID().uuidString,
        type: ChallengeType,
        title: String,
        exerciseName: String? = nil,
        tiers: [ChallengeTier],
        currentTierIndex: Int = 0,
        accumulatedVolumeLbs: Double = 0,
        status: ChallengeStatus = .active,
        challengeStartDate: Date = Date(),
        challengeEndDate: Date? = nil,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.exerciseName = exerciseName
        self.tiers = tiers
        self.currentTierIndex = currentTierIndex
        self.accumulatedVolumeLbs = accumulatedVolumeLbs
        self.status = status
        self.challengeStartDate = challengeStartDate
        self.challengeEndDate = challengeEndDate
        self.dateCreated = dateCreated
    }

    // MARK: - Backwards-compatible decoding
    //
    // Older records used `startDate`/`endDate`/`createdAt` which collide with
    // CloudKit system fields. The model was renamed but existing records in
    // CloudKit and LocalDataClient still have the old keys.

    private enum CodingKeys: String, CodingKey {
        case id, type, title, exerciseName, tiers
        case currentTierIndex, accumulatedVolumeLbs, status
        case challengeStartDate, challengeEndDate, dateCreated
        // Legacy keys
        case startDate, endDate, createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(ChallengeType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        exerciseName = try container.decodeIfPresent(String.self, forKey: .exerciseName)
        tiers = try container.decode([ChallengeTier].self, forKey: .tiers)
        currentTierIndex = try container.decode(Int.self, forKey: .currentTierIndex)
        accumulatedVolumeLbs = try container.decode(Double.self, forKey: .accumulatedVolumeLbs)
        status = try container.decode(ChallengeStatus.self, forKey: .status)

        // Date fields: try new name first, fall back to legacy name
        if let date = try container.decodeIfPresent(Date.self, forKey: .challengeStartDate) {
            challengeStartDate = date
        } else {
            challengeStartDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        }

        if let date = try container.decodeIfPresent(Date.self, forKey: .challengeEndDate) {
            challengeEndDate = date
        } else {
            challengeEndDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        }

        if let date = try container.decodeIfPresent(Date.self, forKey: .dateCreated) {
            dateCreated = date
        } else {
            dateCreated = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(exerciseName, forKey: .exerciseName)
        try container.encode(tiers, forKey: .tiers)
        try container.encode(currentTierIndex, forKey: .currentTierIndex)
        try container.encode(accumulatedVolumeLbs, forKey: .accumulatedVolumeLbs)
        try container.encode(status, forKey: .status)
        try container.encode(challengeStartDate, forKey: .challengeStartDate)
        try container.encodeIfPresent(challengeEndDate, forKey: .challengeEndDate)
        try container.encode(dateCreated, forKey: .dateCreated)
    }
}

// MARK: - Challenge Progress

public struct ChallengeProgress: Sendable {
    /// Name of the current tier being pursued.
    public let currentTierName: String
    /// Progress within the current tier (0.0–1.0).
    public let percentComplete: Double
    /// Pounds remaining to complete the current tier.
    public let volumeRemaining: Double
    /// Non-nil if a tier was just completed by the last volume update.
    public let justCompletedTier: ChallengeTier?
    /// True if all tiers are complete.
    public let isFullyComplete: Bool

    public init(
        currentTierName: String,
        percentComplete: Double,
        volumeRemaining: Double,
        justCompletedTier: ChallengeTier? = nil,
        isFullyComplete: Bool = false
    ) {
        self.currentTierName = currentTierName
        self.percentComplete = percentComplete
        self.volumeRemaining = volumeRemaining
        self.justCompletedTier = justCompletedTier
        self.isFullyComplete = isFullyComplete
    }
}
