package com.sundeefundee.domain.model

data class CycleSettings(
    val id: String,
    val odUserID: String,
    val averageCycleLength: Int,
    val averagePeriodLength: Int,
    val lastPeriodStartDate: Long?
)
