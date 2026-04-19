package com.sundeefundee.core.data.factory

import com.sundeefundee.core.data.healthconnect.HealthConnectClientWrapper
import com.sundeefundee.core.data.protocol.ActiveEnergyRecord
import com.sundeefundee.core.data.protocol.DataClient
import com.sundeefundee.core.data.protocol.HealthClient
import com.sundeefundee.core.data.protocol.HealthWorkout
import com.sundeefundee.core.data.protocol.HRVRecord
import com.sundeefundee.core.data.protocol.MenstrualCycleRecord
import com.sundeefundee.core.data.protocol.RestingHeartRateRecord
import com.sundeefundee.core.data.protocol.SleepRecord
import com.sundeefundee.core.data.room.RoomDataClient
import com.sundeefundee.core.data.room.SundeeFundeeDatabase
import com.sundeefundee.core.data.supabase.SupabaseDataClient
import com.sundeefundee.core.data.sync.NetworkMonitor
import com.sundeefundee.core.data.sync.SyncQueue
import kotlinx.datetime.Instant
import java.util.concurrent.atomic.AtomicReference
import javax.inject.Inject
import javax.inject.Singleton

// Thread-safe client factory — mirrors iOS DataClientFactory
@Singleton
class DataClientFactory @Inject constructor(
    private val roomDataClient: RoomDataClient,
    private val database: SundeeFundeeDatabase,
    private val supabaseDataClient: SupabaseDataClient,
    private val networkMonitor: NetworkMonitor
) {
    private val _client = AtomicReference<DataClient>(roomDataClient)

    val client: DataClient
        get() = _client.get()

    fun switchToAuthenticated() {
        _client.set(SyncQueue(supabaseDataClient, database.syncQueueDao(), networkMonitor))
    }

    fun switchToGuest() {
        _client.set(roomDataClient)
    }
}

@Singleton
class HealthClientFactory @Inject constructor(
    private val healthConnectClient: HealthConnectClientWrapper
) {
    val client: HealthClient
        get() = if (healthConnectClient.isAvailable) healthConnectClient else object : HealthClient {
            override val isAvailable = false
            override suspend fun requestAuthorization() {}
            override suspend fun fetchWorkouts(startDate: Instant?, endDate: Instant?, limit: Int) = emptyList<HealthWorkout>()
            override suspend fun fetchMenstrualCycles(startDate: Instant?, endDate: Instant?, limit: Int) = emptyList<MenstrualCycleRecord>()
            override suspend fun fetchActiveEnergy(startDate: Instant, endDate: Instant) = emptyList<ActiveEnergyRecord>()
            override suspend fun fetchHeartRateVariability(startDate: Instant, endDate: Instant) = emptyList<HRVRecord>()
            override suspend fun fetchRestingHeartRate(startDate: Instant, endDate: Instant) = emptyList<RestingHeartRateRecord>()
            override suspend fun fetchSleepAnalysis(startDate: Instant, endDate: Instant) = emptyList<SleepRecord>()
            override suspend fun saveWorkout(startDate: Instant, endDate: Instant, totalEnergyBurnedKcal: Double, exerciseNames: List<String>) {}
        }
}
