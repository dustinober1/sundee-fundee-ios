package com.sundeefundee.core.domain.intelligence

import com.sundeefundee.core.domain.exercise.WeightliftingCategory
import com.sundeefundee.core.domain.exercise.WeightliftingCatalog
import com.sundeefundee.core.model.OneRepMaxRecord
import com.sundeefundee.core.model.WeightUnit
import com.sundeefundee.core.model.Workout
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import kotlin.math.max
import kotlin.math.round

/**
 * Detects stalled lifts from 1RM history and generates actionable alerts.
 *
 * A plateau is defined as a lift whose 1RM has not increased over a
 * configurable window of attempts. The detector groups records by exercise,
 * sorts chronologically, and checks whether recent attempts show progress.
 *
 * Pure domain logic -- no framework dependencies.
 */
object PlateauDetector {

    // MARK: - Configuration

    /** Minimum number of records required before a plateau can be detected. */
    const val MINIMUM_ATTEMPTS = 3

    /** Number of most-recent records to evaluate for progress. */
    const val RECENT_WINDOW = 3

    /** Maximum allowed days between first and last attempt in the window
     * for a plateau to be flagged. Prevents stale data from triggering alerts. */
    const val MAX_WINDOW_DAYS = 90

    /** Default percentage improvement required to count as progress.
     * 0.01 = 1% improvement over the window. */
    const val PROGRESS_THRESHOLD = 0.01

    /** Minimum records needed for rate-of-progress analysis. */
    const val MINIMUM_PROGRESS_RECORDS = 5

    // MARK: - Types

    /** Whether the plateau is a strength (1RM) or volume stall. */
    enum class PlateauType {
        STRENGTH,
        VOLUME
    }

    /** A detected plateau for a specific lift. */
    data class PlateauAlert(
        /** The exercise name that has stalled. */
        val exerciseName: String,
        /** The current 1RM weight (most recent). */
        val currentWeight: Double,
        /** The weight unit. */
        val unit: WeightUnit,
        /** The best weight achieved in the evaluation window. */
        val bestWeight: Double,
        /** Number of consecutive attempts without meaningful progress. */
        val stallCount: Int,
        /** Days since the best weight was achieved. */
        val daysSinceBest: Int,
        /** Actionable recommendation. */
        val recommendation: String,
        /** Whether this is a strength or volume plateau. */
        val plateauType: PlateauType = PlateauType.STRENGTH
    )

    /** An early warning that progress is slowing before a full plateau. */
    data class RateOfProgressAlert(
        val exerciseName: String,
        /** Weight gained per week in the recent period. */
        val currentRate: Double,
        /** Weight gained per week in the earlier period. */
        val historicalRate: Double,
        val message: String
    )

    // MARK: - Exercise-Specific Thresholds

    /** Returns an exercise-category-aware progress threshold.
     * Compound lifts move larger absolute weights and progress more slowly,
     * so they use a tighter threshold. Isolation/press exercises use a wider one. */
    fun progressThresholdForCategory(category: WeightliftingCategory): Double {
        return when (category) {
            WeightliftingCategory.SQUAT,
            WeightliftingCategory.HIP_HINGE,
            WeightliftingCategory.OLYMPIC_WEIGHTLIFTING -> 0.005 // 0.5%

            WeightliftingCategory.PRESS,
            WeightliftingCategory.PULL -> 0.015 // 1.5%

            WeightliftingCategory.CARRY -> 0.01 // 1.0%
        }
    }

    /** Resolves the category for an exercise name from the catalog, falling back to null. */
    private fun resolveCategory(exerciseName: String): WeightliftingCategory? {
        return WeightliftingCatalog.all.firstOrNull { it.id == exerciseName }?.category
    }

    // MARK: - Strength Plateau Detection

    /**
     * Analyzes 1RM records and returns alerts for stalled lifts.
     *
     * @param records All 1RM records for the user, across all exercises.
     * @return An array of [PlateauAlert] for exercises that appear stalled.
     */
    fun detect(records: List<OneRepMaxRecord>): List<PlateauAlert> {
        val grouped = records.groupBy { it.exerciseName }

        val alerts = mutableListOf<PlateauAlert>()

        for ((exerciseName, exerciseRecords) in grouped) {
            if (exerciseRecords.size < MINIMUM_ATTEMPTS) continue

            val sorted = exerciseRecords.sortedBy { parseDate(it.date) }
            val recent = sorted.takeLast(RECENT_WINDOW)
            if (recent.size < MINIMUM_ATTEMPTS) continue

            val first = recent.first()
            val last = recent.last()

            val daySpan = ChronoUnit.DAYS.between(
                parseDate(first.date), parseDate(last.date)
            )
            if (daySpan > MAX_WINDOW_DAYS) continue

            val bestWeight = recent.maxOf { it.weight }
            val currentWeight = last.weight

            val oldestInWindow = first.weight
            val improvement = if (oldestInWindow > 0) {
                (bestWeight - oldestInWindow) / oldestInWindow
            } else {
                0.0
            }

            // Use category-specific threshold when catalog is available
            val threshold: Double = resolveCategory(exerciseName)?.let {
                progressThresholdForCategory(it)
            } ?: PROGRESS_THRESHOLD

            if (improvement < threshold) {
                val peak = sorted.maxOf { it.weight }
                var stallCount = 0
                var seenPeak = false

                for (record in sorted.reversed()) {
                    if (record.weight >= peak && !seenPeak) {
                        seenPeak = true
                        stallCount++
                    } else if (seenPeak && record.weight >= peak) {
                        stallCount++
                    } else if (seenPeak) {
                        break
                    } else {
                        stallCount++
                    }
                }
                stallCount = max(stallCount, recent.size)

                val bestRecord = sorted.lastOrNull { it.weight == peak }
                val bestDate = bestRecord?.let { parseDate(it.date) } ?: parseDate(last.date)
                val daysSinceBest = ChronoUnit.DAYS.between(bestDate, LocalDate.now()).toInt()

                val recommendation = generateRecommendation(
                    exerciseName = exerciseName,
                    stallCount = stallCount,
                    currentWeight = currentWeight,
                    bestWeight = peak,
                    plateauType = PlateauType.STRENGTH
                )

                alerts.add(
                    PlateauAlert(
                        exerciseName = exerciseName,
                        currentWeight = currentWeight,
                        unit = last.unit,
                        bestWeight = peak,
                        stallCount = stallCount,
                        daysSinceBest = daysSinceBest,
                        recommendation = recommendation,
                        plateauType = PlateauType.STRENGTH
                    )
                )
            }
        }

        return alerts.sortedByDescending { it.stallCount }
    }

    // MARK: - Volume Plateau Detection

    /**
     * Detects exercises whose training volume has stalled over recent weeks.
     *
     * Groups workouts by week, computes per-exercise weekly volume (reps x weight),
     * and flags exercises with less than 2% volume growth across the window.
     *
     * @param workouts All completed workouts.
     * @param windowWeeks Number of weeks to evaluate (default 4).
     * @return Alerts for exercises with stalled volume.
     */
    fun detectVolumePlateaus(
        workouts: List<Workout>,
        windowWeeks: Int = 4
    ): List<PlateauAlert> {
        val cutoffDate = LocalDate.now().minusWeeks(windowWeeks.toLong())
        val recentWorkouts = workouts.filter {
            parseDate(it.date) >= cutoffDate && it.isComplete
        }

        if (recentWorkouts.size < 2) return emptyList()

        // Group workouts by year*100 + week number
        val weeklyVolume = mutableMapOf<Int, MutableMap<String, Double>>()

        for (workout in recentWorkouts) {
            val workoutDate = parseDate(workout.date)
            val yearWeek = workoutDate.year * 100 + workoutDate.get(
                java.time.temporal.WeekFields.ISO.weekOfWeekBasedYear()
            )

            for (exercise in workout.exercises) {
                val volume = exercise.targetSets.sumOf { set ->
                    val reps = (set.actualReps ?: set.reps).toDouble()
                    val weight = if ((set.completedWeight ?: 0.0) > 0) {
                        set.completedWeight!!
                    } else if (set.prescribedWeight > 0) {
                        set.prescribedWeight
                    } else {
                        0.0
                    }
                    reps * weight
                }

                weeklyVolume
                    .getOrPut(yearWeek) { mutableMapOf() }
                    .merge(exercise.name, volume) { old, new -> old + new }
            }
        }

        if (weeklyVolume.size < 2) return emptyList()

        val sortedWeeks = weeklyVolume.keys.sorted()

        // Collect all exercises that appear in at least 2 weeks
        val allExercises = mutableSetOf<String>()
        for ((_, exercises) in weeklyVolume) {
            allExercises.addAll(exercises.keys)
        }

        val alerts = mutableListOf<PlateauAlert>()
        val volumeGrowthThreshold = 0.02 // 2%

        for (exerciseName in allExercises) {
            val volumes = sortedWeeks.mapNotNull { weeklyVolume[it]?.get(exerciseName) }
            if (volumes.size < 2) continue

            val firstVolume = volumes.first()
            val lastVolume = volumes.last()
            if (firstVolume <= 0) continue

            val growth = (lastVolume - firstVolume) / firstVolume
            if (growth < volumeGrowthThreshold) {
                val bestVolume = volumes.max()
                val recommendation = generateRecommendation(
                    exerciseName = exerciseName,
                    stallCount = volumes.size,
                    currentWeight = lastVolume,
                    bestWeight = bestVolume,
                    plateauType = PlateauType.VOLUME
                )
                alerts.add(
                    PlateauAlert(
                        exerciseName = exerciseName,
                        currentWeight = lastVolume,
                        unit = WeightUnit.LBS,
                        bestWeight = bestVolume,
                        stallCount = volumes.size,
                        daysSinceBest = 0,
                        recommendation = recommendation,
                        plateauType = PlateauType.VOLUME
                    )
                )
            }
        }

        return alerts.sortedByDescending { it.stallCount }
    }

    // MARK: - Rate of Progress Detection

    /**
     * Detects exercises where the rate of strength progress is slowing,
     * providing an early warning before a full plateau manifests.
     *
     * Splits 1RM history into two halves and compares the rate of weight
     * gain per week. If the recent rate drops below 50% of the earlier rate,
     * an alert is generated.
     *
     * @param records All 1RM records for the user.
     * @param minimumRecords Minimum records per exercise (default 5).
     * @return Early warning alerts for slowing progress.
     */
    fun detectSlowingProgress(
        records: List<OneRepMaxRecord>,
        minimumRecords: Int = 5
    ): List<RateOfProgressAlert> {
        val grouped = records.groupBy { it.exerciseName }
        val alerts = mutableListOf<RateOfProgressAlert>()

        for ((exerciseName, exerciseRecords) in grouped) {
            if (exerciseRecords.size < minimumRecords) continue

            val sorted = exerciseRecords.sortedBy { parseDate(it.date) }

            // Split into first half and second half
            val midpoint = sorted.size / 2
            val firstHalf = sorted.take(midpoint)
            val secondHalf = sorted.drop(midpoint)

            if (firstHalf.size < 2 || secondHalf.size < 2) continue

            val historicalRate = ratePerWeek(firstHalf)
            val currentRate = ratePerWeek(secondHalf)

            // Only flag if historical rate was positive (they were progressing)
            // and current rate has dropped below 50% of historical
            if (historicalRate > 0 && currentRate < historicalRate * 0.5) {
                val message = if (currentRate <= 0) {
                    "Your progress on $exerciseName has stalled -- consider a variation or deload before a full plateau."
                } else {
                    "Your progress on $exerciseName is slowing -- consider a variation or deload before a full plateau."
                }
                alerts.add(
                    RateOfProgressAlert(
                        exerciseName = exerciseName,
                        currentRate = currentRate,
                        historicalRate = historicalRate,
                        message = message
                    )
                )
            }
        }

        return alerts
    }

    // MARK: - Private Helpers

    /** Computes weight gained per week across a sorted slice of records. */
    private fun ratePerWeek(records: List<OneRepMaxRecord>): Double {
        val first = records.firstOrNull() ?: return 0.0
        val last = records.lastOrNull() ?: return 0.0

        val days = ChronoUnit.DAYS.between(parseDate(first.date), parseDate(last.date)).toDouble()
        val weeks = days / 7.0
        if (weeks <= 0) return 0.0

        return (last.weight - first.weight) / weeks
    }

    private fun generateRecommendation(
        exerciseName: String,
        stallCount: Int,
        currentWeight: Double,
        bestWeight: Double,
        plateauType: PlateauType
    ): String {
        return when (plateauType) {
            PlateauType.STRENGTH -> {
                when {
                    stallCount >= 6 -> "Consider changing your rep scheme or adding a variation of $exerciseName for 3-4 weeks, then re-test."
                    stallCount >= 4 -> "Try a deload week at 60% of your $exerciseName max, then build back with smaller jumps."
                    else -> "Add volume: try 3-5 extra sets of $exerciseName per week at 70-80% to break through."
                }
            }
            PlateauType.VOLUME -> {
                "Your $exerciseName volume has plateaued. Try adding 1-2 sets per session or increase weight by 5%."
            }
        }
    }

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
}
