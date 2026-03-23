package com.sundeefundee.domain

import com.sundeefundee.domain.model.PainLog

/**
 * Result of pain trend analysis.
 */
data class PainTrend(
    val trailingAverage: Double,
    val isImproving: Boolean,
    val latestPainLevel: Int?,
    val readingCount: Int
)

/**
 * Pure functions for analyzing pain trends from pain logs.
 */
object PainTrendAnalyzer {

    private const val DEFAULT_WINDOW_SIZE = 7

    /**
     * Analyzes pain trend from logs sorted by date (newest first).
     *
     * @param logs Pain logs for a single injury, sorted newest first
     * @param windowSize Number of recent readings to consider
     * @return PainTrend with analysis results
     */
    fun analyzeTrend(
        logs: List<PainLog>,
        windowSize: Int = DEFAULT_WINDOW_SIZE
    ): PainTrend {
        if (logs.isEmpty()) {
            return PainTrend(
                trailingAverage = 0.0,
                isImproving = false,
                latestPainLevel = null,
                readingCount = 0
            )
        }

        val recent = logs.take(windowSize)
        val average = recent.map { it.painLevel }.average()
        val latest = logs.firstOrNull()?.painLevel

        // Compare first half vs second half of window to determine trend
        val improving = if (recent.size >= 2) {
            val midpoint = recent.size / 2
            val newerHalf = recent.take(midpoint)
            val olderHalf = recent.drop(midpoint)

            if (newerHalf.isEmpty() || olderHalf.isEmpty()) {
                false
            } else {
                val newerAvg = newerHalf.map { it.painLevel }.average()
                val olderAvg = olderHalf.map { it.painLevel }.average()
                newerAvg < olderAvg
            }
        } else {
            false
        }

        return PainTrend(
            trailingAverage = average,
            isImproving = improving,
            latestPainLevel = latest,
            readingCount = logs.size
        )
    }

    /**
     * Checks if a pain log has been recorded in the last N hours for the given injury.
     */
    fun hasRecentLog(logs: List<PainLog>, withinHours: Double = 24.0): Boolean {
        val latest = logs.firstOrNull() ?: return false
        val hoursSince = (System.currentTimeMillis() - latest.loggedAt) / (1000.0 * 60.0 * 60.0)
        return hoursSince <= withinHours
    }

    /**
     * Returns the last N pain levels for sparkline display.
     * Returns in chronological order (oldest first).
     */
    fun sparklineData(logs: List<PainLog>, count: Int = DEFAULT_WINDOW_SIZE): List<Int> {
        return logs
            .take(count)
            .reversed()
            .map { it.painLevel }
    }

    /**
     * Calculates the rate of change in pain levels.
     * Positive = worsening, Negative = improving.
     */
    fun calculateRateOfChange(logs: List<PainLog>, windowSize: Int = DEFAULT_WINDOW_SIZE): Double {
        if (logs.size < 2) return 0.0

        val recent = logs.take(windowSize)
        if (recent.size < 2) return 0.0

        val midpoint = recent.size / 2
        val newerHalf = recent.take(midpoint)
        val olderHalf = recent.drop(midpoint)

        if (newerHalf.isEmpty() || olderHalf.isEmpty()) return 0.0

        val newerAvg = newerHalf.map { it.painLevel }.average()
        val olderAvg = olderHalf.map { it.painLevel }.average()

        return newerAvg - olderAvg
    }

    /**
     * Determines if pain is worsening based on logs.
     */
    fun isWorsening(logs: List<PainLog>, windowSize: Int = DEFAULT_WINDOW_SIZE): Boolean {
        return calculateRateOfChange(logs, windowSize) > 0.5
    }

    /**
     * Gets the maximum pain level in the window.
     */
    fun getMaxPainLevel(logs: List<PainLog>, windowSize: Int = DEFAULT_WINDOW_SIZE): Int? {
        return logs.take(windowSize).maxByOrNull { it.painLevel }?.painLevel
    }

    /**
     * Gets the minimum pain level in the window.
     */
    fun getMinPainLevel(logs: List<PainLog>, windowSize: Int = DEFAULT_WINDOW_SIZE): Int? {
        return logs.take(windowSize).minByOrNull { it.painLevel }?.painLevel
    }
}
