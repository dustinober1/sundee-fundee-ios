package com.sundeefundee.core.data.cache

import android.content.Context
import android.content.SharedPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

// Shared snapshot store for widget data — mirrors iOS SharedSnapshotStore
@Singleton
class SharedSnapshotStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences("widget_snapshots", Context.MODE_PRIVATE)
    }

    fun writeRecovery(total: Int, recommendation: String, presentInputCount: Int) {
        prefs.edit()
            .putInt("recovery_total", total)
            .putString("recovery_recommendation", recommendation)
            .putInt("recovery_input_count", presentInputCount)
            .putLong("recovery_captured_at", System.currentTimeMillis())
            .apply()
    }

    fun readRecovery(): RecoverySnapshot? {
        val total = prefs.getInt("recovery_total", -1)
        if (total < 0) return null
        return RecoverySnapshot(
            total = total,
            recommendation = prefs.getString("recovery_recommendation", "") ?: "",
            presentInputCount = prefs.getInt("recovery_input_count", 0),
            capturedAt = prefs.getLong("recovery_captured_at", 0)
        )
    }

    fun writeCyclePhase(phase: String, day: Int, cycleLength: Int) {
        prefs.edit()
            .putString("cycle_phase", phase)
            .putInt("cycle_day", day)
            .putInt("cycle_length", cycleLength)
            .putLong("cycle_captured_at", System.currentTimeMillis())
            .apply()
    }

    fun readCyclePhase(): CyclePhaseSnapshot? {
        val phase = prefs.getString("cycle_phase", null) ?: return null
        return CyclePhaseSnapshot(
            phase = phase,
            day = prefs.getInt("cycle_day", 0),
            cycleLength = prefs.getInt("cycle_length", 28),
            capturedAt = prefs.getLong("cycle_captured_at", 0)
        )
    }
}

data class RecoverySnapshot(
    val total: Int,
    val recommendation: String,
    val presentInputCount: Int,
    val capturedAt: Long
)

data class CyclePhaseSnapshot(
    val phase: String,
    val day: Int,
    val cycleLength: Int,
    val capturedAt: Long
)
