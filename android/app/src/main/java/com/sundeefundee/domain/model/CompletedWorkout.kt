package com.sundeefundee.domain.model

data class CompletedWorkout(
    val id: String,
    val odUserID: String,
    val workoutDate: Long,
    val workoutName: String,
    val programId: String?,
    val wodTypeRaw: String?,
    val duration: Int,
    val totalVolume: Double?,
    val spicyRating: Int?,
    val notes: String?,
    val createdAt: Long
)
