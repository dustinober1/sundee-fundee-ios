package com.sundeefundee.domain.model

data class GeneratedWorkoutRecord(
    val id: String,
    val odUserID: String,
    val generatedAt: Long,
    val contextJson: String,
    val resultJson: String,
    val usedForWorkout: Boolean
)
