package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "enrolled_programs",
    indices = [
        Index(value = ["user_id"]),
        Index(value = ["program_id"])
    ]
)
data class EnrolledProgramEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "user_id")
    val odUserID: String,
    
    @ColumnInfo(name = "program_id")
    val programId: String,
    
    @ColumnInfo(name = "enrolled_at")
    val enrolledAt: Long,
    
    @ColumnInfo(name = "completed_at")
    val completedAt: Long?,
    
    @ColumnInfo(name = "current_week")
    val currentWeek: Int,
    
    @ColumnInfo(name = "current_day")
    val currentDay: Int
) {
    companion object {
        const val TABLE_NAME = "enrolled_programs"
    }
}
