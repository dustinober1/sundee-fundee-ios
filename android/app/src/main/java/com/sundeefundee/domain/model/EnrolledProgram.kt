package com.sundeefundee.domain.model

data class EnrolledProgram(
    val id: String,
    val odUserID: String,
    val programId: String,
    val enrolledAt: Long,
    val completedAt: Long?,
    val currentWeek: Int,
    val currentDay: Int
)
