package com.sundeefundee.data.repository

import com.sundeefundee.data.local.MaxDao
import com.sundeefundee.data.local.MaxEntity
import com.sundeefundee.domain.model.Max
import com.sundeefundee.domain.repository.MaxRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class MaxRepositoryImpl @Inject constructor(
    private val maxDao: MaxDao
) : MaxRepository {

    override fun getMaxesForUser(userId: String): Flow<List<Max>> {
        return maxDao.getMaxesForUser(userId).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getMaxByLiftName(userId: String, liftName: String): Flow<Max?> {
        return maxDao.getMaxByLiftName(userId, liftName).map { entity ->
            entity?.toDomain()
        }
    }

    override suspend fun upsertMax(max: Max) {
        maxDao.insert(max.toEntity())
    }

    override suspend fun deleteMax(max: Max) {
        maxDao.delete(max.toEntity())
    }

    private fun MaxEntity.toDomain(): Max {
        return Max(
            id = id,
            odUserID = odUserID,
            liftName = liftName,
            weight = weight,
            unitRaw = unitRaw,
            achievedDate = achievedDate,
            createdAt = createdAt
        )
    }

    private fun Max.toEntity(): MaxEntity {
        return MaxEntity(
            id = id,
            odUserID = odUserID,
            liftName = liftName,
            weight = weight,
            unitRaw = unitRaw,
            achievedDate = achievedDate,
            createdAt = createdAt
        )
    }
}
