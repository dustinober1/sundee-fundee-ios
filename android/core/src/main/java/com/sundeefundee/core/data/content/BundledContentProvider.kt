package com.sundeefundee.core.data.content

import com.sundeefundee.core.data.protocol.ContentBenchmark
import com.sundeefundee.core.data.protocol.ContentClient
import com.sundeefundee.core.data.protocol.ContentExercise
import com.sundeefundee.core.data.protocol.ContentProgram

// Hardcoded content fallback — mirrors iOS BundledContentProvider
class BundledContentProvider : ContentClient {

    override suspend fun fetchExercises(): List<ContentExercise> {
        return bundledExercises
    }

    override suspend fun fetchPrograms(): List<ContentProgram> {
        return bundledPrograms
    }

    override suspend fun fetchBenchmarks(): List<ContentBenchmark> {
        return bundledBenchmarks
    }

    companion object {
        // TODO: Port all 51 weightlifting + 31 conditioning exercises from iOS ExerciseCatalog (Phase 1)
        val bundledExercises = listOf<ContentExercise>()

        // TODO: Port 7 program templates from iOS ProgramTemplateGenerator (Phase 1)
        val bundledPrograms = listOf(
            ContentProgram(
                id = "first_margarita",
                name = "The First Margarita",
                category = "strength",
                description = "8-week progressive overload program designed for cycle-aware strength training",
                durationWeeks = 8,
                sessionsPerWeek = 3,
                difficulty = "intermediate",
                isFeatured = true
            )
        )

        // TODO: Port 30 benchmarks from iOS BenchmarkCatalog (Phase 1)
        val bundledBenchmarks = listOf<ContentBenchmark>()
    }
}
