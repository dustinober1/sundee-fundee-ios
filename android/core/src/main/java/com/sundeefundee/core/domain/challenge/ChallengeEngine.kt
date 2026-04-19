package com.sundeefundee.core.domain.challenge

import com.sundeefundee.core.model.Challenge
import com.sundeefundee.core.model.ChallengeProgress
import com.sundeefundee.core.model.ChallengeStatus
import com.sundeefundee.core.model.ChallengeTier
import com.sundeefundee.core.model.ChallengeType
import com.sundeefundee.core.model.Workout
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.todayIn

// MARK: - ChallengeEngine

/// Pure domain logic for weight volume challenges.
///
/// All functions are side-effect-free — they accept data
/// and return data without touching any persistence layer.
object ChallengeEngine {

    // MARK: - Default Tiers

    /// Standard lifetime challenge tiers: Bronze (250K), Silver (500K), Gold (1M).
    fun defaultLifetimeTiers(): List<ChallengeTier> = listOf(
        ChallengeTier(name = "Bronze", targetVolumeLbs = 250_000.0, ordinal = 0),
        ChallengeTier(name = "Silver", targetVolumeLbs = 500_000.0, ordinal = 1),
        ChallengeTier(name = "Gold", targetVolumeLbs = 1_000_000.0, ordinal = 2)
    )

    // MARK: - Challenge Creation

    /// Creates a lifetime volume challenge with default tiers.
    fun createLifetimeChallenge(): Challenge {
        val now = Clock.System.todayIn(TimeZone.currentSystemDefault()).toString()
        return Challenge(
            id = java.util.UUID.randomUUID().toString(),
            type = ChallengeType.LIFETIME_VOLUME,
            title = "Lifetime Volume",
            tiers = defaultLifetimeTiers(),
            challengeStartDate = now,
            dateCreated = now
        )
    }

    /// Creates a per-exercise volume challenge.
    fun createExerciseChallenge(
        exerciseName: String,
        tiers: List<ChallengeTier>
    ): Challenge {
        val now = Clock.System.todayIn(TimeZone.currentSystemDefault()).toString()
        return Challenge(
            id = java.util.UUID.randomUUID().toString(),
            type = ChallengeType.EXERCISE_VOLUME,
            title = "$exerciseName Volume",
            exerciseName = exerciseName,
            tiers = tiers,
            challengeStartDate = now,
            dateCreated = now
        )
    }

    /// Creates a custom time-boxed challenge.
    fun createCustomChallenge(
        title: String,
        targetVolumeLbs: Double,
        endDate: String? = null
    ): Challenge {
        val now = Clock.System.todayIn(TimeZone.currentSystemDefault()).toString()
        val tier = ChallengeTier(name = "Goal", targetVolumeLbs = targetVolumeLbs, ordinal = 0)
        return Challenge(
            id = java.util.UUID.randomUUID().toString(),
            type = ChallengeType.CUSTOM,
            title = title,
            tiers = listOf(tier),
            challengeStartDate = now,
            challengeEndDate = endDate,
            dateCreated = now
        )
    }

    // MARK: - Progress Computation

    /// Computes the current progress of a challenge.
    fun computeProgress(challenge: Challenge): ChallengeProgress {
        val tiers = challenge.tiers.sortedBy { it.ordinal }

        if (tiers.isEmpty()) {
            return ChallengeProgress(
                currentTierName = "\u2014",
                percentComplete = 0.0,
                volumeRemaining = 0.0,
                isFullyComplete = true
            )
        }

        // If all tiers completed
        if (challenge.currentTierIndex >= tiers.size || challenge.status == ChallengeStatus.COMPLETED) {
            val lastTier = tiers.last()
            return ChallengeProgress(
                currentTierName = lastTier.name,
                percentComplete = 1.0,
                volumeRemaining = 0.0,
                isFullyComplete = true
            )
        }

        val currentTier = tiers[challenge.currentTierIndex]
        val previousTarget = if (challenge.currentTierIndex > 0) {
            tiers[challenge.currentTierIndex - 1].targetVolumeLbs
        } else {
            0.0
        }

        val tierRange = currentTier.targetVolumeLbs - previousTarget
        val tierProgress = challenge.accumulatedVolumeLbs - previousTarget
        val percent = if (tierRange > 0) {
            (tierProgress / tierRange).coerceIn(0.0, 1.0)
        } else {
            1.0
        }
        val remaining = maxOf(currentTier.targetVolumeLbs - challenge.accumulatedVolumeLbs, 0.0)

        return ChallengeProgress(
            currentTierName = currentTier.name,
            percentComplete = percent,
            volumeRemaining = remaining,
            isFullyComplete = false
        )
    }

    // MARK: - Volume Update

    /// Updates a challenge with additional volume, advancing tiers as needed.
    ///
    /// @return Pair of (updated challenge, progress with justCompletedTier set if applicable).
    fun updateVolume(
        challenge: Challenge,
        additionalVolumeLbs: Double
    ): Pair<Challenge, ChallengeProgress> {
        var accumulated = challenge.accumulatedVolumeLbs + additionalVolumeLbs
        var tierIndex = challenge.currentTierIndex
        val tiers = challenge.tiers.sortedBy { it.ordinal }
        var justCompleted: ChallengeTier? = null

        // Advance through tiers
        while (tierIndex < tiers.size) {
            val tier = tiers[tierIndex]
            if (accumulated >= tier.targetVolumeLbs) {
                justCompleted = tier
                tierIndex++
            } else {
                break
            }
        }

        // Determine final status
        val status = if (tierIndex >= tiers.size) {
            ChallengeStatus.COMPLETED
        } else {
            challenge.status
        }

        val updated = challenge.copy(
            accumulatedVolumeLbs = accumulated,
            currentTierIndex = tierIndex,
            status = status
        )

        val progress = computeProgress(updated).copy(
            justCompletedTier = justCompleted
        )

        return Pair(updated, progress)
    }

    // MARK: - Retroactive Volume

    /// Computes total historical volume from workout history.
    ///
    /// @param workouts All completed workouts.
    /// @param exerciseName If provided, only counts volume from this exercise.
    /// @return Total volume in pounds.
    fun retroactiveVolume(
        workouts: List<Workout>,
        exerciseName: String? = null
    ): Double {
        var total = 0.0
        for (workout in workouts) {
            if (!workout.isComplete) continue
            for (exercise in workout.exercises) {
                if (exerciseName != null && exercise.name != exerciseName) continue
                for (set in exercise.targetSets) {
                    val reps = set.actualReps ?: set.reps
                    val weight = if ((set.completedWeight ?: 0.0) > 0) {
                        set.completedWeight!!
                    } else if (set.prescribedWeight > 0) {
                        set.prescribedWeight
                    } else {
                        0.0
                    }
                    total += reps.toDouble() * weight
                }
            }
        }
        return total
    }

    // MARK: - Expiration Check

    /// Marks a challenge as expired if its end date has passed.
    fun checkExpiration(
        challenge: Challenge,
        referenceDate: String // ISO8601
    ): Challenge {
        if (challenge.status != ChallengeStatus.ACTIVE) return challenge
        val endDate = challenge.challengeEndDate ?: return challenge
        if (referenceDate > endDate) {
            return challenge.copy(status = ChallengeStatus.EXPIRED)
        }
        return challenge
    }

    // MARK: - Workout Volume Extraction

    /// Extracts the relevant volume from a single workout for a challenge.
    fun workoutVolume(
        workout: Workout,
        exerciseName: String? = null
    ): Double {
        if (exerciseName != null) {
            // Per-exercise: only count matching exercises
            return workout.exercises
                .filter { it.name == exerciseName }
                .flatMap { it.targetSets }
                .fold(0.0) { sum, set ->
                    val reps = set.actualReps ?: set.reps
                    val weight = if ((set.completedWeight ?: 0.0) > 0) {
                        set.completedWeight!!
                    } else if (set.prescribedWeight > 0) {
                        set.prescribedWeight
                    } else {
                        0.0
                    }
                    sum + reps.toDouble() * weight
                }
        }
        return workout.totalVolume
    }
}
