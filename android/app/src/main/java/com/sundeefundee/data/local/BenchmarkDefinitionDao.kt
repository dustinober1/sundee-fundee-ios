package com.sundeefundee.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface BenchmarkDefinitionDao {
    @Query("SELECT * FROM benchmark_definitions ORDER BY name ASC")
    fun getAllDefinitions(): Flow<List<BenchmarkDefinitionEntity>>

    @Query("SELECT * FROM benchmark_definitions WHERE id = :id")
    fun getDefinitionById(id: String): Flow<BenchmarkDefinitionEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(definitions: List<BenchmarkDefinitionEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(definition: BenchmarkDefinitionEntity)
}
