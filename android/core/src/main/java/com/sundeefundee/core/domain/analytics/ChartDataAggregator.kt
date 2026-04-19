package com.sundeefundee.core.domain.analytics

import com.sundeefundee.core.domain.benchmark.BenchmarkResult
import com.sundeefundee.core.model.CyclePhase
import com.sundeefundee.core.model.CyclePhaseInfo
import com.sundeefundee.core.model.OneRepMaxRecord
import com.sundeefundee.core.model.WeightUnit
import com.sundeefundee.core.model.Workout
import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.minus
import kotlinx.datetime.toLocalDateTime
import java.util.UUID

// MARK: - Time Range

/**
 * Time ranges for analytics chart filtering.
 */
enum class TimeRange {
    LAST_MONTH,
    LAST_THREE_MONTHS,
    LAST_SIX_MONTHS,
    LAST_YEAR,
    ALL_TIME;

    /** The start instant for this time range, computed relative to now. */
    val startInstant: Instant
        get() = startInstantRelativeTo(Clock.System.now())

    /** Start instant computed relative to a specific reference instant (useful for testing). */
    fun startInstantRelativeTo(reference: Instant): Instant {
        val tz = TimeZone.currentSystemDefault()
        return when (this) {
            LAST_MONTH -> reference.minus(1, DateTimeUnit.MONTH, tz)
            LAST_THREE_MONTHS -> reference.minus(3, DateTimeUnit.MONTH, tz)
            LAST_SIX_MONTHS -> reference.minus(6, DateTimeUnit.MONTH, tz)
            LAST_YEAR -> reference.minus(1, DateTimeUnit.YEAR, tz)
            ALL_TIME -> Instant.DISTANT_PAST
        }
    }
}

// MARK: - Data Points

/**
 * A single data point for strength progression charts.
 */
data class StrengthDataPoint(
    val id: String = UUID.randomUUID().toString(),
    val date: Instant,
    val exerciseName: String,
    val weight: Double,
    val unit: WeightUnit
)

/**
 * A single data point for training volume charts, aggregated by week.
 */
data class VolumeDataPoint(
    val id: String = UUID.randomUUID().toString(),
    val weekStartDate: LocalDate,
    val totalVolume: Double,
    val workoutCount: Int
)

/**
 * A single data point for workout frequency charts, aggregated by week.
 */
data class FrequencyDataPoint(
    val id: String = UUID.randomUUID().toString(),
    val weekStartDate: LocalDate,
    val workoutCount: Int,
    val label: String
)

/**
 * A single data point for cycle-correlated performance charts.
 */
data class CyclePerformancePoint(
    val phase: CyclePhase,
    val averageVolume: Double,
    val workoutCount: Int,
    val confidence: Double
) {
    val id: String get() = phase.name
}

// MARK: - Aggregator

/**
 * Pure domain service that transforms raw records into chart-ready data points.
 *
 * All functions are top-level and side-effect free. The ViewModel layer calls these
 * with data fetched from the persistence store.
 */
object ChartDataAggregator {

    // MARK: - Strength Progression

    /**
     * Groups one-rep-max records by exercise, filters by time range, and sorts by date.
     *
     * @param records Raw one-rep-max records from the persistence store.
     * @param timeRange The time window to filter by.
     * @param referenceDate Optional reference instant for time range computation (defaults to now).
     * @return Sorted list of strength data points within the time range.
     */
    fun strengthProgression(
        records: List<OneRepMaxRecord>,
        timeRange: TimeRange,
        referenceDate: Instant = Clock.System.now()
    ): List<StrengthDataPoint> {
        val cutoff = timeRange.startInstantRelativeTo(referenceDate)

        return records
            .filter {
                val instant = Instant.parse(it.date)
                instant >= cutoff
            }
            .map {
                StrengthDataPoint(
                    date = Instant.parse(it.date),
                    exerciseName = it.exerciseName,
                    weight = it.weight,
                    unit = it.unit
                )
            }
            .sortedBy { it.date }
    }

    // MARK: - Training Volume

    /**
     * Aggregates completed workout volumes by ISO week.
     *
     * Only workouts with a non-null [Workout.completedAt] are included.
     *
     * @param workouts Raw workouts from the persistence store.
     * @param timeRange The time window to filter by.
     * @param referenceDate Optional reference instant for time range computation (defaults to now).
     * @return Sorted list of weekly volume data points.
     */
    fun trainingVolume(
        workouts: List<Workout>,
        timeRange: TimeRange,
        referenceDate: Instant = Clock.System.now()
    ): List<VolumeDataPoint> {
        val cutoff = timeRange.startInstantRelativeTo(referenceDate)
        val tz = TimeZone.currentSystemDefault()

        val completed = workouts.filter { workout ->
            val completedAt = workout.completedAt ?: return@filter false
            Instant.parse(completedAt) >= cutoff
        }

        // Group by ISO week start date
        val weekMap = mutableMapOf<LocalDate, Pair<Double, Int>>()

        for (workout in completed) {
            val completedInstant = Instant.parse(workout.completedAt!!)
            val weekStart = isoWeekStart(completedInstant, tz)

            val existing = weekMap[weekStart]
            if (existing != null) {
                weekMap[weekStart] = (existing.first + workout.totalVolume) to (existing.second + 1)
            } else {
                weekMap[weekStart] = workout.totalVolume to 1
            }
        }

        return weekMap.map { (weekStart, data) ->
            VolumeDataPoint(
                weekStartDate = weekStart,
                totalVolume = data.first,
                workoutCount = data.second
            )
        }.sortedBy { it.weekStartDate }
    }

    // MARK: - Workout Frequency

    /**
     * Counts completed workouts per ISO week.
     *
     * Only workouts with a non-null [Workout.completedAt] are included.
     *
     * @param workouts Raw workouts from the persistence store.
     * @param timeRange The time window to filter by.
     * @param referenceDate Optional reference instant for time range computation (defaults to now).
     * @return Sorted list of weekly frequency data points with human-readable labels.
     */
    fun workoutFrequency(
        workouts: List<Workout>,
        timeRange: TimeRange,
        referenceDate: Instant = Clock.System.now()
    ): List<FrequencyDataPoint> {
        val cutoff = timeRange.startInstantRelativeTo(referenceDate)
        val tz = TimeZone.currentSystemDefault()

        val completed = workouts.filter { workout ->
            val completedAt = workout.completedAt ?: return@filter false
            Instant.parse(completedAt) >= cutoff
        }

        val weekMap = mutableMapOf<LocalDate, Int>()

        for (workout in completed) {
            val completedInstant = Instant.parse(workout.completedAt!!)
            val weekStart = isoWeekStart(completedInstant, tz)
            weekMap[weekStart] = (weekMap[weekStart] ?: 0) + 1
        }

        return weekMap.map { (weekStart, count) ->
            val label = formatWeekLabel(weekStart)
            FrequencyDataPoint(
                weekStartDate = weekStart,
                workoutCount = count,
                label = label
            )
        }.sortedBy { it.weekStartDate }
    }

    // MARK: - Cycle Correlation

    /**
     * Maps workouts to their cycle phases via date overlap and averages volume per phase.
     *
     * Each workout is matched to the first [CyclePhaseInfo] whose date range contains
     * the workout's [Workout.completedAt] date. The resulting points include the average
     * confidence of matched phases.
     *
     * @param workouts Raw workouts from the persistence store.
     * @param phases Cycle phase info records with date ranges.
     * @param timeRange The time window to filter by.
     * @param referenceDate Optional reference instant for time range computation (defaults to now).
     * @return List of performance points, one per represented phase.
     */
    fun cycleCorrelation(
        workouts: List<Workout>,
        phases: List<CyclePhaseInfo>,
        timeRange: TimeRange,
        referenceDate: Instant = Clock.System.now()
    ): List<CyclePerformancePoint> {
        val cutoff = timeRange.startInstantRelativeTo(referenceDate)
        val tz = TimeZone.currentSystemDefault()

        val completed = workouts.filter { workout ->
            val completedAt = workout.completedAt ?: return@filter false
            Instant.parse(completedAt) >= cutoff
        }

        // Map workouts to phases
        val phaseData = mutableMapOf<CyclePhase, Pair<MutableList<Double>, MutableList<Double>>>()

        for (workout in completed) {
            val workoutInstant = Instant.parse(workout.completedAt!!)
            val workoutLocalDate = workoutInstant.toLocalDateTime(tz).date

            // Find the first phase whose date range contains this workout
            val matchingPhase = phases.firstOrNull { phase ->
                val phaseStart = LocalDate.parse(phase.startDate)
                val phaseEnd = LocalDate.parse(phase.endDate)
                workoutLocalDate >= phaseStart && workoutLocalDate <= phaseEnd
            } ?: continue

            val existing = phaseData[matchingPhase.phase]
            if (existing != null) {
                existing.first.add(workout.totalVolume)
                existing.second.add(matchingPhase.confidence)
            } else {
                phaseData[matchingPhase.phase] = Pair(
                    mutableListOf(workout.totalVolume),
                    mutableListOf(matchingPhase.confidence)
                )
            }
        }

        return phaseData.map { (phase, data) ->
            val avgVolume = data.first.sum() / data.first.size
            val avgConfidence = data.second.sum() / data.second.size
            CyclePerformancePoint(
                phase = phase,
                averageVolume = avgVolume,
                workoutCount = data.first.size,
                confidence = avgConfidence
            )
        }.sortedBy { it.phase.name }
    }

    // MARK: - Exercise Picker

    /**
     * Returns unique exercise names from one-rep-max records, sorted alphabetically.
     *
     * Useful for populating the exercise picker in the strength progression chart.
     *
     * @param records Raw one-rep-max records.
     * @return Sorted list of unique exercise names.
     */
    fun exercises(records: List<OneRepMaxRecord>): List<String> {
        return records.map { it.exerciseName }.toSortedSet().toList()
    }

    // MARK: - Private Helpers

    /** Get the ISO week start date (Monday) for an instant. */
    private fun isoWeekStart(instant: Instant, tz: TimeZone): LocalDate {
        val localDate = instant.toLocalDateTime(tz).date
        val dow = localDate.dayOfWeek
        // Iso8601: Monday = 1, Sunday = 7
        val daysSinceMonday = dow.ordinal // Monday=0 ... Sunday=6
        return localDate.minus(daysSinceMonday, DateTimeUnit.DAY)
    }

    /** Format a week start date as "MMM d" for chart labels. */
    private fun formatWeekLabel(weekStart: LocalDate): String {
        val months = listOf("Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
        val monthName = months[weekStart.monthNumber - 1]
        return "Week of $monthName ${weekStart.dayOfMonth}"
    }
}
