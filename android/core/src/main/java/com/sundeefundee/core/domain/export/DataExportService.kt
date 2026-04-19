package com.sundeefundee.core.domain.export

import com.sundeefundee.core.domain.benchmark.BenchmarkResult
import com.sundeefundee.core.domain.injury.DailyPainLog
import com.sundeefundee.core.domain.injury.Injury
import com.sundeefundee.core.model.CelebrationEventRecord
import com.sundeefundee.core.model.CompletedWorkoutRecord
import com.sundeefundee.core.model.CyclePhaseInfo
import com.sundeefundee.core.model.CycleSettings
import com.sundeefundee.core.model.EnrolledProgramRecord
import com.sundeefundee.core.model.OneRepMaxRecord
import com.sundeefundee.core.model.Workout
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

// MARK: - ExportedData

/**
 * Top-level container for all user data exported from the app.
 *
 * Holds every record type the user has created, plus metadata about when
 * the export was produced and which app version generated it. All list
 * fields default to empty and [cycleSettings] defaults to null so that
 * an empty-state export is valid.
 */
@Serializable
data class ExportedData(
    /** Timestamp of when this export was generated (ISO8601). */
    val exportDate: String,
    /** App version that produced the export (e.g. "1.0.0"). */
    val appVersion: String,
    /** Saved workouts. */
    val workouts: List<Workout> = emptyList(),
    /** One-rep-max tracking records. */
    val oneRepMaxRecords: List<OneRepMaxRecord> = emptyList(),
    /** Completed workout history entries. */
    val completedWorkoutRecords: List<CompletedWorkoutRecord> = emptyList(),
    /** Menstrual cycle phase information. */
    val cyclePhaseInfo: List<CyclePhaseInfo> = emptyList(),
    /** Benchmark attempt results. */
    val benchmarkResults: List<BenchmarkResult> = emptyList(),
    /** Logged injuries and chronic conditions. */
    val injuries: List<Injury> = emptyList(),
    /** Daily pain log entries. */
    val painLogs: List<DailyPainLog> = emptyList(),
    /** Milestone celebration events. */
    val celebrations: List<CelebrationEventRecord> = emptyList(),
    /** Programs the user is enrolled in. */
    val enrolledPrograms: List<EnrolledProgramRecord> = emptyList(),
    /** User's cycle tracking settings (at most one record). */
    val cycleSettings: CycleSettings? = null
) {
    companion object {
        /** App version for exports. */
        private const val CURRENT_APP_VERSION = "1.0.0"

        /**
         * Creates an [ExportedData] instance with the current timestamp and app version.
         */
        fun current(): ExportedData {
            val now = Clock.System.now()
                .toLocalDateTime(TimeZone.currentSystemDefault())
                .toString()
            return ExportedData(
                exportDate = now,
                appVersion = CURRENT_APP_VERSION
            )
        }
    }

    /** A map of category names to record counts for summary display. */
    val categoryCounts: Map<String, Int>
        get() = mapOf(
            "Workouts" to workouts.size,
            "One Rep Maxes" to oneRepMaxRecords.size,
            "Completed Workouts" to completedWorkoutRecords.size,
            "Cycle Phases" to cyclePhaseInfo.size,
            "Benchmarks" to benchmarkResults.size,
            "Injuries" to injuries.size,
            "Pain Logs" to painLogs.size,
            "Celebrations" to celebrations.size,
            "Programs" to enrolledPrograms.size
        )
}

// MARK: - DataExportService

/**
 * Fetches all user record types in parallel and produces an [ExportedData] container.
 *
 * Each record type is fetched independently. If an individual fetch fails the
 * service logs the error and continues with an empty result for that type rather
 * than aborting the entire export.
 *
 * @param dataClient The data client used to fetch records. Expected to provide
 *   a `suspend fun <T> fetchAll(recordType: String): List<T>` method.
 */
class DataExportService(
    private val dataClient: DataExportClient
) {

    /**
     * Fetches all user record types in parallel and wraps them in an [ExportedData].
     *
     * Individual fetch failures are tolerated — the corresponding list will be
     * empty in the returned data. This ensures a partial export is still useful.
     */
    suspend fun exportAll(): ExportedData {
        // Fetch all record types concurrently, tolerating individual failures.
        val workouts = safeFetch<Workout>("Workout")
        val ormRecords = safeFetch<OneRepMaxRecord>("OneRepMaxRecord")
        val completedWorkouts = safeFetch<CompletedWorkoutRecord>("CompletedWorkoutRecord")
        val cyclePhases = safeFetch<CyclePhaseInfo>("CyclePhaseInfo")
        val cycleSettingsRecords = safeFetch<CycleSettings>("CycleSettings")
        val benchmarkResults = safeFetch<BenchmarkResult>("BenchmarkResult")
        val injuries = safeFetch<Injury>("Injury")
        val painLogs = safeFetch<DailyPainLog>("DailyPainLog")
        val celebrations = safeFetch<CelebrationEventRecord>("CelebrationEventRecord")
        val enrolledPrograms = safeFetch<EnrolledProgramRecord>("EnrolledProgramRecord")

        val now = Clock.System.now()
            .toLocalDateTime(TimeZone.currentSystemDefault())
            .toString()

        return ExportedData(
            exportDate = now,
            appVersion = "1.0.0",
            workouts = workouts,
            oneRepMaxRecords = ormRecords,
            completedWorkoutRecords = completedWorkouts,
            cyclePhaseInfo = cyclePhases,
            benchmarkResults = benchmarkResults,
            injuries = injuries,
            painLogs = painLogs,
            celebrations = celebrations,
            enrolledPrograms = enrolledPrograms,
            cycleSettings = cycleSettingsRecords.firstOrNull()
        )
    }

    /**
     * Encodes [ExportedData] to a JSON string with pretty-printed output.
     *
     * @param data The export data to encode.
     * @return JSON string.
     */
    fun encode(data: ExportedData): String {
        val json = Json {
            prettyPrint = true
            isLenient = true
            ignoreUnknownKeys = true
        }
        return json.encodeToString(data)
    }

    /**
     * Fetches all records of a given type, returning an empty list on failure.
     */
    private suspend inline fun <reified T> safeFetch(recordType: String): List<T> {
        return try {
            dataClient.fetchAll(recordType)
        } catch (e: Exception) {
            // Log but don't propagate — a partial export is better than none.
            emptyList()
        }
    }
}

/**
 * Client interface for fetching records during data export.
 * Implementations should provide deserialization from the persistence store.
 */
interface DataExportClient {
    suspend fun <T> fetchAll(recordType: String): List<T>
}
