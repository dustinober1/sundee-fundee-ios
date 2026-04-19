package com.sundeefundee.core.data.cache

import com.sundeefundee.core.model.CyclePhase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

// Shared cycle phase cache — mirrors iOS CyclePhaseCache
@Singleton
class CyclePhaseCache @Inject constructor() {
    private val _currentPhase = MutableStateFlow<CyclePhase?>(null)
    val currentPhase = _currentPhase.asStateFlow()

    private val _confidence = MutableStateFlow<Double?>(null)
    val confidence = _confidence.asStateFlow()

    private val _isSharkWeek = MutableStateFlow(false)
    val isSharkWeek = _isSharkWeek.asStateFlow()

    fun update(phase: CyclePhase?, confidence: Double?) {
        _currentPhase.value = phase
        _confidence.value = confidence
        _isSharkWeek.value = phase == CyclePhase.MENSTRUAL
    }

    fun clear() {
        _currentPhase.value = null
        _confidence.value = null
        _isSharkWeek.value = false
    }
}
