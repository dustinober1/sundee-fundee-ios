package com.sundeefundee.data.repository

import com.sundeefundee.data.local.BenchmarkDao
import com.sundeefundee.data.local.BenchmarkDefinitionDao
import com.sundeefundee.data.local.BenchmarkDefinitionEntity
import com.sundeefundee.data.local.BenchmarkEntity
import com.sundeefundee.domain.model.Benchmark
import com.sundeefundee.domain.model.BenchmarkDefinition
import com.sundeefundee.domain.repository.BenchmarkRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class BenchmarkRepositoryImpl @Inject constructor(
    private val benchmarkDao: BenchmarkDao,
    private val benchmarkDefinitionDao: BenchmarkDefinitionDao
) : BenchmarkRepository {

    override fun getAllBenchmarks(): Flow<List<BenchmarkDefinition>> {
        return benchmarkDefinitionDao.getAllDefinitions().map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getBenchmarkById(id: String): Flow<BenchmarkDefinition?> {
        return benchmarkDefinitionDao.getDefinitionById(id).map { entity ->
            entity?.toDomain()
        }
    }

    override fun getUserBenchmarks(userId: String): Flow<List<Benchmark>> {
        return benchmarkDao.getBenchmarksForUser(userId).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getBenchmarkHistory(userId: String, benchmarkId: String): Flow<List<Benchmark>> {
        return benchmarkDao.getBenchmarksForDefinition(userId, benchmarkId).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override suspend fun logBenchmark(benchmark: Benchmark) {
        benchmarkDao.insert(benchmark.toEntity())
    }

    override suspend fun seedBenchmarksFromBundle() {
        // Implementation would load benchmarks from bundled JSON and insert them
        // This is a placeholder that would be implemented with actual data loading
    }

    private fun BenchmarkEntity.toDomain(): Benchmark {
        return Benchmark(
            id = id,
            odUserID = odUserID,
            benchmarkId = benchmarkId,
            score = score,
            achievedDate = achievedDate,
            notes = notes
        )
    }

    private fun Benchmark.toEntity(): BenchmarkEntity {
        return BenchmarkEntity(
            id = id,
            odUserID = odUserID,
            benchmarkId = benchmarkId,
            score = score,
            achievedDate = achievedDate,
            notes = notes
        )
    }

    private fun BenchmarkDefinitionEntity.toDomain(): BenchmarkDefinition {
        return BenchmarkDefinition(
            id = id,
            name = name,
            description = description,
            wodTypeRaw = wodTypeRaw,
            scoringTypeRaw = scoringTypeRaw,
            targetTime = targetTime,
            roundsAndReps = roundsAndReps,
            exercises = exercises,
            createdAt = createdAt
        )
    }
}
