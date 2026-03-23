package com.sundeefundee.ui.features.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.data.remote.HealthConnectService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI State for Health Connect Settings screen
 */
data class HealthConnectUiState(
    val isLoading: Boolean = true,
    val availability: HealthConnectAvailabilityState = HealthConnectAvailabilityState.NOT_INSTALLED,
    val hasPermissions: Boolean = false,
    val syncWorkoutsEnabled: Boolean = true,
    val syncHeartRateEnabled: Boolean = true,
    val error: String? = null
)

/**
 * ViewModel for Health Connect settings screen.
 */
@HiltViewModel
class HealthConnectSettingsViewModel @Inject constructor(
    private val healthConnectService: HealthConnectService?
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(HealthConnectUiState())
    val uiState: StateFlow<HealthConnectUiState> = _uiState.asStateFlow()
    
    /**
     * Check if Health Connect is available and has permissions
     */
    fun checkAvailability() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            
            if (healthConnectService == null) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        availability = HealthConnectAvailabilityState.NOT_SUPPORTED
                    )
                }
                return@launch
            }
            
            try {
                val availability = when (healthConnectService.checkAvailability()) {
                    HealthConnectService.HealthConnectAvailability.INSTALLED -> 
                        HealthConnectAvailabilityState.INSTALLED
                    HealthConnectService.HealthConnectAvailability.NOT_INSTALLED -> 
                        HealthConnectAvailabilityState.NOT_INSTALLED
                    HealthConnectService.HealthConnectAvailability.NOT_SUPPORTED -> 
                        HealthConnectAvailabilityState.NOT_SUPPORTED
                }
                
                val hasPermissions = if (availability == HealthConnectAvailabilityState.INSTALLED) {
                    healthConnectService.hasAllPermissions()
                } else {
                    false
                }
                
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        availability = availability,
                        hasPermissions = hasPermissions
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message
                    )
                }
            }
        }
    }
    
    /**
     * Request Health Connect permissions
     */
    fun requestPermissions() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            
            if (healthConnectService == null) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = "Health Connect is not available"
                    )
                }
                return@launch
            }
            
            try {
                val result = healthConnectService.requestPermissions()
                result.fold(
                    onSuccess = { granted ->
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                hasPermissions = granted
                            )
                        }
                    },
                    onFailure = { e ->
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                error = e.message
                            )
                        }
                    }
                )
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message
                    )
                }
            }
        }
    }
    
    /**
     * Toggle workout syncing to Health Connect
     */
    fun setSyncWorkouts(enabled: Boolean) {
        _uiState.update { it.copy(syncWorkoutsEnabled = enabled) }
        // In a real app, persist this preference
    }
    
    /**
     * Toggle heart rate data reading
     */
    fun setSyncHeartRate(enabled: Boolean) {
        _uiState.update { it.copy(syncHeartRateEnabled = enabled) }
        // In a real app, persist this preference
    }
    
    /**
     * Clear error message
     */
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
