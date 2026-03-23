package com.sundeefundee.ui.features.cycle

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.domain.CyclePhase
import com.sundeefundee.domain.getPhaseRecommendation
import com.sundeefundee.domain.model.ActiveCycle
import com.sundeefundee.domain.model.CycleSettings
import com.sundeefundee.domain.model.PeriodLog
import com.sundeefundee.domain.repository.CycleRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

/**
 * UI State for the Cycle screen.
 */
data class CycleUiState(
    val isLoading: Boolean = true,
    val cycleSettings: CycleSettings? = null,
    val activeCycle: ActiveCycle? = null,
    val periodLogs: List<PeriodLog> = emptyList(),
    val currentPhase: CyclePhase = CyclePhase.FOLLICULAR,
    val phaseRecommendation: String = "",
    val cycleLength: Int = 28,
    val periodLength: Int = 5,
    val dayInPhase: Int = 1,
    val daysUntilNextPhase: Int = 0,
    val showLogPeriodDialog: Boolean = false,
    val showPhaseWarning: Boolean = false,
    val phaseWarningMessage: String? = null,
    val error: String? = null
)

/**
 * ViewModel for the Cycle screen.
 */
@HiltViewModel
class CycleViewModel @Inject constructor(
    private val cycleRepository: CycleRepository
) : ViewModel() {

    private val _userId = MutableStateFlow<String?>(null)
    private val _showLogPeriodDialog = MutableStateFlow(false)
    private val _showPhaseWarning = MutableStateFlow(false)
    private val _phaseWarningMessage = MutableStateFlow<String?>(null)
    private val _error = MutableStateFlow<String?>(null)

    // Cycle settings
    private val cycleSettings: StateFlow<CycleSettings?> = _userId
        .flatMapLatest { id ->
            if (id != null) {
                cycleRepository.getCycleSettings(id)
            } else {
                flowOf(null)
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    // Active cycle
    private val activeCycle: StateFlow<ActiveCycle?> = _userId
        .flatMapLatest { id ->
            if (id != null) {
                cycleRepository.getActiveCycle(id)
            } else {
                flowOf(null)
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    // Period logs
    private val periodLogs: StateFlow<List<PeriodLog>> = _userId
        .flatMapLatest { id ->
            if (id != null) {
                cycleRepository.getPeriodLogs(id)
            } else {
                flowOf(emptyList())
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Combined UI state
    val uiState: StateFlow<CycleUiState> = combine(
        cycleSettings,
        activeCycle,
        periodLogs,
        _showLogPeriodDialog,
        _showPhaseWarning,
        _phaseWarningMessage
    ) { settings, cycle, logs, showDialog, showWarning, warningMsg ->
        val phase = cycle?.currentPhaseRaw?.let {
            try { CyclePhase.valueOf(it.uppercase()) } catch (e: Exception) { CyclePhase.FOLLICULAR }
        } ?: CyclePhase.FOLLICULAR

        val cycleLength = settings?.cycleLengthRaw?.toIntOrNull() ?: 28
        val periodLength = settings?.periodLengthRaw?.toIntOrNull() ?: 5

        // Calculate day in phase
        val dayInPhase = cycle?.startDate?.let { startDate ->
            val daysSinceStart = ((System.currentTimeMillis() - startDate) / (24 * 60 * 60 * 1000)).toInt()
            val phaseLength = cycleLength / 4
            (daysSinceStart % phaseLength) + 1
        } ?: 1

        // Calculate days until next phase
        val daysUntilNextPhase = cycleLength - ((dayInPhase - 1) % (cycleLength / 4)) - (cycleLength / 4)

        CycleUiState(
            isLoading = false,
            cycleSettings = settings,
            activeCycle = cycle,
            periodLogs = logs.sortedByDescending { it.startDate },
            currentPhase = phase,
            phaseRecommendation = getPhaseRecommendation(phase),
            cycleLength = cycleLength,
            periodLength = periodLength,
            dayInPhase = dayInPhase,
            daysUntilNextPhase = daysUntilNextPhase,
            showLogPeriodDialog = showDialog,
            showPhaseWarning = showWarning,
            phaseWarningMessage = warningMsg,
            error = _error.value
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        CycleUiState()
    )

    /**
     * Sets the current user ID for data loading.
     */
    fun setUserId(id: String) {
        _userId.value = id
    }

    /**
     * Loads cycle data for the given user.
     */
    fun loadCycleData(userId: String) {
        _userId.value = userId
    }

    /**
     * Shows the log period dialog.
     */
    fun showLogPeriodDialog() {
        _showLogPeriodDialog.value = true
    }

    /**
     * Hides the log period dialog.
     */
    fun hideLogPeriodDialog() {
        _showLogPeriodDialog.value = false
    }

    /**
     * Logs a new period start.
     */
    fun logPeriod(startDate: Long, endDate: Long?, notes: String?) {
        val userId = _userId.value ?: return

        viewModelScope.launch {
            try {
                val log = PeriodLog(
                    id = UUID.randomUUID().toString(),
                    odUserID = userId,
                    startDate = startDate,
                    endDate = endDate,
                    notes = notes,
                    createdAt = System.currentTimeMillis()
                )
                cycleRepository.addPeriodLog(log)

                // Update active cycle
                val cycleSettings = cycleSettings.value
                val cycleLength = cycleSettings?.cycleLengthRaw?.toIntOrNull() ?: 28

                val newCycle = ActiveCycle(
                    id = activeCycle.value?.id ?: UUID.randomUUID().toString(),
                    odUserID = userId,
                    startDate = startDate,
                    currentPhaseRaw = CyclePhase.MENSTRUAL.name,
                    predictedEndDate = startDate + (cycleLength * 24 * 60 * 60 * 1000L)
                )
                cycleRepository.updateActiveCycle(newCycle)

                _showLogPeriodDialog.value = false
            } catch (e: Exception) {
                _error.value = "Failed to log period: ${e.message}"
            }
        }
    }

    /**
     * Updates cycle settings.
     */
    fun updateCycleSettings(cycleLength: Int, periodLength: Int) {
        val userId = _userId.value ?: return

        viewModelScope.launch {
            try {
                val currentSettings = cycleSettings.value
                val settings = CycleSettings(
                    odUserID = userId,
                    cycleLengthRaw = cycleLength.toString(),
                    periodLengthRaw = periodLength.toString(),
                    updatedAt = System.currentTimeMillis()
                )
                cycleRepository.updateCycleSettings(settings)
            } catch (e: Exception) {
                _error.value = "Failed to update settings: ${e.message}"
            }
        }
    }

    /**
     * Initializes cycle settings for a new user.
     */
    fun initializeCycleSettings(userId: String) {
        viewModelScope.launch {
            try {
                val settings = CycleSettings(
                    odUserID = userId,
                    cycleLengthRaw = "28",
                    periodLengthRaw = "5",
                    updatedAt = System.currentTimeMillis()
                )
                cycleRepository.updateCycleSettings(settings)
            } catch (e: Exception) {
                _error.value = "Failed to initialize settings: ${e.message}"
            }
        }
    }

    /**
     * Shows a phase transition warning.
     */
    fun showPhaseWarning(message: String) {
        _phaseWarningMessage.value = message
        _showPhaseWarning.value = true
    }

    /**
     * Hides the phase warning.
     */
    fun hidePhaseWarning() {
        _showPhaseWarning.value = false
        _phaseWarningMessage.value = null
    }

    /**
     * Clears any error state.
     */
    fun clearError() {
        _error.value = null
    }
}
