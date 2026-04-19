package com.sundeefundee.core.data.protocol

import kotlinx.datetime.Instant

// Health data interface — mirrors iOS HealthClientProtocol
interface HealthClient {
    val isAvailable: Boolean

    suspend fun requestAuthorization()

    suspend fun fetchWorkouts(
        startDate: Instant? = null,
        endDate: Instant? = null,
        limit: Int = 100
    ): List<HealthWorkout>

    suspend fun fetchMenstrualCycles(
        startDate: Instant? = null,
        endDate: Instant? = null,
        limit: Int = 50
    ): List<MenstrualCycleRecord>

    suspend fun fetchActiveEnergy(startDate: Instant, endDate: Instant): List<ActiveEnergyRecord>

    suspend fun fetchHeartRateVariability(startDate: Instant, endDate: Instant): List<HRVRecord>

    suspend fun fetchRestingHeartRate(startDate: Instant, endDate: Instant): List<RestingHeartRateRecord>

    suspend fun fetchSleepAnalysis(startDate: Instant, endDate: Instant): List<SleepRecord>

    suspend fun saveWorkout(
        startDate: Instant,
        endDate: Instant,
        totalEnergyBurnedKcal: Double,
        exerciseNames: List<String>
    )
}

data class HealthWorkout(
    val id: String,
    val startDate: Instant,
    val endDate: Instant,
    val totalEnergyBurnedKcal: Double,
    val exerciseType: String
)

data class MenstrualCycleRecord(
    val startDate: Instant,
    val endDate: Instant?,
    val flowLevel: Int?
)

data class ActiveEnergyRecord(
    val startDate: Instant,
    val endDate: Instant,
    val kilocalories: Double
)

data class HRVRecord(
    val startDate: Instant,
    val valueMillis: Double
)

data class RestingHeartRateRecord(
    val startDate: Instant,
    val beatsPerMinute: Double
)

data class SleepRecord(
    val startDate: Instant,
    val endDate: Instant,
    val stage: String
)
