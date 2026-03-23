package com.sundeefundee.domain.model

data class InjuryProfile(
    val id: String,
    val odUserID: String,
    val bodyLocationRaw: String,
    val severity: Int,
    val description: String,
    val isResolved: Boolean,
    val createdAt: Long,
    val resolvedAt: Long?
)
