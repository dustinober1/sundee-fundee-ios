package com.sundeefundee.data.repository

import com.sundeefundee.data.local.CompletedWorkoutDao
import com.sundeefundee.data.local.CompletedWorkoutEntity
import com.sundeefundee.domain.model.CompletedWorkout
import com.sundeefundee.domain.repository.WorkoutRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class WorkoutRepositoryImpl @Inject constructor(
    private val workoutDao: CompletedWorkoutDao
) : WorkoutRepository {

    override fun getWorkoutsForUser(userId: String): Flow<List<CompletedWorkout>> {
        return workoutDao.getWorkoutsForUser(userId).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getWorkoutById(id: String): Flow<CompletedWorkout?> {
        return workoutDao.getWorkoutById(id).map { entity ->
            entity?.toDomain()
        }
    }

    override fun getWorkoutsForDateRange(
        userId: String,
        startDate: Long,
        endDate: Long
    ): Flow<List<CompletedWorkout>> {
        return workoutDao.getWorkoutsForDateRange(userId, startDate, endDate).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getRecentWorkouts(userId: String, limit: Int): Flow<List<CompletedWorkout>> {
        return workoutDao.getRecentWorkouts(userId, limit).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override suspend fun logWorkout(workout: CompletedWorkout) {
        workoutDao.insert(workout.toEntity())
    }

    override suspend fun updateWorkout(workout: CompletedWorkout) {
        workoutDao.update(workout.toEntity())
    }

    override suspend fun deleteWorkout(workout: CompletedWorkout) {
        workoutDao.delete(workout.toEntity())
    }

    private fun CompletedWorkoutEntity.toDomain(): CompletedWorkout {
        return CompletedWorkout(
            id = id,
            odUserID = odUserID,
            workoutDate = workoutDate,
            workoutName = workoutName,
            programId = programId,
            wodTypeRaw = wodTypeRaw,
            duration = duration,
            totalVolume = totalVolume,
            spicyRating = spicyRating,
            notes = notes,
            createdAt = createdAt
        )
    }

    private fun CompletedWorkout.toEntity(): CompletedWorkoutEntity {
        return CompletedWorkoutEntity(
            id = id,
            odUserID = odUserID,
            workoutDate = workoutDate,
            workoutName = workoutName,
            programId = programId,
            wodTypeRaw = wodTypeRaw,
            duration = duration,
            totalVolume = totalVolume,
            spicyRating = spicyRating,
            notes = notes,
            createdAt = createdAt
        )
    }
}
