package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface GeneratedWorkoutRecordDao {
    @Query("SELECT * FROM generated_workout_records WHERE userId = :userId ORDER BY generatedAt DESC")
    fun getRecordsForUser(userId: String): Flow<List<GeneratedWorkoutRecordEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(record: GeneratedWorkoutRecordEntity)

    @Update
    suspend fun update(record: GeneratedWorkoutRecordEntity)
}
