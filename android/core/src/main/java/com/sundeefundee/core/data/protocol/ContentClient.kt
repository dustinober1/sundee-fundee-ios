package com.sundeefundee.core.data.protocol

import kotlinx.serialization.Serializable

// Content data interface — mirrors iOS ContentClientProtocol
interface ContentClient {
    suspend fun fetchExercises(): List<ContentExercise>
    suspend fun fetchPrograms(): List<ContentProgram>
    suspend fun fetchBenchmarks(): List<ContentBenchmark>
}

@Serializable
data class ContentExercise(
    val id: String,
    val name: String,
    val category: String,
    val muscleGroups: List<String> = emptyList(),
    val equipment: List<String> = emptyList(),
    val isWeightlifting: Boolean = true
)

@Serializable
data class ContentProgram(
    val id: String,
    val name: String,
    val category: String,
    val description: String,
    val durationWeeks: Int,
    val sessionsPerWeek: Int,
    val difficulty: String,
    val isFeatured: Boolean = false
)

@Serializable
data class ContentBenchmark(
    val id: String,
    val name: String,
    val category: String,
    val description: String,
    val scoringType: String,
    val intensity: Int,
    val equipment: List<String> = emptyList(),
    val timeDomain: String? = null,
    val movementTags: List<String> = emptyList(),
    val coachNotes: String? = null
)
