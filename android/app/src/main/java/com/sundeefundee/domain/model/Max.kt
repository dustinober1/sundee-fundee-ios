package com.sundeefundee.domain.model

data class Max(
    val id: String,
    val odUserID: String,
    val liftName: String,
    val weight: Double,
    val unitRaw: String,
    val achievedDate: Long,
    val createdAt: Long
)
