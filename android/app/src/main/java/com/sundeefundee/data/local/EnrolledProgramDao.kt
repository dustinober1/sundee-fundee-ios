package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface EnrolledProgramDao {
    @Query("SELECT * FROM enrolled_programs WHERE userId = :userId ORDER BY enrolledAt DESC")
    fun getEnrollmentsForUser(userId: String): Flow<List<EnrolledProgramEntity>>

    @Query("SELECT * FROM enrolled_programs WHERE id = :id")
    fun getEnrollmentById(id: String): Flow<EnrolledProgramEntity?>

    @Query("SELECT * FROM enrolled_programs WHERE userId = :userId AND isActive = 1 LIMIT 1")
    fun getActiveEnrollment(userId: String): Flow<EnrolledProgramEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(enrollment: EnrolledProgramEntity)

    @Update
    suspend fun update(enrollment: EnrolledProgramEntity)

    @Delete
    suspend fun delete(enrollment: EnrolledProgramEntity)
}
