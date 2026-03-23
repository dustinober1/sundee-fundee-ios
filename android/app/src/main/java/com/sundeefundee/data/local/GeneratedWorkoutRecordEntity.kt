package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "generated_workout_records",
    indices = [
        Index(value = ["od_user_id"]),
        Index(value = ["generated_at"])
    ]
)
data class GeneratedWorkoutRecordEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "od_user_id")
    val odUserID: String,
    
    @ColumnInfo(name = "generated_at")
    val generatedAt: Long,
    
    @ColumnInfo(name = "context_json")
    val contextJson: String,
    
    @ColumnInfo(name = "result_json")
    val resultJson: String,
    
    @ColumnInfo(name = "used_for_workout")
    val usedForWorkout: Boolean
) {
    companion object {
        const val TABLE_NAME = "generated_workout_records"
    }
}
