package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface CompletedWorkoutDao {
    @Query("SELECT * FROM completed_workouts WHERE userId = :userId ORDER BY completedAt DESC")
    fun getWorkoutsForUser(userId: String): Flow<List<CompletedWorkoutEntity>>

    @Query("SELECT * FROM completed_workouts WHERE id = :id")
    fun getWorkoutById(id: String): Flow<CompletedWorkoutEntity?>

    @Query("SELECT * FROM completed_workouts WHERE userId = :userId AND completedAt >= :startDate AND completedAt <= :endDate ORDER BY completedAt DESC")
    fun getWorkoutsForDateRange(userId: String, startDate: Long, endDate: Long): Flow<List<CompletedWorkoutEntity>>

    @Query("SELECT * FROM completed_workouts WHERE userId = :userId ORDER BY completedAt DESC LIMIT :limit")
    fun getRecentWorkouts(userId: String, limit: Int): Flow<List<CompletedWorkoutEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(workout: CompletedWorkoutEntity)

    @Update
    suspend fun update(workout: CompletedWorkoutEntity)

    @Delete
    suspend fun delete(workout: CompletedWorkoutEntity)
}
