package com.sundeefundee.core.data.healthconnect

import android.content.Context
import android.content.Intent
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.records.*
import androidx.health.connect.client.request.AggregateGroupByPeriodRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import com.sundeefundee.core.data.protocol.*
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.datetime.Instant
import javax.inject.Inject
import javax.inject.Singleton

// Health Connect client — mirrors iOS HealthKitClient
@Singleton
class HealthConnectClientWrapper @Inject constructor(
    @ApplicationContext private val context: Context
) : HealthClient {

    private val client: HealthConnectClient? by lazy {
        if (HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE) {
            HealthConnectClient.getOrCreate(context)
        } else null
    }

    override val isAvailable: Boolean
        get() = client != null

    override suspend fun requestAuthorization() {
        client?.requestPermissions(
            activity = TODO("Launch permission contract from UI"),
            permissions = buildSet {
                addAll(READ_PERMISSIONS)
                addAll(WRITE_PERMISSIONS)
            }
        )
    }

    override suspend fun fetchWorkouts(
        startDate: Instant?,
        endDate: Instant?,
        limit: Int
    ): List<HealthWorkout> {
        val hcClient = client ?: return emptyList()
        val request = ReadRecordsRequest(
            recordType = ExerciseSessionRecord::class,
            timeRangeFilter = buildTimeRange(startDate, endDate),
            ascendingOrder = false,
            pageSize = limit
        )
        val response = hcClient.readRecords(request)
        return response.records.map { record ->
            HealthWorkout(
                id = record.metadata.id,
                startDate = Instant.fromEpochMilliseconds(record.startTime.toEpochMilli()),
                endDate = Instant.fromEpochMilliseconds(record.endTime.toEpochMilli()),
                totalEnergyBurnedKcal = 0.0, // computed from associated records
                exerciseType = record.exerciseType.toString()
            )
        }
    }

    override suspend fun fetchMenstrualCycles(
        startDate: Instant?,
        endDate: Instant?,
        limit: Int
    ): List<MenstrualCycleRecord> {
        val hcClient = client ?: return emptyList()
        val request = ReadRecordsRequest(
            recordType = MenstruationFlowRecord::class,
            timeRangeFilter = buildTimeRange(startDate, endDate),
            pageSize = limit
        )
        val response = hcClient.readRecords(request)
        return response.records.map { record ->
            MenstrualCycleRecord(
                startDate = Instant.fromEpochMilliseconds(record.time.toEpochMilli()),
                endDate = null,
                flowLevel = record.flow?.value
            )
        }
    }

    override suspend fun fetchActiveEnergy(
        startDate: Instant,
        endDate: Instant
    ): List<ActiveEnergyRecord> {
        val hcClient = client ?: return emptyList()
        val request = ReadRecordsRequest(
            recordType = ActiveCaloriesBurnedRecord::class,
            timeRangeFilter = buildTimeRange(startDate, endDate)
        )
        val response = hcClient.readRecords(request)
        return response.records.map { record ->
            ActiveEnergyRecord(
                startDate = Instant.fromEpochMilliseconds(record.startTime.toEpochMilli()),
                endDate = Instant.fromEpochMilliseconds(record.endTime.toEpochMilli()),
                kilocalories = record.energy.inKilocalories
            )
        }
    }

    override suspend fun fetchHeartRateVariability(
        startDate: Instant,
        endDate: Instant
    ): List<HRVRecord> {
        val hcClient = client ?: return emptyList()
        val request = ReadRecordsRequest(
            recordType = HeartRateVariabilityRmssdRecord::class,
            timeRangeFilter = buildTimeRange(startDate, endDate)
        )
        val response = hcClient.readRecords(request)
        return response.records.map { record ->
            HRVRecord(
                startDate = Instant.fromEpochMilliseconds(record.time.toEpochMilli()),
                valueMillis = record.heartRateVariabilityMillis.inWholeMilliseconds.toDouble()
            )
        }
    }

    override suspend fun fetchRestingHeartRate(
        startDate: Instant,
        endDate: Instant
    ): List<RestingHeartRateRecord> {
        val hcClient = client ?: return emptyList()
        val request = ReadRecordsRequest(
            recordType = RestingHeartRateRecord::class,
            timeRangeFilter = buildTimeRange(startDate, endDate)
        )
        val response = hcClient.readRecords(request)
        return response.records.map { record ->
            RestingHeartRateRecord(
                startDate = Instant.fromEpochMilliseconds(record.time.toEpochMilli()),
                beatsPerMinute = record.beatsPerMinute.toDouble()
            )
        }
    }

    override suspend fun fetchSleepAnalysis(
        startDate: Instant,
        endDate: Instant
    ): List<SleepRecord> {
        val hcClient = client ?: return emptyList()
        val request = ReadRecordsRequest(
            recordType = SleepSessionRecord::class,
            timeRangeFilter = buildTimeRange(startDate, endDate)
        )
        val response = hcClient.readRecords(request)
        return response.records.map { record ->
            SleepRecord(
                startDate = Instant.fromEpochMilliseconds(record.startTime.toEpochMilli()),
                endDate = Instant.fromEpochMilliseconds(record.endTime.toEpochMilli()),
                stage = record.stages.firstOrNull()?.stage?.toString() ?: "sleep"
            )
        }
    }

    override suspend fun saveWorkout(
        startDate: Instant,
        endDate: Instant,
        totalEnergyBurnedKcal: Double,
        exerciseNames: List<String>
    ) {
        val hcClient = client ?: return
        val record = ExerciseSessionRecord(
            startTime = java.time.Instant.ofEpochMilli(startDate.toEpochMilliseconds()),
            startZoneOffset = null,
            endTime = java.time.Instant.ofEpochMilli(endDate.toEpochMilliseconds()),
            endZoneOffset = null,
            exerciseType = ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING
        )
        hcClient.insertRecords(listOf(record))
    }

    private fun buildTimeRange(start: Instant?, end: Instant?): TimeRangeFilter {
        val startTime = start?.let { java.time.Instant.ofEpochMilli(it.toEpochMilliseconds()) }
            ?: java.time.Instant.EPOCH
        val endTime = end?.let { java.time.Instant.ofEpochMilli(it.toEpochMilliseconds()) }
            ?: java.time.Instant.now()
        return TimeRangeFilter.between(startTime, endTime)
    }

    companion object {
        val READ_PERMISSIONS = setOf(
            ExerciseSessionRecord::class,
            MenstruationFlowRecord::class,
            HeartRateVariabilityRmssdRecord::class,
            SleepSessionRecord::class,
            RestingHeartRateRecord::class,
            ActiveCaloriesBurnedRecord::class,
        ).mapNotNull {
            try {
                androidx.health.connect.client.permission.HealthPermission.getReadPermission(it)
            } catch (_: Exception) { null }
        }.toSet()

        val WRITE_PERMISSIONS = setOf(
            ExerciseSessionRecord::class,
        ).mapNotNull {
            try {
                androidx.health.connect.client.permission.HealthPermission.getWritePermission(it)
            } catch (_: Exception) { null }
        }.toSet()
    }
}
