package com.sundeefundee.domain.repository

import com.sundeefundee.domain.model.Benchmark
import com.sundeefundee.domain.model.BenchmarkDefinition
import kotlinx.coroutines.flow.Flow

interface BenchmarkRepository {
    fun getAllBenchmarks(): Flow<List<BenchmarkDefinition>>
    fun getBenchmarkById(id: String): Flow<BenchmarkDefinition?>
    fun getUserBenchmarks(userId: String): Flow<List<Benchmark>>
    fun getBenchmarkHistory(userId: String, benchmarkId: String): Flow<List<Benchmark>>
    suspend fun logBenchmark(benchmark: Benchmark)
    suspend fun seedBenchmarksFromBundle()
}
