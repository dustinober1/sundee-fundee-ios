package com.sundeefundee.core.domain.celebration

import com.sundeefundee.core.domain.benchmark.BenchmarkScoringType

// MARK: - Celebration Event

/**
 * A celebration-worthy event in the app.
 */
sealed class CelebrationEvent {

    /** A workout was completed. */
    data class WorkoutCompleted(
        val durationSeconds: Int
    ) : CelebrationEvent()

    /** A new personal record was set. */
    data class NewPersonalRecord(
        val exerciseName: String,
        val weightKg: Double
    ) : CelebrationEvent()

    /** A program was completed. */
    data class ProgramCompleted(
        val programName: String
    ) : CelebrationEvent()

    /** A weight milestone was reached. */
    data class WeightMilestone(
        val exerciseName: String,
        val thresholdKg: Double
    ) : CelebrationEvent()

    /** A new conditioning PR was achieved. */
    data class NewConditioningPR(
        val exerciseName: String,
        val value: Double,
        val scoringType: BenchmarkScoringType
    ) : CelebrationEvent()

    /** A challenge tier was completed. */
    data class ChallengeTierCompleted(
        val challengeTitle: String,
        val tierName: String,
        val volumeLbs: Double
    ) : CelebrationEvent()
}

// MARK: - Title & Subtitle

/**
 * Title for a celebration event.
 */
fun celebrationTitle(event: CelebrationEvent): String = when (event) {
    is CelebrationEvent.WorkoutCompleted -> "Workout Complete!"
    is CelebrationEvent.NewPersonalRecord -> "New Personal Record!"
    is CelebrationEvent.ProgramCompleted -> "Program Complete!"
    is CelebrationEvent.WeightMilestone -> "Weight Milestone!"
    is CelebrationEvent.NewConditioningPR -> "New Conditioning PR!"
    is CelebrationEvent.ChallengeTierCompleted -> "Challenge Milestone!"
}

/**
 * Subtitle for a celebration event.
 *
 * @param event The celebration event.
 * @param unit Weight unit string ("kg" or "lb").
 */
fun celebrationSubtitle(event: CelebrationEvent, unit: String = "kg"): String = when (event) {
    is CelebrationEvent.WorkoutCompleted -> {
        val minutes = event.durationSeconds / 60
        if (minutes > 0) "Completed in $minutes min" else "Workout saved!"
    }
    is CelebrationEvent.NewPersonalRecord -> {
        val converted = if (unit == "lb") event.weightKg * 2.20462 else event.weightKg
        val formatted = formatWeight(converted)
        "${event.exerciseName} — $formatted $unit estimated 1RM"
    }
    is CelebrationEvent.ProgramCompleted -> {
        "You finished ${event.programName}. Time to level up!"
    }
    is CelebrationEvent.WeightMilestone -> {
        val converted = if (unit == "lb") event.thresholdKg * 2.20462 else event.thresholdKg
        "${event.exerciseName} hit ${kotlin.math.round(converted).toInt()} $unit!"
    }
    is CelebrationEvent.NewConditioningPR -> {
        val formatted = formatConditioningValue(event.value, event.scoringType)
        "${event.exerciseName} — $formatted"
    }
    is CelebrationEvent.ChallengeTierCompleted -> {
        val formatted = formatWeight(event.volumeLbs)
        "${event.challengeTitle} — ${event.tierName} tier at $formatted lbs!"
    }
}

// MARK: - Private Helpers

/**
 * Format a conditioning value based on scoring type.
 */
private fun formatConditioningValue(value: Double, scoringType: BenchmarkScoringType): String =
    when (scoringType) {
        BenchmarkScoringType.TIME -> {
            val totalSeconds = value.toInt()
            val minutes = totalSeconds / 60
            val seconds = totalSeconds % 60
            "$minutes:${String.format("%02d", seconds)}"
        }
        BenchmarkScoringType.REPS -> {
            val count = value.toInt()
            if (count == 1) "1 rep" else "$count reps"
        }
        BenchmarkScoringType.ROUNDS_AND_REPS -> {
            val rounds = value.toInt() / 10000
            val reps = value.toInt() % 10000
            "$rounds rounds + $reps reps"
        }
        BenchmarkScoringType.DISTANCE -> "${value.toInt()} m"
        BenchmarkScoringType.LOAD -> "${value.toInt()} kg"
        BenchmarkScoringType.CALORIES -> "${value.toInt()} kg"
    }

/**
 * Format a weight value, removing trailing .0.
 */
private fun formatWeight(value: Double): String {
    return if (value == kotlin.math.round(value)) {
        "${value.toInt()}"
    } else {
        String.format("%.1f", value)
    }
}
