package com.sundeefundee.core.data.supabase

import com.sundeefundee.core.data.protocol.DataClient
import com.sundeefundee.core.data.protocol.Predicate
import com.sundeefundee.core.data.protocol.SortDescriptor
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import javax.inject.Inject
import javax.inject.Singleton

// Supabase-backed DataClient for authenticated users — mirrors iOS CloudKitClient
@Singleton
class SupabaseDataClient @Inject constructor(
    private val client: SupabaseClient
) : DataClient {

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    override suspend fun <T : Any> fetch(
        recordType: String,
        predicate: Predicate,
        sortDescriptors: List<SortDescriptor>?
    ): List<T> {
        val table = SupabaseSchema.recordTypeToTable[recordType] ?: return emptyList()
        val query = client.from(table).select()

        val result = query.decodeList<JsonObject>()

        @Suppress("UNCHECKED_CAST")
        return result.mapNotNull { row ->
            try {
                json.decodeFromString<JsonObject>(row.toString())
                // Deserialize to T via kotlinx.serialization
                json.decodeFromString<T>(row.toString())
            } catch (_: Exception) {
                null // skip corrupt records, mirrors iOS CloudKitClient
            }
        } as List<T>
    }

    override suspend fun <T : Any> fetchAll(
        recordType: String,
        sortDescriptors: List<SortDescriptor>?
    ): List<T> {
        return fetch(recordType, Predicate.all, sortDescriptors)
    }

    override suspend fun <T : Any> save(records: List<T>, recordType: String) {
        val table = SupabaseSchema.recordTypeToTable[recordType] ?: return
        for (record in records) {
            save(record, recordType)
        }
    }

    override suspend fun <T : Any> save(record: T, recordType: String) {
        val table = SupabaseSchema.recordTypeToTable[recordType] ?: return
        val jsonStr = serializeRecord(record)
        client.from(table).upsert(jsonStr)
    }

    override suspend fun delete(recordIds: List<String>, recordType: String) {
        val table = SupabaseSchema.recordTypeToTable[recordType] ?: return
        for (id in recordIds) {
            client.from(table).delete {
                filter { eq("id", id) }
            }
        }
    }

    override suspend fun deleteAllData() {
        val tables = SupabaseSchema.recordTypeToTable.values
        for (table in tables) {
            try {
                client.from(table).delete {}
            } catch (_: Exception) { /* skip tables that don't exist yet */ }
        }
    }

    override suspend fun saveFromJSON(jsonRecords: List<String>, recordType: String) {
        val table = SupabaseSchema.recordTypeToTable[recordType] ?: return
        for (jsonStr in jsonRecords) {
            try {
                client.from(table).upsert(jsonStr)
            } catch (_: Exception) { /* skip malformed records */ }
        }
    }

    companion object {
        /**
         * Serializes a record to JSON string.
         * Uses runtime serializer resolution via kotlinx.serialization.
         */
        private fun <T : Any> serializeRecord(record: T): String {
            // Use the Json instance to encode via reflection on the runtime class
            // All model types are @Serializable, so this works at runtime
            val jsonElement = Json.encodeToJsonElement(
                kotlinx.serialization.serializer(record::class.java),
                record
            )
            return jsonElement.toString()
        }
    }
}
