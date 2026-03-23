package com.sundeefundee.domain.model

data class User(
    val id: String,
    val name: String,
    val experienceLevelRaw: String,
    val primaryGoalRaw: String,
    val genderRaw: String,
    val weightUnitRaw: String?,
    val googleUserID: String,
    val cycleTrackingEnabled: Boolean,
    val onboardingComplete: Boolean,
    val createdAt: Long,
    val profileUpdatedAt: Long?
)
