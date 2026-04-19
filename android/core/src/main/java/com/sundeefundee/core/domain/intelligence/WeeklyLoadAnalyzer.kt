package com.sundeefundee.core.domain.intelligence

import com.sundeefundee.core.model.CompletedWorkoutRecord
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.WeekFields
import java.util.Locale
import kotlin.math.pow
import kotlin.math.round

/**
 * Analyzes completed workout history to surface volume, intensity,
 * frequency, and muscle-group balance trends over rolling weeks.
 *
 * Pure domain logic -- no framework dependencies.
 */
object WeeklyLoadAnalyzer {

    // MARK: - Types

    /** Summary of a single training week. */
    data class WeeklySummary(
        /** The Monday that starts this ISO week. */
        val weekStartDate: LocalDate,
        /** Total number of workouts completed. */
        val workoutCount: Int,
        /** Total training duration in minutes. */
        val totalMinutes: Int,
        /** Distinct muscle groups trained (from exercise names). */
        val muscleGroupsHit: Set<String>,
        /** Exercises performed this week. */
        val exerciseNames: List<String>
    )

    /** A detected trend across multiple weeks. */
    data class LoadTrend(
        val type: TrendType,
        val message: String,
        val severity: TrendSeverity
    )

    /** Types of detectable training trends. */
    enum class TrendType {
        /** Workout frequency is declining. */
        FREQUENCY_DROP,
        /** Workout frequency is increasing nicely. */
        FREQUENCY_RISE,
        /** Muscle group imbalance detected. */
        MUSCLE_IMBALANCE,
        /** Possible overreaching (too much volume). */
        OVERREACHING,
        /** Undertraining (very low volume). */
        UNDERTRAINING,
        /** Consistent training pattern. */
        CONSISTENT,
        /** Push/pull ratio imbalance within a week. */
        PUSH_PULL_IMBALANCE,
        /** Repeating pattern of missed/dropped weeks. */
        MISSED_SESSION_PATTERN,
    }

    /** Severity level for a detected trend. */
    enum class TrendSeverity {
        INFO,
        WARNING,
        POSITIVE
    }

    // MARK: - Analysis

    /**
     * Builds weekly summaries from completed workout records.
     *
     * @param workouts Completed workout records.
     * @param weekCount Number of recent weeks to analyze (default 4).
     * @return Weekly summaries sorted oldest-first.
     */
    fun weeklySummaries(
        workouts: List<CompletedWorkoutRecord>,
        weekCount: Int = 4
    ): List<WeeklySummary> {
        val weekFields = WeekFields.of(Locale.getDefault())

        // Group workouts by ISO week start (Monday)
        val weekBuckets = mutableMapOf<LocalDate, MutableList<CompletedWorkoutRecord>>()

        for (workout in workouts) {
            val workoutDate = parseDate(workout.date)
            val weekStart = workoutDate.with(weekFields.dayOfWeek(), 1)
            weekBuckets.getOrPut(weekStart) { mutableListOf() }.add(workout)
        }

        // Build summaries for the most recent N weeks
        val sortedWeeks = weekBuckets.keys.sorted()
        val recentWeeks = sortedWeeks.takeLast(weekCount)

        return recentWeeks.map { weekStart ->
            val records = weekBuckets[weekStart] ?: emptyList()
            val allExercises = records.flatMap { it.exerciseNames }
            val muscleGroups = allExercises.mapNotNull { classifyMuscleGroup(it) }.toSet()
            val totalMinutes = records.mapNotNull { it.duration }.sum()

            WeeklySummary(
                weekStartDate = weekStart,
                workoutCount = records.size,
                totalMinutes = totalMinutes,
                muscleGroupsHit = muscleGroups,
                exerciseNames = allExercises
            )
        }
    }

    /**
     * Detects trends from weekly summaries.
     *
     * @param summaries Weekly summaries (oldest-first).
     * @return Detected trends.
     */
    fun detectTrends(summaries: List<WeeklySummary>): List<LoadTrend> {
        if (summaries.size < 2) return emptyList()

        val trends = mutableListOf<LoadTrend>()

        // Frequency analysis
        val counts = summaries.map { it.workoutCount }
        val recentAvg = counts.takeLast(2).sum().toDouble() / 2.0
        val olderCount = maxOf(1, counts.size - 2)
        val olderAvg = counts.dropLast(2).sum().toDouble() / olderCount

        if (recentAvg < olderAvg * 0.6 && olderAvg > 0) {
            trends.add(
                LoadTrend(
                    type = TrendType.FREQUENCY_DROP,
                    message = "Your workout frequency dropped from ~${round(olderAvg).toInt()} to ~${round(recentAvg).toInt()} sessions/week.",
                    severity = TrendSeverity.WARNING
                )
            )
        } else if (recentAvg > olderAvg * 1.3 && olderAvg > 0) {
            trends.add(
                LoadTrend(
                    type = TrendType.FREQUENCY_RISE,
                    message = "Great consistency -- you're training ~${round(recentAvg).toInt()} sessions/week, up from ~${round(olderAvg).toInt()}.",
                    severity = TrendSeverity.POSITIVE
                )
            )
        }

        // Overreaching check (>6 sessions/week sustained for 2+ weeks)
        val highVolumeWeeks = counts.takeLast(2).count { it >= 6 }
        if (highVolumeWeeks >= 2) {
            trends.add(
                LoadTrend(
                    type = TrendType.OVERREACHING,
                    message = "You've trained 6+ times/week for 2 consecutive weeks. Consider a lighter week.",
                    severity = TrendSeverity.WARNING
                )
            )
        }

        // Undertraining check (<2 sessions/week for 2+ weeks)
        val lowVolumeWeeks = counts.takeLast(2).count { it <= 1 }
        if (lowVolumeWeeks >= 2) {
            trends.add(
                LoadTrend(
                    type = TrendType.UNDERTRAINING,
                    message = "Only 0-1 sessions/week recently. Even 2-3 short sessions help maintain progress.",
                    severity = TrendSeverity.WARNING
                )
            )
        }

        // Muscle group balance
        val lastWeek = summaries.lastOrNull()
        if (lastWeek != null) {
            val majorGroups = setOf("Upper Push", "Upper Pull", "Lower", "Core")
            val missing = majorGroups - lastWeek.muscleGroupsHit
            if (missing.isNotEmpty() && lastWeek.workoutCount >= 3) {
                val missingList = missing.sorted().joinToString(", ")
                trends.add(
                    LoadTrend(
                        type = TrendType.MUSCLE_IMBALANCE,
                        message = "Last week missed: $missingList. Try to hit all major groups each week.",
                        severity = TrendSeverity.INFO
                    )
                )
            }
        }

        // Push/pull ratio imbalance
        if (lastWeek != null && lastWeek.workoutCount >= 2) {
            val ratio = pushPullRatio(lastWeek)
            if (ratio.first > 0 && ratio.second > 0) {
                if (ratio.first > ratio.second * 2) {
                    trends.add(
                        LoadTrend(
                            type = TrendType.PUSH_PULL_IMBALANCE,
                            message = "Push/Pull ratio is ${ratio.first}:${ratio.second} this week. Aim for roughly 1:1 to prevent shoulder and posture issues.",
                            severity = TrendSeverity.WARNING
                        )
                    )
                } else if (ratio.second > ratio.first * 2) {
                    trends.add(
                        LoadTrend(
                            type = TrendType.PUSH_PULL_IMBALANCE,
                            message = "Pull/Push ratio is ${ratio.second}:${ratio.first} this week. Add some pressing to maintain balance.",
                            severity = TrendSeverity.WARNING
                        )
                    )
                }
            }
        }

        // Missed session pattern detection
        if (summaries.size >= 4) {
            detectMissedSessionPattern(counts)?.let { trends.add(it) }
        }

        // Consistency
        if (trends.isEmpty() && summaries.size >= 3) {
            val variance = counts.variance()
            if (variance < 1.5) {
                trends.add(
                    LoadTrend(
                        type = TrendType.CONSISTENT,
                        message = "Solid consistency over the last ${summaries.size} weeks. Keep it up.",
                        severity = TrendSeverity.POSITIVE
                    )
                )
            }
        }

        return trends
    }

    // MARK: - Push/Pull Ratio

    /** Computes the count of Upper Push vs Upper Pull exercises in a weekly summary. */
    fun pushPullRatio(summary: WeeklySummary): Pair<Int, Int> {
        var push = 0
        var pull = 0
        for (name in summary.exerciseNames) {
            when (classifyMuscleGroup(name)) {
                "Upper Push" -> push++
                "Upper Pull" -> pull++
            }
        }
        return push to pull
    }

    // MARK: - Missed Session Pattern Detection

    /**
     * Looks for repeating drop-off patterns in workout counts.
     * E.g., [4, 4, 1, 4, 4, 1] -> drop-off every 3rd week.
     */
    private fun detectMissedSessionPattern(counts: List<Int>): LoadTrend? {
        if (counts.size < 4) return null

        val avg = counts.sum().toDouble() / counts.size
        if (avg <= 1) return null

        // Find weeks that are significantly below average (< 40% of avg)
        val dropThreshold = avg * 0.4
        val dropWeeks = counts.mapIndexedNotNull { index, value ->
            if (value.toDouble() < dropThreshold) index else null
        }

        // Need at least 2 drop weeks to detect a pattern
        if (dropWeeks.size < 2) return null

        // Check if drops are evenly spaced
        val gaps = dropWeeks.zipWithNext { a, b -> b - a }
        val firstGap = gaps.firstOrNull() ?: return null
        if (firstGap < 2) return null
        val allSameGap = gaps.all { it == firstGap }

        if (allSameGap) {
            val ordinal = if (firstGap == 2) "3rd" else "${firstGap + 1}th"
            return LoadTrend(
                type = TrendType.MISSED_SESSION_PATTERN,
                message = "You tend to drop off every $ordinal week. Consider scheduling a deliberate lighter week instead of skipping.",
                severity = TrendSeverity.INFO
            )
        }

        return null
    }

    // MARK: - Muscle Group Classification

    /** Maps an exercise name to a broad muscle group category. */
    fun classifyMuscleGroup(exerciseName: String): String? {
        val name = exerciseName.lowercase()

        // Lower body
        val lowerKeywords = listOf(
            "squat", "deadlift", "lunge", "leg", "hip thrust",
            "glute", "hamstring", "calf", "step-up", "box jump"
        )
        if (lowerKeywords.any { name.contains(it) }) {
            return "Lower"
        }

        // Upper push
        val pushKeywords = listOf(
            "bench", "press", "push-up", "pushup", "dip",
            "overhead", "shoulder", "jerk", "thruster"
        )
        if (pushKeywords.any { name.contains(it) }) {
            return "Upper Push"
        }

        // Upper pull
        val pullKeywords = listOf(
            "row", "pull-up", "pullup", "chin-up", "lat",
            "curl", "snatch", "clean", "face pull", "muscle-up"
        )
        if (pullKeywords.any { name.contains(it) }) {
            return "Upper Pull"
        }

        // Core
        val coreKeywords = listOf(
            "sit-up", "situp", "plank", "crunch", "ab",
            "toes-to-bar", "l-sit", "hollow", "v-up"
        )
        if (coreKeywords.any { name.contains(it) }) {
            return "Core"
        }

        return null
    }

    // MARK: - Private Helpers

    /** Parse an ISO8601 date string to LocalDate. Tolerant of multiple ISO formats. */
    private fun parseDate(dateString: String): LocalDate {
        return try {
            LocalDate.parse(dateString.substring(0, 10))
        } catch (_: Exception) {
            try {
                LocalDateTime.parse(dateString).toLocalDate()
            } catch (_: Exception) {
                LocalDate.now()
            }
        }
    }

    /** Compute population variance of a list of integers. */
    private fun List<Int>.variance(): Double {
        if (size <= 1) return 0.0
        val mean = sum().toDouble() / size
        return sumOf { (it.toDouble() - mean).pow(2) } / size
    }
}
