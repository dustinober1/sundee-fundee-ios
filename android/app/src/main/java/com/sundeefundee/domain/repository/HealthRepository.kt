package com.sundeefundee.domain.repository

import com.sundeefundee.domain.model.CompletedWorkout
import com.sundeefundee.domain.model.InjuryProfile
import com.sundeefundee.domain.model.PainLog
import com.sundeefundee.domain.model.ReadinessScore
import kotlinx.coroutines.flow.Flow

interface HealthRepository {
    // Readiness
    fun getReadinessScore(): Flow<Int?>
    suspend fun calculateReadinessScore(): ReadinessScore?
    
    // Injury & Pain
    fun getInjuriesForUser(userId: String): Flow<List<InjuryProfile>>
    fun getActiveInjuries(userId: String): Flow<List<InjuryProfile>>
    fun getPainLogsForUser(userId: String): Flow<List<PainLog>>
    suspend fun addInjury(injury: InjuryProfile)
    suspend fun updateInjury(injury: InjuryProfile)
    suspend fun logPain(painLog: PainLog)
    suspend fun resolveInjury(injuryId: String)
    
    // Health Connect Integration
    suspend fun syncWorkoutToHealthConnect(workout: CompletedWorkout): Result<Boolean>
    fun hasHealthConnectPermissions(): Flow<Boolean>
}
