package com.sundeefundee.core.domain.recovery

import com.sundeefundee.core.domain.intelligence.WeeklyLoadAnalyzer
import com.sundeefundee.core.domain.intelligence.WeeklyLoadAnalyzer.WeeklySummary
import com.sundeefundee.core.model.CyclePhase
import java.time.Instant
import java.time.temporal.ChronoUnit
import kotlin.math.max
import kotlin.math.min
import kotlin.math.round
import kotlin.math.roundToInt

// MARK: - Recovery Score

/**
 * The result of recovery score calculation.
 *
 * Contains the total score (0-100), per-input sub-scores, a training
 * recommendation, and human-readable explanations for each sub-score.
 */
data class RecoveryScore(
    /** Total recovery score, clamped to 0-100. */
    val total: Int,
    /** Training recommendation derived from total score. */
    val recommendation: TrainingRecommendation,
    /** Per-input sub-scores (0-100 each). */
    val subScores: Map<RecoveryInput, Int>,
    /** Number of inputs that were present (non-null). */
    val presentInputCount: Int,
    /** Total number of possible inputs (always 5). */
    val totalInputCount: Int,
    /** Per-input human-readable explanations. */
    val explanations: Map<RecoveryInput, String>
)

// MARK: - Training Recommendation

/** Training recommendation derived from recovery score total. */
enum class TrainingRecommendation {
    /** Total >= 70 -- good to train. */
    PUSH_DAY,
    /** Total 40-69 -- moderate readiness. */
    MODERATE,
    /** Total < 40 -- prioritize rest. */
    REST_DAY
}

// MARK: - Recovery Input

/** Identifies each recovery input dimension. */
enum class RecoveryInput {
    HRV,
    SLEEP,
    TRAINING_LOAD,
    CYCLE_PHASE,
    PAIN
}

// MARK: - Recovery Score Inputs

/**
 * Input data for recovery score calculation.
 *
 * All fields are nullable -- the calculator gracefully degrades when
 * inputs are missing by redistributing weights among present inputs.
 * When all inputs are null, the calculator returns null (no score).
 */
data class RecoveryScoreInputs(
    /** Most recent nightly SDNN from HealthKit (milliseconds). */
    val hrvMilliseconds: Double? = null,
    /** Deduplicated total sleep duration (hours). */
    val sleepDurationHours: Double? = null,
    /** Last 4 weeks of training summaries from WeeklyLoadAnalyzer. */
    val weeklySummaries: List<WeeklySummary>? = null,
    /** Current cycle phase. */
    val cyclePhase: CyclePhase? = null,
    /** Pain intensity 1-10 scale. */
    val painIntensity: Int? = null
)

// MARK: - Recovery Score Calculator

/**
 * Pure domain calculator for recovery scores.
 *
 * Takes all available biometric and training inputs, scores each dimension
 * 0-100, and produces a weighted total with graceful degradation when
 * inputs are missing. Returns null when no inputs are present.
 *
 * Weight distribution when all inputs present:
 * - HRV: 30%
 * - Sleep: 25%
 * - Training Load: 25%
 * - Cycle Phase: 15%
 * - Pain: 5%
 *
 * When inputs are missing, weights are redistributed proportionally
 * among present inputs.
 */
object RecoveryScoreCalculator {

    // MARK: - Input Weights

    private const val HRV_WEIGHT: Double = 0.30
    private const val SLEEP_WEIGHT: Double = 0.25
    private const val TRAINING_LOAD_WEIGHT: Double = 0.25
    private const val CYCLE_PHASE_WEIGHT: Double = 0.15
    private const val PAIN_WEIGHT: Double = 0.05

    // MARK: - Calculate

    /**
     * Calculate recovery score from available inputs.
     *
     * @param inputs Recovery data (all fields optional).
     * @return Score with sub-scores and recommendation, or null if all inputs are null.
     */
    fun calculate(inputs: RecoveryScoreInputs): RecoveryScore? {
        var weightedSum: Double = 0.0
        var totalWeight: Double = 0.0
        val subScores = mutableMapOf<RecoveryInput, Int>()
        val explanations = mutableMapOf<RecoveryInput, String>()

        // HRV
        inputs.hrvMilliseconds?.let { hrv ->
            val normalized = HRVBaselineNormalizer.normalize(hrvMs = hrv, phase = inputs.cyclePhase)
            val hrvScore = HRVBaselineNormalizer.score(normalizedHrvMs = normalized)
            subScores[RecoveryInput.HRV] = hrvScore
            weightedSum += hrvScore.toDouble() * HRV_WEIGHT
            totalWeight += HRV_WEIGHT
            val phaseNote = if (inputs.cyclePhase != null) " (phase-normalized)" else ""
            explanations[RecoveryInput.HRV] = "HRV ${hrv.toInt()}ms -> $hrvScore/100$phaseNote"
        }

        // Sleep
        inputs.sleepDurationHours?.let { sleep ->
            val sleepScore = scoreSleep(sleep)
            subScores[RecoveryInput.SLEEP] = sleepScore
            weightedSum += sleepScore.toDouble() * SLEEP_WEIGHT
            totalWeight += SLEEP_WEIGHT
            val formatted = "%.1f".format(sleep)
            explanations[RecoveryInput.SLEEP] = if (sleep >= 7.0) {
                "${formatted}h -- within 7h target"
            } else {
                "${formatted}h -- below 7h target"
            }
        }

        // Training Load
        inputs.weeklySummaries?.let { summaries ->
            val loadResult = TrainingLoadScorer.score(summaries = summaries)
            subScores[RecoveryInput.TRAINING_LOAD] = loadResult.score
            weightedSum += loadResult.score.toDouble() * TRAINING_LOAD_WEIGHT
            totalWeight += TRAINING_LOAD_WEIGHT
            explanations[RecoveryInput.TRAINING_LOAD] = loadResult.explanation
        }

        // Cycle Phase
        inputs.cyclePhase?.let { phase ->
            val phaseResult = CyclePhaseScorer.score(phase = phase)
            subScores[RecoveryInput.CYCLE_PHASE] = phaseResult.score
            weightedSum += phaseResult.score.toDouble() * CYCLE_PHASE_WEIGHT
            totalWeight += CYCLE_PHASE_WEIGHT
            explanations[RecoveryInput.CYCLE_PHASE] = phaseResult.explanation
        }

        // Pain
        inputs.painIntensity?.let { pain ->
            val painResult = PainScorer.score(intensity = pain)
            subScores[RecoveryInput.PAIN] = painResult.score
            weightedSum += painResult.score.toDouble() * PAIN_WEIGHT
            totalWeight += PAIN_WEIGHT
            explanations[RecoveryInput.PAIN] = painResult.explanation
        }

        if (totalWeight <= 0) return null

        val total = (weightedSum / totalWeight).roundToInt()
        val clamped = min(100, max(0, total))
        val recommendation: TrainingRecommendation = when {
            clamped >= 70 -> TrainingRecommendation.PUSH_DAY
            clamped >= 40 -> TrainingRecommendation.MODERATE
            else -> TrainingRecommendation.REST_DAY
        }

        return RecoveryScore(
            total = clamped,
            recommendation = recommendation,
            subScores = subScores,
            presentInputCount = subScores.size,
            totalInputCount = 5,
            explanations = explanations
        )
    }

    // MARK: - Sleep Scoring

    /**
     * Scores sleep duration on a 0-100 scale.
     *
     * @param hours Total sleep duration in hours.
     * @return Score from 0-100.
     */
    private fun scoreSleep(hours: Double): Int {
        return when {
            hours >= 8.0 -> 100
            hours >= 7.0 -> 85
            hours >= 6.0 -> 60
            hours >= 5.0 -> 35
            else -> 10
        }
    }
}

// MARK: - HRV Baseline Normalizer

/**
 * Normalizes HRV readings against per-cycle-phase baselines.
 *
 * Progesterone suppresses HRV 10-20% during the luteal phase.
 * Without phase-relative normalization, luteal-phase readings would
 * consistently produce artificially low recovery scores.
 * The normalizer divides raw HRV by a phase-specific multiplier,
 * producing a phase-adjusted value that can be scored uniformly.
 */
object HRVBaselineNormalizer {

    /**
     * Returns the HRV normalization multiplier for a given cycle phase.
     *
     * @param phase Current cycle phase (null when no cycle data available).
     * @return Multiplier applied to raw HRV for normalization.
     */
    fun phaseMultiplier(phase: CyclePhase?): Double {
        return when (phase) {
            CyclePhase.FOLLICULAR -> 1.0
            CyclePhase.OVULATION -> 1.05
            CyclePhase.LUTEAL -> 0.85
            CyclePhase.MENSTRUAL -> 0.90
            null -> 1.0
        }
    }

    /**
     * Normalizes an HRV reading against the phase baseline.
     *
     * @param hrvMs Raw HRV in milliseconds.
     * @param phase Current cycle phase (null if unavailable).
     * @return Phase-normalized HRV value.
     */
    fun normalize(hrvMs: Double, phase: CyclePhase?): Double {
        val multiplier = phaseMultiplier(phase)
        return hrvMs / multiplier
    }

    /**
     * Scores a normalized HRV value on a 0-100 scale.
     *
     * Uses continuous linear interpolation within bands so that
     * phase-normalization differences produce different scores
     * even within the same band.
     *
     * @param normalizedHrvMs Phase-normalized HRV in milliseconds.
     * @return Score from 0-100.
     */
    fun score(normalizedHrvMs: Double): Int {
        return when {
            normalizedHrvMs >= 80 -> 100
            normalizedHrvMs >= 60 -> {
                // 60ms -> 60, 80ms -> 100 (linear)
                val fraction = (normalizedHrvMs - 60.0) / 20.0
                (60.0 + fraction * 40.0).roundToInt()
            }
            normalizedHrvMs >= 40 -> {
                // 40ms -> 30, 60ms -> 60 (linear)
                val fraction = (normalizedHrvMs - 40.0) / 20.0
                (30.0 + fraction * 30.0).roundToInt()
            }
            normalizedHrvMs >= 20 -> {
                // 20ms -> 10, 40ms -> 30 (linear)
                val fraction = (normalizedHrvMs - 20.0) / 20.0
                (10.0 + fraction * 20.0).roundToInt()
            }
            else -> 0
        }
    }
}

// MARK: - Sleep Deduplicator

/**
 * Pure domain function that deduplicates overlapping sleep intervals from multiple sources.
 *
 * HealthKit receives sleep data from both Apple Watch and iPhone, often with overlapping
 * time ranges. This algorithm merges overlapping intervals, prioritizing Watch data,
 * and returns the total deduplicated sleep duration.
 *
 * ## Algorithm
 * 1. Filter to sleep stages only (exclude IN_BED and AWAKE)
 * 2. Sort by start date ascending
 * 3. Merge overlapping intervals within Watch and non-Watch sets separately
 * 4. Remove non-Watch intervals that overlap with any merged Watch interval
 * 5. Sum all remaining merged interval durations
 */
object SleepDeduplicator {

    // MARK: - Types

    /** Represents a single sleep interval with source and stage metadata. */
    data class SleepInterval(
        val start: Instant,
        val end: Instant,
        val source: SleepSource,
        val stage: SleepStage
    )

    /** The device or app that recorded the sleep sample. */
    enum class SleepSource {
        WATCH,
        PHONE,
        OTHER
    }

    /** HealthKit sleep category values mapping to sleep stages. */
    enum class SleepStage(val value: Int) {
        IN_BED(0),
        ASLEEP_LEGACY(1),
        AWAKE(2),
        ASLEEP_CORE(3),
        ASLEEP_DEEP(4),
        ASLEEP_REM(5);

        /** Whether this stage counts as actual sleep for duration calculation. */
        val countsAsSleep: Boolean
            get() = when (this) {
                ASLEEP_LEGACY, ASLEEP_CORE, ASLEEP_DEEP, ASLEEP_REM -> true
                IN_BED, AWAKE -> false
            }

        companion object {
            fun fromValue(value: Int): SleepStage? =
                entries.firstOrNull { it.value == value }
        }
    }

    // MARK: - Deduplication

    /**
     * Returns deduplicated total sleep duration in seconds.
     *
     * Algorithm:
     * 1. Filter to sleep stages only (exclude IN_BED and AWAKE)
     * 2. Sort by start date ascending
     * 3. Separate into Watch and non-Watch sets
     * 4. Merge overlapping intervals within each set (sorted sweep line, O(n log n))
     * 5. Remove non-Watch intervals that overlap with any merged Watch interval
     * 6. Sum all remaining merged interval durations
     *
     * @param intervals Array of sleep intervals from potentially multiple sources.
     * @return Total sleep duration in seconds after deduplication.
     */
    fun deduplicate(intervals: List<SleepInterval>): Long {
        // Step 1: Filter to sleep stages only
        val sleepIntervals = intervals.filter { it.stage.countsAsSleep }
        if (sleepIntervals.isEmpty()) return 0L

        // Step 2: Sort by start date ascending
        val sorted = sleepIntervals.sortedBy { it.start }

        // Step 3: Separate into Watch and non-Watch sets
        val watchIntervals = sorted.filter { it.source == SleepSource.WATCH }
        val otherIntervals = sorted.filter { it.source != SleepSource.WATCH }

        // Step 4: Merge overlapping intervals within each set
        val mergedWatch = mergeOverlapping(watchIntervals)
        val mergedOther = mergeOverlapping(otherIntervals)

        // Step 5: Subtract Watch intervals from non-Watch intervals
        // Rather than removing overlapping non-Watch intervals entirely, trim them
        // so that only the portions outside the Watch range remain.
        val trimmedOther = mutableListOf<SleepInterval>()
        for (other in mergedOther) {
            var remaining = listOf(other)
            for (watch in mergedWatch) {
                val newRemaining = mutableListOf<SleepInterval>()
                for (interval in remaining) {
                    newRemaining.addAll(subtractInterval(interval, watch))
                }
                remaining = newRemaining
            }
            trimmedOther.addAll(remaining)
        }

        // Step 6: Sum all remaining intervals
        val allMerged = mergedWatch + trimmedOther
        return allMerged.sumOf { ChronoUnit.SECONDS.between(it.start, it.end) }
    }

    // MARK: - Private Helpers

    /**
     * Merges overlapping intervals using sorted sweep line algorithm.
     *
     * Intervals are assumed to be sorted by start date ascending.
     * If the current interval's start is <= the previous merged interval's end,
     * the previous is extended to max(prev.end, current.end).
     */
    private fun mergeOverlapping(intervals: List<SleepInterval>): List<SleepInterval> {
        if (intervals.isEmpty()) return emptyList()

        val merged = mutableListOf(intervals[0])

        for (interval in intervals.drop(1)) {
            val last = merged.last()
            if (!interval.start.isAfter(last.end)) {
                // Overlapping -- extend the end to the later of the two
                val newEnd = if (last.end.isAfter(interval.end)) last.end else interval.end
                merged[merged.lastIndex] = SleepInterval(
                    start = last.start,
                    end = newEnd,
                    source = last.source,
                    stage = last.stage
                )
            } else {
                merged.add(interval)
            }
        }

        return merged
    }

    /**
     * Subtracts one interval from another, returning the remaining portions.
     *
     * If [subtract] overlaps with [source], the overlapping portion is removed.
     * This may result in zero, one, or two remaining intervals (if the subtract
     * is in the middle, both the left and right portions remain).
     */
    private fun subtractInterval(
        source: SleepInterval,
        subtract: SleepInterval
    ): List<SleepInterval> {
        // No overlap -- source remains intact
        if (source.start >= subtract.end || source.end <= subtract.start) {
            return listOf(source)
        }

        val result = mutableListOf<SleepInterval>()

        // Left portion (before subtract.start)
        if (source.start < subtract.start) {
            result.add(SleepInterval(
                start = source.start,
                end = subtract.start,
                source = source.source,
                stage = source.stage
            ))
        }

        // Right portion (after subtract.end)
        if (source.end > subtract.end) {
            result.add(SleepInterval(
                start = subtract.end,
                end = source.end,
                source = source.source,
                stage = source.stage
            ))
        }

        return result
    }

    // MARK: - Sample Conversion

    /**
     * Converts raw HealthKit category sample data into SleepInterval domain types.
     *
     * This is the bridge between HealthKit's category samples and the pure domain model.
     * Source name is matched case-insensitively: containing "watch" maps to [SleepSource.WATCH],
     * otherwise [SleepSource.PHONE].
     *
     * @param values Array of tuples with (start, end, value, sourceName).
     * @return Array of SleepInterval instances, filtering out unknown sleep stages.
     */
    fun convertSamples(
        values: List<SleepSampleValue>
    ): List<SleepInterval> {
        return values.mapNotNull { sample ->
            val stage = SleepStage.fromValue(sample.value) ?: return@mapNotNull null
            val source = if (sample.sourceName.lowercase().contains("watch")) {
                SleepSource.WATCH
            } else {
                SleepSource.PHONE
            }
            SleepInterval(start = sample.start, end = sample.end, source = source, stage = stage)
        }
    }

    /** Raw sample data for conversion. */
    data class SleepSampleValue(
        val start: Instant,
        val end: Instant,
        val value: Int,
        val sourceName: String
    )
}

// MARK: - Training Load Scorer

/**
 * Scores training load based on the Acute:Chronic Workload Ratio (ACWR).
 *
 * Compares current week workout volume against the prior 3-week average.
 * A ratio around 1.0 indicates balanced load; above 1.5 indicates
 * overreaching; below 0.8 indicates detraining.
 */
object TrainingLoadScorer {

    /** Result of training load scoring. */
    data class LoadScoreResult(
        val score: Int,
        val explanation: String
    )

    /**
     * Computes a training load sub-score from weekly summaries.
     *
     * @param summaries Weekly summaries (last 4 weeks recommended).
     * @return Tuple of (score 0-100, explanation string).
     */
    fun score(summaries: List<WeeklySummary>): LoadScoreResult {
        if (summaries.size < 2) {
            return LoadScoreResult(75, "Insufficient training history -- moderate default")
        }

        val sorted = summaries.sortedBy { it.weekStartDate }
        val currentWeek = sorted.last()
        val priorWeeks = sorted.dropLast(1)

        val currentCount = currentWeek.workoutCount.toDouble()
        val priorAvg = if (priorWeeks.isEmpty()) {
            currentCount
        } else {
            priorWeeks.map { it.workoutCount.toDouble() }.average()
        }

        if (priorAvg <= 0) {
            return LoadScoreResult(75, "No prior training data -- moderate default")
        }

        val acwr = currentCount / priorAvg
        return scoreACWR(acwr)
    }

    /**
     * Scores an ACWR value on a 0-100 scale.
     *
     * @param acwr Acute:Chronic Workload Ratio.
     * @return Tuple of (score 0-100, explanation string).
     */
    private fun scoreACWR(acwr: Double): LoadScoreResult {
        return when {
            acwr < 0.8 ->
                LoadScoreResult(90, "Load is well within recovery range -- well rested")
            acwr < 1.0 ->
                LoadScoreResult(80, "Load is within recovery range")
            acwr < 1.3 ->
                LoadScoreResult(60, "Load is within recovery range -- building phase")
            acwr < 1.5 ->
                LoadScoreResult(40, "High weekly load -- body needs recovery time")
            else ->
                LoadScoreResult(20, "High weekly load -- body needs recovery time")
        }
    }
}

// MARK: - Cycle Phase Scorer

/**
 * Scores the current cycle phase as a contextual modifier for recovery.
 *
 * Each phase has inherent energy and recovery characteristics:
 * - Follicular: energy rising, good for intensity
 * - Ovulation: peak performance window
 * - Luteal: progesterone rises, recovery may be slower
 * - Menstrual: energy typically lowest
 */
object CyclePhaseScorer {

    /** Result of cycle phase scoring. */
    data class PhaseScoreResult(
        val score: Int,
        val explanation: String
    )

    /**
     * Scores a cycle phase as a recovery input.
     *
     * @param phase Current cycle phase (null when no data available).
     * @return Tuple of (score 0-100, explanation string).
     */
    fun score(phase: CyclePhase?): PhaseScoreResult {
        return when (phase) {
            CyclePhase.FOLLICULAR ->
                PhaseScoreResult(80, "Follicular phase -- energy rising, good for intensity")
            CyclePhase.OVULATION ->
                PhaseScoreResult(85, "Ovulation phase -- peak performance window")
            CyclePhase.LUTEAL ->
                PhaseScoreResult(60, "Luteal phase -- recovery may be slower, focus on maintenance")
            CyclePhase.MENSTRUAL ->
                PhaseScoreResult(50, "Menstrual phase -- energy typically lower, prioritize recovery")
            null ->
                PhaseScoreResult(70, "No cycle data -- moderate default")
        }
    }
}

// MARK: - Pain Scorer

/**
 * Scores pain intensity from DailyPainLog on a 0-100 recovery scale.
 *
 * Uses a linear mapping from the 1-10 pain intensity scale:
 * - Intensity 1 (minimal pain) -> score 100
 * - Intensity 10 (severe pain) -> score 1
 */
object PainScorer {

    /** Result of pain scoring. */
    data class PainScoreResult(
        val score: Int,
        val explanation: String
    )

    /**
     * Scores a pain intensity value as a recovery input.
     *
     * @param intensity Pain intensity on 1-10 scale. Clamped to valid range.
     * @return Tuple of (score 0-100, explanation string).
     */
    fun score(intensity: Int): PainScoreResult {
        val clamped = max(1, min(10, intensity))
        val score = max(0, 100 - ((clamped - 1) * 11))
        val explanation = explanationForIntensity(clamped)

        return PainScoreResult(score, explanation)
    }

    /**
     * Returns a human-readable explanation for a pain intensity level.
     */
    private fun explanationForIntensity(intensity: Int): String {
        return when (intensity) {
            in 1..2 -> "Minimal pain"
            in 3..5 -> "Moderate soreness"
            else -> "High pain -- prioritize recovery"
        }
    }
}
