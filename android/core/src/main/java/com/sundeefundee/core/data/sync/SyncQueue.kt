package com.sundeefundee.core.data.sync

import com.sundeefundee.core.data.protocol.DataClient
import com.sundeefundee.core.data.protocol.Predicate
import com.sundeefundee.core.data.protocol.SortDescriptor
import com.sundeefundee.core.data.room.dao.SyncQueueDao
import com.sundeefundee.core.data.room.entity.PendingMutationEntity
import com.sundeefundee.core.data.supabase.SupabaseDataClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

// Offline mutation queue with auto-replay — mirrors iOS SyncQueue
@Singleton
class SyncQueue @Inject constructor(
    private val delegate: DataClient,
    private val syncQueueDao: SyncQueueDao,
    private val networkMonitor: NetworkMonitor
) : DataClient {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val maxAttempts = 10
    private val queueJson = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    init {
        scope.launch {
            networkMonitor.connectivityChanges.collect { connected ->
                if (connected) flushQueue()
            }
        }
    }

    override suspend fun <T : Any> fetch(
        recordType: String,
        predicate: Predicate,
        sortDescriptors: List<SortDescriptor>?
    ): List<T> = delegate.fetch(recordType, predicate, sortDescriptors)

    override suspend fun <T : Any> fetchAll(
        recordType: String,
        sortDescriptors: List<SortDescriptor>?
    ): List<T> = delegate.fetchAll(recordType, sortDescriptors)

    override suspend fun <T : Any> save(records: List<T>, recordType: String) {
        try {
            delegate.save(records, recordType)
        } catch (e: Exception) {
            for (record in records) {
                enqueueSave(record, recordType)
            }
        }
    }

    override suspend fun <T : Any> save(record: T, recordType: String) {
        try {
            delegate.save(record, recordType)
        } catch (e: Exception) {
            enqueueSave(record, recordType)
        }
    }

    override suspend fun delete(recordIds: List<String>, recordType: String) {
        try {
            delegate.delete(recordIds, recordType)
        } catch (e: Exception) {
            enqueueDelete(recordIds, recordType)
        }
    }

    override suspend fun deleteAllData() {
        delegate.deleteAllData()
    }

    override suspend fun saveFromJSON(jsonRecords: List<String>, recordType: String) {
        try {
            delegate.saveFromJSON(jsonRecords, recordType)
        } catch (e: Exception) {
            for (json in jsonRecords) {
                syncQueueDao.insert(
                    PendingMutationEntity(
                        recordType = recordType,
                        operation = "save",
                        encodedData = json,
                        recordIdsJson = null,
                        attempts = 0,
                        enqueuedAt = kotlinx.datetime.Clock.System.now().toString()
                    )
                )
            }
        }
    }

    @Suppress("UNCHECKED_CAST")
    private suspend fun <T : Any> enqueueSave(record: T, recordType: String) {
        val serializer = SupabaseDataClient.serializerFor(recordType)
        val jsonStr = if (serializer != null) {
            queueJson.encodeToString(serializer as kotlinx.serialization.KSerializer<T>, record)
        } else {
            // Fallback: use toString() for unknown types
            record.toString()
        }
        syncQueueDao.insert(
            PendingMutationEntity(
                recordType = recordType,
                operation = "save",
                encodedData = jsonStr,
                recordIdsJson = null,
                attempts = 0,
                enqueuedAt = kotlinx.datetime.Clock.System.now().toString()
            )
        )
    }

    private suspend fun enqueueDelete(recordIds: List<String>, recordType: String) {
        val jsonStr = queueJson.encodeToString(recordIds)
        syncQueueDao.insert(
            PendingMutationEntity(
                recordType = recordType,
                operation = "delete",
                encodedData = "",
                recordIdsJson = jsonStr,
                attempts = 0,
                enqueuedAt = kotlinx.datetime.Clock.System.now().toString()
            )
        )
    }

    suspend fun flushQueue() {
        val pending = syncQueueDao.getAll()
        for (mutation in pending) {
            try {
                when (mutation.operation) {
                    "save" -> delegate.saveFromJSON(listOf(mutation.encodedData), mutation.recordType)
                    "delete" -> {
                        val ids = mutation.recordIdsJson?.let {
                            queueJson.decodeFromString<List<String>>(it)
                        } ?: emptyList()
                        delegate.delete(ids, mutation.recordType)
                    }
                }
                syncQueueDao.deleteById(mutation.rowId)
            } catch (e: Exception) {
                val newAttempts = mutation.attempts + 1
                if (newAttempts >= maxAttempts) {
                    syncQueueDao.deleteById(mutation.rowId)
                } else {
                    syncQueueDao.updateAttempts(mutation.rowId, newAttempts)
                }
            }
        }
    }
}
