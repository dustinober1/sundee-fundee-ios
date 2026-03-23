package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(
    tableName = "programs"
)
data class ProgramEntity(
    @PrimaryKey
    val id: String,
    
    val name: String,
    
    @ColumnInfo(name = "program_description")
    val programDescription: String,
    
    @ColumnInfo(name = "difficulty_level_raw")
    val difficultyLevelRaw: String,
    
    @ColumnInfo(name = "estimated_duration_weeks")
    val estimatedDurationWeeks: Int,
    
    @ColumnInfo(name = "target_audience")
    val targetAudience: String,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Long
) {
    companion object {
        const val TABLE_NAME = "programs"
    }
}
