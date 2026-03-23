package com.sundeefundee.domain.model

data class BenchmarkDefinition(
    val id: String,
    val name: String,
    val description: String,
    val wodTypeRaw: String,
    val scoringTypeRaw: String,
    val targetTime: Int?,
    val roundsAndReps: String?,
    val exercises: String,
    val createdAt: Long
)
