package com.sundeefundee.domain.model

data class ActiveCycle(
    val id: String,
    val odUserID: String,
    val startDate: Long,
    val currentPhaseRaw: String,
    val predictedEndDate: Long?
)
