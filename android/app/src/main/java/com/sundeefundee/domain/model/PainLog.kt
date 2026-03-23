package com.sundeefundee.domain.model

data class PainLog(
    val id: String,
    val odUserID: String,
    val bodyLocationRaw: String,
    val painLevel: Int,
    val loggedAt: Long,
    val notes: String?
)
