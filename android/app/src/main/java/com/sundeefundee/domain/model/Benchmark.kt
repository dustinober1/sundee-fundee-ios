package com.sundeefundee.domain.model

data class Benchmark(
    val id: String,
    val odUserID: String,
    val benchmarkId: String,
    val score: Double,
    val achievedDate: Long,
    val notes: String?
)
