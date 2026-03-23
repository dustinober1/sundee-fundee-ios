package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface BenchmarkDao {
    @Query("SELECT * FROM benchmarks WHERE userId = :userId ORDER BY completedAt DESC")
    fun getBenchmarksForUser(userId: String): Flow<List<BenchmarkEntity>>

    @Query("SELECT * FROM benchmarks WHERE id = :id")
    fun getBenchmarkById(id: String): Flow<BenchmarkEntity?>

    @Query("SELECT * FROM benchmarks WHERE userId = :userId AND benchmarkId = :benchmarkId ORDER BY completedAt DESC")
    fun getBenchmarksForDefinition(userId: String, benchmarkId: String): Flow<List<BenchmarkEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(benchmark: BenchmarkEntity)

    @Update
    suspend fun update(benchmark: BenchmarkEntity)

    @Delete
    suspend fun delete(benchmark: BenchmarkEntity)
}
