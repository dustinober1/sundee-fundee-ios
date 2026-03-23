package com.sundeefundee.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "benchmarks",
    indices = [
        Index(value = ["user_id"]),
        Index(value = ["benchmark_id"]),
        Index(value = ["achieved_date"])
    ]
)
data class BenchmarkEntity(
    @PrimaryKey
    val id: String,
    
    @ColumnInfo(name = "user_id")
    val odUserID: String,
    
    @ColumnInfo(name = "benchmark_id")
    val benchmarkId: String,
    
    val score: Double,
    
    @ColumnInfo(name = "achieved_date")
    val achievedDate: Long,
    
    val notes: String?
) {
    companion object {
        const val TABLE_NAME = "benchmarks"
    }
}
