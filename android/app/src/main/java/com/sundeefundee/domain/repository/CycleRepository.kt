package com.sundeefundee.domain.repository

import com.sundeefundee.domain.model.ActiveCycle
import com.sundeefundee.domain.model.CycleSettings
import com.sundeefundee.domain.model.PeriodLog
import kotlinx.coroutines.flow.Flow

interface CycleRepository {
    fun getCycleSettings(userId: String): Flow<CycleSettings?>
    fun getPeriodLogs(userId: String): Flow<List<PeriodLog>>
    fun getActiveCycle(userId: String): Flow<ActiveCycle?>
    suspend fun updateCycleSettings(settings: CycleSettings)
    suspend fun addPeriodLog(log: PeriodLog)
    suspend fun updateActiveCycle(cycle: ActiveCycle)
}
