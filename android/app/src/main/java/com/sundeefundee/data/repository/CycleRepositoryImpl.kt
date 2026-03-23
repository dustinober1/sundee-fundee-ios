package com.sundeefundee.data.repository

import com.sundeefundee.data.local.ActiveCycleDao
import com.sundeefundee.data.local.ActiveCycleEntity
import com.sundeefundee.data.local.CycleSettingsDao
import com.sundeefundee.data.local.CycleSettingsEntity
import com.sundeefundee.data.local.PeriodLogDao
import com.sundeefundee.data.local.PeriodLogEntity
import com.sundeefundee.domain.model.ActiveCycle
import com.sundeefundee.domain.model.CycleSettings
import com.sundeefundee.domain.model.PeriodLog
import com.sundeefundee.domain.repository.CycleRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class CycleRepositoryImpl @Inject constructor(
    private val cycleSettingsDao: CycleSettingsDao,
    private val periodLogDao: PeriodLogDao,
    private val activeCycleDao: ActiveCycleDao
) : CycleRepository {

    override fun getCycleSettings(userId: String): Flow<CycleSettings?> {
        return cycleSettingsDao.getCycleSettingsForUser(userId).map { entity ->
            entity?.toDomain()
        }
    }

    override fun getPeriodLogs(userId: String): Flow<List<PeriodLog>> {
        return periodLogDao.getPeriodLogsForUser(userId).map { entities ->
            entities.map { it.toDomain() }
        }
    }

    override fun getActiveCycle(userId: String): Flow<ActiveCycle?> {
        return activeCycleDao.getActiveCycleForUser(userId).map { entity ->
            entity?.toDomain()
        }
    }

    override suspend fun updateCycleSettings(settings: CycleSettings) {
        cycleSettingsDao.insert(settings.toEntity())
    }

    override suspend fun addPeriodLog(log: PeriodLog) {
        periodLogDao.insert(log.toEntity())
    }

    override suspend fun updateActiveCycle(cycle: ActiveCycle) {
        activeCycleDao.insert(cycle.toEntity())
    }

    private fun CycleSettingsEntity.toDomain(): CycleSettings {
        return CycleSettings(
            id = id,
            odUserID = odUserID,
            averageCycleLength = averageCycleLength,
            averagePeriodLength = averagePeriodLength,
            lastPeriodStartDate = lastPeriodStartDate
        )
    }

    private fun CycleSettings.toEntity(): CycleSettingsEntity {
        return CycleSettingsEntity(
            id = id,
            odUserID = odUserID,
            averageCycleLength = averageCycleLength,
            averagePeriodLength = averagePeriodLength,
            lastPeriodStartDate = lastPeriodStartDate
        )
    }

    private fun PeriodLogEntity.toDomain(): PeriodLog {
        return PeriodLog(
            id = id,
            odUserID = odUserID,
            startDate = startDate,
            endDate = endDate,
            flowIntensityRaw = flowIntensityRaw
        )
    }

    private fun PeriodLog.toEntity(): PeriodLogEntity {
        return PeriodLogEntity(
            id = id,
            odUserID = odUserID,
            startDate = startDate,
            endDate = endDate,
            flowIntensityRaw = flowIntensityRaw
        )
    }

    private fun ActiveCycleEntity.toDomain(): ActiveCycle {
        return ActiveCycle(
            id = id,
            odUserID = odUserID,
            startDate = startDate,
            currentPhaseRaw = currentPhaseRaw,
            predictedEndDate = predictedEndDate
        )
    }

    private fun ActiveCycle.toEntity(): ActiveCycleEntity {
        return ActiveCycleEntity(
            id = id,
            odUserID = odUserID,
            startDate = startDate,
            currentPhaseRaw = currentPhaseRaw,
            predictedEndDate = predictedEndDate
        )
    }
}
