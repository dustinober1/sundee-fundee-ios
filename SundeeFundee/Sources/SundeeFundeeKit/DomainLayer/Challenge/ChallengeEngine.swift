import Foundation

// MARK: - ChallengeEngine

/// Pure domain logic for weight volume challenges.
///
/// All functions are static and side-effect-free — they accept data
/// and return data without touching any persistence layer.
public enum ChallengeEngine {

    // MARK: - Default Tiers

    /// Standard lifetime challenge tiers: Bronze (250K), Silver (500K), Gold (1M).
    public static func defaultLifetimeTiers() -> [ChallengeTier] {
        [
            ChallengeTier(name: "Bronze", targetVolumeLbs: 250_000, ordinal: 0),
            ChallengeTier(name: "Silver", targetVolumeLbs: 500_000, ordinal: 1),
            ChallengeTier(name: "Gold", targetVolumeLbs: 1_000_000, ordinal: 2),
        ]
    }

    // MARK: - Challenge Creation

    /// Creates a lifetime volume challenge with default tiers.
    public static func createLifetimeChallenge() -> Challenge {
        Challenge(
            type: .lifetimeVolume,
            title: "Lifetime Volume",
            tiers: defaultLifetimeTiers()
        )
    }

    /// Creates a per-exercise volume challenge.
    public static func createExerciseChallenge(
        exerciseName: String,
        tiers: [ChallengeTier]
    ) -> Challenge {
        Challenge(
            type: .exerciseVolume,
            title: "\(exerciseName) Volume",
            exerciseName: exerciseName,
            tiers: tiers
        )
    }

    /// Creates a custom time-boxed challenge.
    public static func createCustomChallenge(
        title: String,
        targetVolumeLbs: Double,
        endDate: Date? = nil
    ) -> Challenge {
        let tier = ChallengeTier(name: "Goal", targetVolumeLbs: targetVolumeLbs, ordinal: 0)
        return Challenge(
            type: .custom,
            title: title,
            tiers: [tier],
            endDate: endDate
        )
    }

    // MARK: - Progress Computation

    /// Computes the current progress of a challenge.
    public static func computeProgress(challenge: Challenge) -> ChallengeProgress {
        let tiers = challenge.tiers.sorted { $0.ordinal < $1.ordinal }

        guard !tiers.isEmpty else {
            return ChallengeProgress(
                currentTierName: "—",
                percentComplete: 0,
                volumeRemaining: 0,
                isFullyComplete: true
            )
        }

        // If all tiers completed
        if challenge.currentTierIndex >= tiers.count || challenge.status == .completed {
            let lastTier = tiers.last!
            return ChallengeProgress(
                currentTierName: lastTier.name,
                percentComplete: 1.0,
                volumeRemaining: 0,
                isFullyComplete: true
            )
        }

        let currentTier = tiers[challenge.currentTierIndex]
        let previousTarget = challenge.currentTierIndex > 0
            ? tiers[challenge.currentTierIndex - 1].targetVolumeLbs
            : 0

        let tierRange = currentTier.targetVolumeLbs - previousTarget
        let tierProgress = challenge.accumulatedVolumeLbs - previousTarget
        let percent = tierRange > 0 ? min(max(tierProgress / tierRange, 0), 1.0) : 1.0
        let remaining = max(currentTier.targetVolumeLbs - challenge.accumulatedVolumeLbs, 0)

        return ChallengeProgress(
            currentTierName: currentTier.name,
            percentComplete: percent,
            volumeRemaining: remaining,
            isFullyComplete: false
        )
    }

    // MARK: - Volume Update

    /// Updates a challenge with additional volume, advancing tiers as needed.
    ///
    /// - Returns: Updated challenge. Check the returned `ChallengeProgress` for `justCompletedTier`.
    public static func updateVolume(
        challenge: Challenge,
        additionalVolumeLbs: Double
    ) -> (challenge: Challenge, progress: ChallengeProgress) {
        var updated = challenge
        updated.accumulatedVolumeLbs += additionalVolumeLbs

        let tiers = updated.tiers.sorted { $0.ordinal < $1.ordinal }
        var justCompleted: ChallengeTier?

        // Advance through tiers
        while updated.currentTierIndex < tiers.count {
            let tier = tiers[updated.currentTierIndex]
            if updated.accumulatedVolumeLbs >= tier.targetVolumeLbs {
                justCompleted = tier
                updated.currentTierIndex += 1
            } else {
                break
            }
        }

        // Check if fully complete
        if updated.currentTierIndex >= tiers.count {
            updated.status = .completed
        }

        var progress = computeProgress(challenge: updated)
        progress = ChallengeProgress(
            currentTierName: progress.currentTierName,
            percentComplete: progress.percentComplete,
            volumeRemaining: progress.volumeRemaining,
            justCompletedTier: justCompleted,
            isFullyComplete: progress.isFullyComplete
        )

        return (updated, progress)
    }

    // MARK: - Retroactive Volume

    /// Computes total historical volume from workout history.
    ///
    /// - Parameters:
    ///   - workouts: All completed workouts.
    ///   - exerciseName: If provided, only counts volume from this exercise.
    /// - Returns: Total volume in pounds.
    public static func retroactiveVolume(
        from workouts: [Workout],
        exerciseName: String? = nil
    ) -> Double {
        var total = 0.0
        for workout in workouts where workout.isComplete {
            for exercise in workout.exercises {
                if let name = exerciseName, exercise.name != name {
                    continue
                }
                for set in exercise.targetSets {
                    let reps = set.actualReps ?? set.reps
                    let weight = (set.completedWeight ?? 0) > 0
                        ? set.completedWeight!
                        : (set.prescribedWeight > 0 ? set.prescribedWeight : 0)
                    total += Double(reps) * weight
                }
            }
        }
        return total
    }

    // MARK: - Expiration Check

    /// Marks a challenge as expired if its end date has passed.
    public static func checkExpiration(
        challenge: Challenge,
        referenceDate: Date = Date()
    ) -> Challenge {
        guard challenge.status == .active,
              let endDate = challenge.endDate,
              referenceDate > endDate else {
            return challenge
        }
        var updated = challenge
        updated.status = .expired
        return updated
    }

    // MARK: - Workout Volume Extraction

    /// Extracts the relevant volume from a single workout for a challenge.
    public static func workoutVolume(
        workout: Workout,
        exerciseName: String? = nil
    ) -> Double {
        if let name = exerciseName {
            // Per-exercise: only count matching exercises
            return workout.exercises
                .filter { $0.name == name }
                .flatMap { $0.targetSets }
                .reduce(0.0) { sum, set in
                    let reps = set.actualReps ?? set.reps
                    let weight = (set.completedWeight ?? 0) > 0
                        ? set.completedWeight!
                        : (set.prescribedWeight > 0 ? set.prescribedWeight : 0)
                    return sum + Double(reps) * weight
                }
        }
        return workout.totalVolume
    }
}
