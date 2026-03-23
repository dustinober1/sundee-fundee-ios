package com.sundeefundee.domain.model

data class Program(
    val id: String,
    val name: String,
    val programDescription: String,
    val difficultyLevelRaw: String,
    val estimatedDurationWeeks: Int,
    val targetAudience: String,
    val createdAt: Long
)
