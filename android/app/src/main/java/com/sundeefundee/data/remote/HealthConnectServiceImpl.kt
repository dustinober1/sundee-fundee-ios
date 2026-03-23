package com.sundeefundee.data.remote

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.TotalCaloriesBurnedRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.changes.Direction
import com.sundeefundee.domain.model.ExerciseEntry
import com.sundeefundee.domain.model.HeartRateEntry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class HealthConnectServiceImpl(
    private val context: Context
) : HealthConnectService {
    
    private val healthConnectClient: HealthConnectClient? by lazy {
        try {
            if (HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE) {
                HealthConnectClient.getOrCreate(context)
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
    
    override suspend fun checkAvailability(): HealthConnectService.HealthConnectAvailability {
        return withContext(Dispatchers.IO) {
            val sdkStatus = HealthConnectClient.getSdkStatus(context)
            when {
                sdkStatus == HealthConnectClient.SDK_AVAILABLE -> 
                    HealthConnectService.HealthConnectAvailability.INSTALLED
                sdkStatus == HealthConnectClient.SDK_UNAVAILABLE -> 
                    HealthConnectService.HealthConnectAvailability.NOT_INSTALLED
                else -> 
                    HealthConnectService.HealthConnectAvailability.NOT_SUPPORTED
            }
        }
    }
    
    override suspend fun requestPermissions(): Result<Boolean> {
        return withContext(Dispatchers.IO) {
            try {
                val client = healthConnectClient
                    ?: return@withContext Result.failure(
                        IllegalStateException("Health Connect is not available")
                    )
                
                val granted = client.permissionController.requestPermissions(
                    getRequiredPermissions()
                )
                
                val allGranted = getRequiredPermissions().all { permission ->
                    granted.contains(permission)
                }
                
                Result.success(allGranted)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }
    
    override suspend fun hasAllPermissions(): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val client = healthConnectClient ?: return@withContext false
                val granted = client.permissionController.getGrantedPermissions()
                getRequiredPermissions().all { permission ->
                    granted.contains(permission)
                }
            } catch (e: Exception) {
                false
            }
        }
    }
    
    override fun getRequiredPermissions(): Set<String> {
        return setOf(
            HealthPermission.getReadPermission(ExerciseSessionRecord::class),
            HealthPermission.getWritePermission(ExerciseSessionRecord::class),
            HealthPermission.getReadPermission(HeartRateRecord::class),
            HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
            HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class)
        )
    }
    
    override suspend fun readExercises(
        startTime: Long,
        endTime: Long
    ): Result<List<ExerciseEntry>> {
        return withContext(Dispatchers.IO) {
            try {
                val client = healthConnectClient
                    ?: return@withContext Result.failure(
                        IllegalStateException("Health Connect is not available")
                    )
                
                val timeRangeFilter = TimeRangeFilter.between(
                    java.time.Instant.ofEpochMilli(startTime),
                    java.time.Instant.ofEpochMilli(endTime)
                )
                
                val request = ReadRecordsRequest(
                    recordType = ExerciseSessionRecord::class,
                    timeRangeFilter = timeRangeFilter
                )
                
                val response = client.readRecords(request)
                
                val exercises = response.records.map { record ->
                    ExerciseEntry(
                        startTime = record.startTime.toEpochMilli(),
                        endTime = record.endTime.toEpochMilli(),
                        exerciseType = ExerciseType.fromHealthConnectType(
                            record.exerciseType
                        ),
                        title = record.title,
                        caloriesBurned = null // Would need to query separately for calories
                    )
                }
                
                Result.success(exercises)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }
    
    override suspend fun readHeartRate(
        startTime: Long,
        endTime: Long
    ): Result<List<HeartRateEntry>> {
        return withContext(Dispatchers.IO) {
            try {
                val client = healthConnectClient
                    ?: return@withContext Result.failure(
                        IllegalStateException("Health Connect is not available")
                    )
                
                val timeRangeFilter = TimeRangeFilter.between(
                    java.time.Instant.ofEpochMilli(startTime),
                    java.time.Instant.ofEpochMilli(endTime)
                )
                
                val request = ReadRecordsRequest(
                    recordType = HeartRateRecord::class,
                    timeRangeFilter = timeRangeFilter
                )
                
                val response = client.readRecords(request)
                
                val heartRates = response.records.flatMap { record ->
                    record.samples.map { sample ->
                        HeartRateEntry(
                            timestamp = sample.time.toEpochMilli(),
                            beatsPerMinute = sample.samples.firstOrNull()?.toInt() ?: 0
                        )
                    }
                }
                
                Result.success(heartRates)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }
    
    override suspend fun writeExercise(exercise: Exercise): Result<Boolean> {
        return withContext(Dispatchers.IO) {
            try {
                val client = healthConnectClient
                    ?: return@withContext Result.failure(
                        IllegalStateException("Health Connect is not available")
                    )
                
                val exerciseRecord = ExerciseSessionRecord(
                    startTime = java.time.Instant.ofEpochMilli(exercise.startTime),
                    endTime = java.time.Instant.ofEpochMilli(exercise.endTime),
                    exerciseType = exercise.exerciseType.healthConnectType,
                    title = exercise.title,
                    startZoneOffset = java.time.ZoneOffset.UTC,
                    endZoneOffset = java.time.ZoneOffset.UTC
                )
                
                val records = mutableListOf<androidx.health.connect.client.records.Record>(
                    exerciseRecord
                )
                
                // Add calories if provided
                exercise.caloriesBurned?.let { calories ->
                    val caloriesRecord = ActiveCaloriesBurnedRecord(
                        startTime = java.time.Instant.ofEpochMilli(exercise.startTime),
                        endTime = java.time.Instant.ofEpochMilli(exercise.endTime),
                        energy = androidx.health.connect.client.units.Energy.calories(calories),
                        startZoneOffset = java.time.ZoneOffset.UTC,
                        endZoneOffset = java.time.ZoneOffset.UTC
                    )
                    records.add(caloriesRecord)
                }
                
                client.insertRecords(records)
                Result.success(true)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }
    
    companion object {
        /**
         * Returns an intent to open the Health Connect app or Play Store
         */
        fun getHealthConnectInstallIntent(): Intent {
            val packageName = "com.google.android.apps.healthdata"
            return Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("market://details?id=$packageName")
                setPackage(packageName)
            }
        }
    }
}
