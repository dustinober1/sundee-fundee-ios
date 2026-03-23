package com.sundeefundee.ui.features.workouts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.domain.WodType
import com.sundeefundee.domain.model.CompletedWorkout
import com.sundeefundee.domain.model.GeneratedWorkoutRecord
import com.sundeefundee.domain.repository.WorkoutRepository
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
 * UI State for the Workouts screen.
 */
data class WorkoutsUiState(
    val isLoading: Boolean = true,
    val todaysWorkout: WorkoutSuggestion? = null,
    val workoutHistory: List<CompletedWorkout> = emptyList(),
    val isGeneratingWorkout: Boolean = false,
    val error: String? = null
)

/**
 * Workout suggestion for today.
 */
data class WorkoutSuggestion(
    val id: String,
    val name: String,
    val wodType: WodType,
    val estimatedDuration: Int?,
    val description: String?
)

/**
 * ViewModel for the Workouts screen.
 */
@HiltViewModel
class WorkoutsViewModel @Inject constructor(
    private val workoutRepository: WorkoutRepository
) : ViewModel() {

    private val _userId = MutableStateFlow<String?>(null)
    private val _isGeneratingWorkout = MutableStateFlow(false)
    private val _error = MutableStateFlow<String?>(null)

    // Workout history
    private val workoutHistory: StateFlow<List<CompletedWorkout>> = _userId
        .flatMapLatest { id ->
            if (id != null) {
                workoutRepository.getWorkoutsForUser(id)
                    .map { it.sortedByDescending { w -> w.workoutDate } }
            } else {
                flowOf(emptyList())
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Combined UI state
    val uiState: StateFlow<WorkoutsUiState> = workoutHistory
        .map { history ->
            val todaysWorkout = generateTodaysWorkout(history)
            WorkoutsUiState(
                isLoading = false,
                todaysWorkout = todaysWorkout,
                workoutHistory = history,
                isGeneratingWorkout = _isGeneratingWorkout.value,
                error = _error.value
            )
        }.stateIn(
            viewModelScope,
            SharingStarted.WhileSubscribed(5000),
            WorkoutsUiState()
        )

    /**
     * Sets the current user ID for data loading.
     */
    fun setUserId(id: String) {
        _userId.value = id
    }

    /**
     * Loads workouts for the given user.
     */
    fun loadWorkouts(userId: String) {
        _userId.value = userId
    }

    /**
     * Generates a new AI workout.
     */
    fun generateNewWorkout() {
        viewModelScope.launch {
            _isGeneratingWorkout.value = true
            try {
                // In a real app, this would call the Firebase Cloud Function
                // For now, we'll simulate a generated workout
                kotlinx.coroutines.delay(1500) // Simulate API call

                val generatedWorkout = WorkoutSuggestion(
                    id = "generated_${UUID.randomUUID()}",
                    name = "AI Generated WOD",
                    wodType = WodType.AMRAP,
                    estimatedDuration = 20,
                    description = "Custom workout based on your history and cycle phase"
                )

                // Store the generated workout record
                _userId.value?.let { userId ->
                    val record = GeneratedWorkoutRecord(
                        id = UUID.randomUUID().toString(),
                        odUserID = userId,
                        generatedAt = System.currentTimeMillis(),
                        contextJson = "{}",
                        resultJson = """{"name":"${generatedWorkout.name}","type":"${generatedWorkout.wodType}"}""",
                        usedForWorkout = false
                    )
                    // Would save this to repository
                }
            } catch (e: Exception) {
                _error.value = "Failed to generate workout: ${e.message}"
            } finally {
                _isGeneratingWorkout.value = false
            }
        }
    }

    /**
     * Logs a completed workout.
     */
    fun logCompletedWorkout(
        workoutName: String,
        wodType: WodType?,
        duration: Int,
        notes: String? = null,
        spicyRating: Int? = null
    ) {
        val userId = _userId.value ?: return

        viewModelScope.launch {
            try {
                val workout = CompletedWorkout(
                    id = UUID.randomUUID().toString(),
                    odUserID = userId,
                    workoutDate = System.currentTimeMillis(),
                    workoutName = workoutName,
                    programId = null,
                    wodTypeRaw = wodType?.name,
                    duration = duration,
                    totalVolume = null,
                    spicyRating = spicyRating,
                    notes = notes,
                    createdAt = System.currentTimeMillis()
                )
                workoutRepository.logWorkout(workout)
            } catch (e: Exception) {
                _error.value = "Failed to log workout: ${e.message}"
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
     * Generates today's workout suggestion based on history.
     */
    private fun generateTodaysWorkout(history: List<CompletedWorkout>): WorkoutSuggestion {
        // Check if there's a recent workout to base suggestion on
        val lastWorkoutType = history.firstOrNull()?.wodTypeRaw

        return WorkoutSuggestion(
            id = "todays_wod",
            name = "Daily WOD",
            wodType = WodType.AMRAP,
            estimatedDuration = 20,
            description = "Today's workout of the day"
        )
    }
}
