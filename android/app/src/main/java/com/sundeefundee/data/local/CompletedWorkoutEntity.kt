package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "completed_workouts",
    indices = [
        Index(value = ["od_user_id"]),
        Index(value = ["workout_date"]),
        Index(value = ["program_id"])
    ]
)
data class CompletedWorkoutEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "od_user_id")
    val odUserID: String,
    
    @ColumnInfo(name = "workout_date")
    val workoutDate: Long,
    
    @ColumnInfo(name = "workout_name")
    val workoutName: String,
    
    @ColumnInfo(name = "program_id")
    val programId: String?,
    
    @ColumnInfo(name = "wod_type_raw")
    val wodTypeRaw: String?,
    
    val duration: Int,
    
    @ColumnInfo(name = "total_volume")
    val totalVolume: Double?,
    
    @ColumnInfo(name = "spicy_rating")
    val spicyRating: Int?,
    
    val notes: String?,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Long
) {
    companion object {
        const val TABLE_NAME = "completed_workouts"
    }
}
