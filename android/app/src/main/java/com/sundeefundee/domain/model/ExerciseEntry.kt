package com.sundeefundee.domain.model

import com.sundeefundee.data.remote.ExerciseType

/**
 * Represents an exercise entry from Health Connect
 */
data class ExerciseEntry(
    val startTime: Long,
    val endTime: Long,
    val exerciseType: ExerciseType,
    val title: String? = null,
    val caloriesBurned: Double? = null
) {
    val durationMinutes: Long
        get() = (endTime - startTime) / (1000 * 60)
}
