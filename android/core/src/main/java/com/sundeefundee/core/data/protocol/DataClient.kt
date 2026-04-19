package com.sundeefundee.core.data.protocol

import com.sundeefundee.core.data.protocol.SortDescriptor

// Generic data persistence interface — mirrors iOS DataClientProtocol
interface DataClient {
    suspend fun <T> fetch(
        recordType: String,
        predicate: Predicate = Predicate.all,
        sortDescriptors: List<SortDescriptor>? = null
    ): List<T> where T : Any

    suspend fun <T> fetchAll(
        recordType: String,
        sortDescriptors: List<SortDescriptor>? = null
    ): List<T> where T : Any

    suspend fun <T> save(records: List<T>, recordType: String) where T : Any

    suspend fun <T> save(record: T, recordType: String) where T : Any

    suspend fun delete(recordIds: List<String>, recordType: String)

    suspend fun deleteAllData()

    suspend fun saveFromJSON(jsonRecords: List<String>, recordType: String)
}

data class Predicate private constructor(
    val field: String?,
    val operator: Operator?,
    val value: Any?,
    val compoundOperator: CompoundOperator?,
    val children: List<Predicate>?
) {
    enum class Operator { EQUAL, NOT_EQUAL, LESS_THAN, GREATER_THAN, LESS_THAN_OR_EQUAL, GREATER_THAN_OR_EQUAL }
    enum class CompoundOperator { AND, OR }

    companion object {
        val all = Predicate(field = null, operator = null, value = null, compoundOperator = null, children = null)

        fun equalTo(field: String, value: Any) = Predicate(field, Operator.EQUAL, value, null, null)
        fun notEqualTo(field: String, value: Any) = Predicate(field, Operator.NOT_EQUAL, value, null, null)
        fun lessThan(field: String, value: Any) = Predicate(field, Operator.LESS_THAN, value, null, null)
        fun greaterThan(field: String, value: Any) = Predicate(field, Operator.GREATER_THAN, value, null, null)
        fun lessThanOrEqual(field: String, value: Any) = Predicate(field, Operator.LESS_THAN_OR_EQUAL, value, null, null)
        fun greaterThanOrEqual(field: String, value: Any) = Predicate(field, Operator.GREATER_THAN_OR_EQUAL, value, null, null)

        fun and(vararg predicates: Predicate) = Predicate(null, null, null, CompoundOperator.AND, predicates.toList())
        fun or(vararg predicates: Predicate) = Predicate(null, null, null, CompoundOperator.OR, predicates.toList())
    }
}

data class SortDescriptor(
    val field: String,
    val ascending: Boolean = true
)
