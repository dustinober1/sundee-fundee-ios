package com.sundeefundee.data.repository

import com.sundeefundee.data.local.InjuryProfileDao
import com.sundeefundee.data.local.InjuryProfileEntity
import com.sundeefundee.data.local.PainLogDao
import com.sundeefundee.data.local.PainLogEntity
import com.sundeefundee.data.remote.Exercise
import com.sundeefundee.data.remote.ExerciseType
import com.sundeefundee.data.remote.HealthConnectService
import com.sundeefundee.domain.model.CompletedWorkout
import com.sundeefundee.domain.model.InjuryProfile
import com.sundeefundee.domain.model.PainLog
import com.sundeefundee.domain.model.ReadinessScore
import com.sundeefundee.domain.repository.HealthRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class HealthRepositoryImpl @Inject constructor(
    private val injuryProfileDao: InjuryProfileDao,
    private val painLogDao: PainLogDao,
    private val healthConnectService: HealthConnectService?,
    private val calculateReadinessScoreUseCase: com.sundeefundee.domain.usecase.CalculateReadinessUseCase
) : HealthRepository {

    override fun getReadinessScore(): Flow<Int?> {
        // Readiness score would be calculated based on active injuries and recent pain logs
        // This is a placeholder implementation
        return flow { emit(null) }
    }
    
    override suspend fun calculateReadinessScore(): ReadinessScore? {
        return try {
            calculateReadinessScoreUseCase()
        } catch (e: Exception) {
            null
        }
    }

    override fun getInjuriesForUser(userId: String): Flow<List<InjuryProfile>> {
        return injuryProfileDao.getInjuriesForUser(userId).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getActiveInjuries(userId: String): Flow<List<InjuryProfile>> {
        return injuryProfileDao.getActiveInjuries(userId).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getPainLogsForUser(userId: String): Flow<List<PainLog>> {
        return painLogDao.getPainLogsForUser(userId).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override suspend fun addInjury(injury: InjuryProfile) {
        injuryProfileDao.insert(injury.toEntity())
    }

    override suspend fun updateInjury(injury: InjuryProfile) {
        injuryProfileDao.update(injury.toEntity())
    }

    override suspend fun logPain(painLog: PainLog) {
        painLogDao.insert(painLog.toEntity())
    }

    override suspend fun resolveInjury(injuryId: String) {
        // This would need a specific query or we need to fetch then update
        // For now, this is a placeholder that would be implemented with actual logic
    }
    
    // Health Connect Integration
    
    override suspend fun syncWorkoutToHealthConnect(workout: CompletedWorkout): Result<Boolean> {
        if (healthConnectService == null) {
            return Result.failure(IllegalStateException("Health Connect is not available"))
        }
        
        val exerciseType = when {
            workout.name.contains("run", ignoreCase = true) -> ExerciseType.RUNNING
            workout.name.contains("walk", ignoreCase = true) -> ExerciseType.WALKING
            workout.name.contains("strength", ignoreCase = true) -> ExerciseType.STRENGTH_TRAINING
            workout.name.contains("stretch", ignoreCase = true) -> ExerciseType.FLEXIBILITY
            workout.name.contains("sports", ignoreCase = true) -> ExerciseType.SPORTS
            else -> ExerciseType.CROSS_TRAINING
        }
        
        val exercise = Exercise(
            startTime = workout.completedAt,
            endTime = workout.completedAt + (workout.durationMinutes * 60 * 1000),
            exerciseType = exerciseType,
            title = workout.name,
            caloriesBurned = workout.caloriesBurned?.toDouble()
        )
        
        return healthConnectService.writeExercise(exercise)
    }
    
    override fun hasHealthConnectPermissions(): Flow<Boolean> = flow {
        if (healthConnectService == null) {
            emit(false)
        } else {
            emit(healthConnectService.hasAllPermissions())
        }
    }

    private fun InjuryProfileEntity.toDomain(): InjuryProfile {
        return InjuryProfile(
            id = id,
            odUserID = odUserID,
            bodyLocationRaw = bodyLocationRaw,
            severity = severity,
            description = description,
            isResolved = isResolved,
            createdAt = createdAt,
            resolvedAt = resolvedAt
        )
    }

    private fun InjuryProfile.toEntity(): InjuryProfileEntity {
        return InjuryProfileEntity(
            id = id,
            odUserID = odUserID,
            bodyLocationRaw = bodyLocationRaw,
            severity = severity,
            description = description,
            isResolved = isResolved,
            createdAt = createdAt,
            resolvedAt = resolvedAt
        )
    }

    private fun PainLogEntity.toDomain(): PainLog {
        return PainLog(
            id = id,
            odUserID = odUserID,
            bodyLocationRaw = bodyLocationRaw,
            painLevel = painLevel,
            loggedAt = loggedAt,
            notes = notes
        )
    }

    private fun PainLog.toEntity(): PainLogEntity {
        return PainLogEntity(
            id = id,
            odUserID = odUserID,
            bodyLocationRaw = bodyLocationRaw,
            painLevel = painLevel,
            loggedAt = loggedAt,
            notes = notes
        )
    }
}
