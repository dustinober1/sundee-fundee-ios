package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.data.factory.HealthClientFactory
import com.sundeefundee.core.data.protocol.DataClient
import com.sundeefundee.core.data.protocol.HealthClient
import com.sundeefundee.core.domain.challenge.ChallengeEngine
import com.sundeefundee.core.model.CelebrationEventRecord
import com.sundeefundee.core.model.Challenge
import com.sundeefundee.core.model.ChallengeProgress
import com.sundeefundee.core.model.CyclePhase
import com.sundeefundee.core.model.EnrolledProgramRecord
import com.sundeefundee.core.model.OneRepMaxRecord
import com.sundeefundee.core.model.Workout
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory,
    private val healthClientFactory: HealthClientFactory
) : ViewModel() {

    private val client: DataClient get() = dataClientFactory.client
    private val healthClient: HealthClient get() = healthClientFactory.client

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    private val _workoutsThisWeek = MutableStateFlow(0)
    val workoutsThisWeek = _workoutsThisWeek.asStateFlow()

    private val _prsThisMonth = MutableStateFlow(0)
    val prsThisMonth = _prsThisMonth.asStateFlow()

    private val _activeProgramName = MutableStateFlow<String?>(null)
    val activeProgramName = _activeProgramName.asStateFlow()

    private val _nextWorkout = MutableStateFlow<String?>(null)
    val nextWorkout = _nextWorkout.asStateFlow()

    private val _recentWins = MutableStateFlow<List<String>>(emptyList())
    val recentWins = _recentWins.asStateFlow()

    private val _insightsSummary = MutableStateFlow<String?>(null)
    val insightsSummary = _insightsSummary.asStateFlow()

    private val _insightsActions = MutableStateFlow<List<String>>(emptyList())
    val insightsActions = _insightsActions.asStateFlow()

    private val _activeChallengeData = MutableStateFlow<Pair<Challenge, ChallengeProgress>?>(null)
    val activeChallengeData = _activeChallengeData.asStateFlow()

    private val _cyclePhase = MutableStateFlow<CyclePhase?>(null)
    val cyclePhase = _cyclePhase.asStateFlow()

    private val _cycleConfidence = MutableStateFlow<Double?>(null)
    val cycleConfidence = _cycleConfidence.asStateFlow()

    private val _userName = MutableStateFlow("Athlete")
    val userName = _userName.asStateFlow()

    private var hasRequestedHealthAuth = false

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null

            if (!hasRequestedHealthAuth) {
                hasRequestedHealthAuth = true
                if (healthClient.isAvailable) {
                    try { healthClient.requestAuthorization() } catch (_: Exception) {}
                }
            }

            // Load critical data in parallel
            kotlinx.coroutines.coroutineScope {
                launch { loadStats() }
                launch { loadProgramInfo() }
                launch { loadRecentWins() }
                launch { loadCyclePhase() }
            }

            _isLoading.value = false

            // Non-critical loads
            loadActiveChallenge()
        }
    }

    private suspend fun loadStats() {
        try {
            val workouts: List<Workout> = client.fetchAll("Workout")
            _workoutsThisWeek.value = workouts.count { it.completedAt != null }
        } catch (_: Exception) {}

        try {
            val prs: List<OneRepMaxRecord> = client.fetchAll("OneRepMaxRecord")
            _prsThisMonth.value = prs.count { true } // simplified date filtering
        } catch (_: Exception) {}
    }

    private suspend fun loadProgramInfo() {
        try {
            val programs: List<EnrolledProgramRecord> = client.fetchAll("EnrolledProgramRecord")
            val active = programs.firstOrNull { it.isActive }
            if (active != null) {
                _activeProgramName.value = active.name
                _nextWorkout.value = "Day ${programs.size + 1}"
            }
        } catch (_: Exception) {}
    }

    private suspend fun loadRecentWins() {
        try {
            val wins: List<CelebrationEventRecord> = client.fetchAll("CelebrationEventRecord")
            _recentWins.value = wins.take(3).map { it.description.take(50) }
        } catch (_: Exception) {}
    }

    private suspend fun loadCyclePhase() {
        try {
            if (healthClient.isAvailable) {
                val cycles = healthClient.fetchMenstrualCycles(
                    startDate = null,
                    endDate = null,
                    limit = 100
                )
                if (cycles.isNotEmpty()) {
                    // Simplified phase calculation from last cycle
                    val lastCycle = cycles.last()
                    val daysSinceStart = (System.currentTimeMillis()
                        - lastCycle.startDate.toEpochMilliseconds()) / (1000 * 60 * 60 * 24)
                    _cyclePhase.value = when (daysSinceStart.toInt()) {
                        in 0..4 -> CyclePhase.MENSTRUAL
                        in 5..13 -> CyclePhase.FOLLICULAR
                        in 14..16 -> CyclePhase.OVULATION
                        else -> CyclePhase.LUTEAL
                    }
                    _cycleConfidence.value = if (daysSinceStart < 28) 0.8 else 0.4
                }
            }
        } catch (_: Exception) {}
    }

    private fun loadActiveChallenge() {
        viewModelScope.launch {
            try {
                val workouts: List<Workout> = client.fetchAll("Workout")
                val totalVolume = workouts.sumOf { it.totalVolume }
                val challenge = ChallengeEngine.createLifetimeChallenge()
                val updated = challenge.copy(accumulatedVolumeLbs = totalVolume)
                val progress = ChallengeEngine.computeProgress(updated)
                _activeChallengeData.value = challenge to progress
            } catch (_: Exception) {}
        }
    }

    fun setUserName(name: String?) {
        _userName.value = if (!name.isNullOrBlank()) name else "Athlete"
    }
}
