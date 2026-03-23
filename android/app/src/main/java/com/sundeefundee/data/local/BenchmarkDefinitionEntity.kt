package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(
    tableName = "benchmark_definitions"
)
data class BenchmarkDefinitionEntity(
    @PrimaryKey
    val id: String,
    
    val name: String,
    
    val description: String,
    
    @ColumnInfo(name = "wod_type_raw")
    val wodTypeRaw: String,
    
    @ColumnInfo(name = "scoring_type_raw")
    val scoringTypeRaw: String,
    
    @ColumnInfo(name = "target_time")
    val targetTime: Int?,
    
    @ColumnInfo(name = "rounds_and_reps")
    val roundsAndReps: String?,
    
    val exercises: String,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Long
) {
    companion object {
        const val TABLE_NAME = "benchmark_definitions"
    }
}
