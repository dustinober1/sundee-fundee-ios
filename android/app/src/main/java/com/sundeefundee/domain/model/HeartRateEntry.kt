package com.sundeefundee.domain.model

/**
 * Represents a heart rate entry from Health Connect
 */
data class HeartRateEntry(
    val timestamp: Long,
    val beatsPerMinute: Int
)
