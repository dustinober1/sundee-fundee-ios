package com.sundeefundee.domain.repository

import com.sundeefundee.domain.model.Max
import kotlinx.coroutines.flow.Flow

interface MaxRepository {
    fun getMaxesForUser(userId: String): Flow<List<Max>>
    fun getMaxByLiftName(userId: String, liftName: String): Flow<Max?>
    suspend fun upsertMax(max: Max)
    suspend fun deleteMax(max: Max)
}
