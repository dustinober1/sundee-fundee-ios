package com.sundeefundee.domain.repository

import com.sundeefundee.domain.model.CompletedWorkout
import kotlinx.coroutines.flow.Flow

interface WorkoutRepository {
    fun getWorkoutsForUser(userId: String): Flow<List<CompletedWorkout>>
    fun getWorkoutById(id: String): Flow<CompletedWorkout?>
    fun getWorkoutsForDateRange(userId: String, startDate: Long, endDate: Long): Flow<List<CompletedWorkout>>
    fun getRecentWorkouts(userId: String, limit: Int): Flow<List<CompletedWorkout>>
    suspend fun logWorkout(workout: CompletedWorkout)
    suspend fun updateWorkout(workout: CompletedWorkout)
    suspend fun deleteWorkout(workout: CompletedWorkout)
}
