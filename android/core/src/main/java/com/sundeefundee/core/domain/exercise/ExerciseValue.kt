package com.sundeefundee.core.domain.exercise

import kotlinx.serialization.Serializable

// Discriminated union for set types — mirrors iOS ExerciseType
@Serializable
sealed class ExerciseValue {
    @Serializable
    data class Fixed(val value: Int) : ExerciseValue()

    @Serializable
    data object Amrap : ExerciseValue()

    @Serializable
    data class Range(val min: Int, val max: Int) : ExerciseValue()

    @Serializable
    data class Text(val value: String) : ExerciseValue()

    val description: String
        get() = when (this) {
            is Fixed -> "Fixed"
            is Amrap -> "AMRAP"
            is Range -> "$min-$max reps"
            is Text -> value
        }
}
