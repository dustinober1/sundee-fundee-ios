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
    public let startDate: Date
    /// Nil = no deadline (lifetime challenges).
    public let endDate: Date?
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
        startDate: Date = Date(),
        endDate: Date? = nil,
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
        self.startDate = startDate
        self.endDate = endDate
        self.dateCreated = dateCreated
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
