package com.sundeefundee.domain.model

data class PeriodLog(
    val id: String,
    val odUserID: String,
    val startDate: Long,
    val endDate: Long?,
    val flowIntensityRaw: String?
)
