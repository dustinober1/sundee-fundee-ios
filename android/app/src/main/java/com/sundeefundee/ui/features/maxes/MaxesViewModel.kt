package com.sundeefundee.ui.features.maxes

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.domain.model.Max
import com.sundeefundee.domain.repository.MaxRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

/**
 * Standard lift names for CrossFit-style max tracking.
 */
val STANDARD_LIFTS = listOf(
    "Back Squat",
    "Bench Press",
    "Deadlift",
    "Overhead Press",
    "Clean",
    "Snatch",
    "Front Squat",
    "Push Press",
    "Thruster",
    "Muscle-Up"
)

/**
 * UI State for the Maxes screen.
 */
data class MaxesUiState(
    val isLoading: Boolean = true,
    val maxes: List<MaxWithLift> = emptyList(),
    val showAddMaxDialog: Boolean = false,
    val editingMax: Max? = null,
    val selectedLiftName: String = "",
    val weightUnit: String = "lb",
    val error: String? = null
)

/**
 * Max with associated lift name for display.
 */
data class MaxWithLift(
    val max: Max,
    val liftName: String,
    val isPR: Boolean = false
)

/**
 * ViewModel for the Maxes screen.
 */
@HiltViewModel
class MaxesViewModel @Inject constructor(
    private val maxRepository: MaxRepository
) : ViewModel() {

    private val _userId = MutableStateFlow<String?>(null)
    private val _showAddMaxDialog = MutableStateFlow(false)
    private val _editingMax = MutableStateFlow<Max?>(null)
    private val _selectedLiftName = MutableStateFlow("")
    private val _weightUnit = MutableStateFlow("lb")
    private val _error = MutableStateFlow<String?>(null)

    // User's maxes
    private val userMaxes: StateFlow<List<Max>> = _userId
        .flatMapLatest { id ->
            if (id != null) {
                maxRepository.getMaxesForUser(id)
            } else {
                flowOf(emptyList())
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Combined UI state
    val uiState: StateFlow<MaxesUiState> = userMaxes
        .map { maxes ->
            val maxesWithLifts = maxes.map { max ->
                MaxWithLift(
                    max = max,
                    liftName = max.liftName,
                    isPR = isPR(max, maxes)
                )
            }.sortedBy { it.liftName }

            MaxesUiState(
                isLoading = false,
                maxes = maxesWithLifts,
                showAddMaxDialog = _showAddMaxDialog.value,
                editingMax = _editingMax.value,
                selectedLiftName = _selectedLiftName.value,
                weightUnit = _weightUnit.value,
                error = _error.value
            )
        }.stateIn(
            viewModelScope,
            SharingStarted.WhileSubscribed(5000),
            MaxesUiState()
        )

    /**
     * Sets the current user ID for data loading.
     */
    fun setUserId(id: String) {
        _userId.value = id
    }

    /**
     * Loads maxes for the given user.
     */
    fun loadMaxes(userId: String, weightUnit: String = "lb") {
        _userId.value = userId
        _weightUnit.value = weightUnit
    }

    /**
     * Shows the add max dialog.
     */
    fun showAddMaxDialog(liftName: String = "") {
        _selectedLiftName.value = liftName
        _editingMax.value = null
        _showAddMaxDialog.value = true
    }

    /**
     * Shows the edit max dialog.
     */
    fun showEditMaxDialog(max: Max) {
        _editingMax.value = max
        _selectedLiftName.value = max.liftName
        _showAddMaxDialog.value = true
    }

    /**
     * Hides the add/edit max dialog.
     */
    fun hideAddMaxDialog() {
        _showAddMaxDialog.value = false
        _editingMax.value = null
        _selectedLiftName.value = ""
    }

    /**
     * Updates the selected lift name.
     */
    fun setSelectedLiftName(name: String) {
        _selectedLiftName.value = name
    }

    /**
     * Saves a max (create or update).
     */
    fun saveMax(weight: Double, unit: String) {
        val userId = _userId.value ?: return
        val liftName = _selectedLiftName.value
        if (liftName.isEmpty()) return

        viewModelScope.launch {
            try {
                val max = Max(
                    id = _editingMax.value?.id ?: UUID.randomUUID().toString(),
                    odUserID = userId,
                    liftName = liftName,
                    weight = weight,
                    unitRaw = unit,
                    achievedDate = System.currentTimeMillis(),
                    createdAt = _editingMax.value?.createdAt ?: System.currentTimeMillis()
                )
                maxRepository.upsertMax(max)
                hideAddMaxDialog()
            } catch (e: Exception) {
                _error.value = "Failed to save max: ${e.message}"
            }
        }
    }

    /**
     * Deletes a max.
     */
    fun deleteMax(max: Max) {
        viewModelScope.launch {
            try {
                maxRepository.deleteMax(max)
            } catch (e: Exception) {
                _error.value = "Failed to delete max: ${e.message}"
            }
        }
    }

    /**
     * Clears any error state.
     */
    fun clearError() {
        _error.value = null
    }

    /**
     * Determines if a max is a personal record.
     * For simplicity, the most recent max for each lift is considered a PR.
     */
    private fun isPR(max: Max, allMaxes: List<Max>): Boolean {
        val sameLiftMaxes = allMaxes.filter { it.liftName == max.liftName }
        if (sameLiftMaxes.isEmpty()) return false

        // Find the max with the highest weight
        val prMax = sameLiftMaxes.maxByOrNull {
            // Convert to common unit for comparison if needed
            it.weight
        }

        return prMax?.id == max.id
    }
}
