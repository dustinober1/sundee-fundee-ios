import Foundation

// MARK: - ChallengeService

/// Actor-based service for challenge persistence and volume tracking.
///
/// Orchestrates loading/saving challenges through `DataClientProtocol`
/// and delegates pure logic to `ChallengeEngine`.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor ChallengeService {
    private let dataClient: DataClientProtocol
    private static let recordType = "Challenge"

    public init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    // MARK: - CRUD

    /// Loads all challenges.
    public func loadAll() async throws -> [Challenge] {
        try await dataClient.fetchAll(recordType: Self.recordType)
    }

    /// Saves a challenge.
    public func save(_ challenge: Challenge) async throws {
        try await dataClient.save(challenge, recordType: Self.recordType)
    }

    /// Deletes a challenge by ID.
    public func delete(_ challengeId: String) async throws {
        try await dataClient.delete(recordType: Self.recordType, id: challengeId)
    }

    // MARK: - Lifecycle

    /// Creates and saves a lifetime challenge, seeding it with historical volume.
    ///
    /// - Parameter workouts: All completed workouts for retroactive volume.
    /// - Returns: The newly created challenge with retroactive volume applied.
    public func initializeLifetimeChallenge(from workouts: [Workout]) async throws -> Challenge {
        var challenge = ChallengeEngine.createLifetimeChallenge()
        let retroVolume = ChallengeEngine.retroactiveVolume(from: workouts)

        if retroVolume > 0 {
            let (updated, _) = ChallengeEngine.updateVolume(
                challenge: challenge,
                additionalVolumeLbs: retroVolume
            )
            challenge = updated
        }

        try await save(challenge)
        return challenge
    }

    /// Ensures exactly one lifetime challenge exists. Deduplicates if multiple
    /// were created (e.g. from previous decode failures causing repeated creates).
    public func ensureLifetimeChallenge(from workouts: [Workout]) async throws -> Challenge? {
        let existing = try await loadAll()
        let lifetimes = existing.filter { $0.type == .lifetimeVolume }

        if lifetimes.count > 1 {
            // Keep the one with the most volume, delete the rest
            let sorted = lifetimes.sorted { $0.accumulatedVolumeLbs > $1.accumulatedVolumeLbs }
            let keeper = sorted[0]
            for duplicate in sorted.dropFirst() {
                try? await delete(duplicate.id)
            }
            return keeper
        }

        if let lifetime = lifetimes.first {
            return lifetime
        }

        return try await initializeLifetimeChallenge(from: workouts)
    }

    // MARK: - Volume Recording

    /// Updates all active challenges with volume from a completed workout.
    ///
    /// - Parameter workout: The just-completed workout.
    /// - Returns: Celebration events for any tier completions.
    public func recordWorkoutVolume(_ workout: Workout) async throws -> [CelebrationEvent] {
        let challenges = try await loadAll()
        var celebrations: [CelebrationEvent] = []

        for challenge in challenges where challenge.status == .active {
            // Check expiration first
            let checked = ChallengeEngine.checkExpiration(challenge: challenge)
            if checked.status == .expired {
                try await save(checked)
                continue
            }

            // Compute relevant volume for this challenge
            let volume = ChallengeEngine.workoutVolume(
                workout: workout,
                exerciseName: challenge.exerciseName
            )

            guard volume > 0 else { continue }

            let (updated, progress) = ChallengeEngine.updateVolume(
                challenge: challenge,
                additionalVolumeLbs: volume
            )

            try await save(updated)

            // Fire celebration for tier completion
            if let tier = progress.justCompletedTier {
                celebrations.append(.challengeTierCompleted(
                    challengeTitle: challenge.title,
                    tierName: tier.name,
                    volumeLbs: tier.targetVolumeLbs
                ))
            }

            // Fire celebration for full challenge completion
            if updated.status == .completed && challenge.status == .active {
                celebrations.append(.challengeCompleted(challengeTitle: challenge.title))
            }
        }

        return celebrations
    }

    /// Returns the active challenge closest to completing its next tier.
    public func closestToCompletion() async throws -> (Challenge, ChallengeProgress)? {
        let challenges = try await loadAll()
        let active = challenges.filter { $0.status == .active }

        var best: (Challenge, ChallengeProgress)?
        var bestPercent = -1.0

        for challenge in active {
            let progress = ChallengeEngine.computeProgress(challenge: challenge)
            if progress.percentComplete > bestPercent {
                bestPercent = progress.percentComplete
                best = (challenge, progress)
            }
        }

        return best
    }
}
