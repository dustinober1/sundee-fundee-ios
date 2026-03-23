package com.sundeefundee.ui.features.workouts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.domain.WodType
import com.sundeefundee.domain.model.CompletedWorkout
import com.sundeefundee.domain.repository.WorkoutRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

/**
 * UI State for the Workout Execution screen.
 */
data class WorkoutExecutionUiState(
    val isLoading: Boolean = true,
    val workoutId: String = "",
    val workoutName: String = "Daily WOD",
    val wodType: WodType = WodType.AMRAP,
    val exercises: List<ExerciseItem> = emptyList(),
    val currentExerciseIndex: Int = 0,
    val totalExercises: Int = 0,
    val isWorkoutActive: Boolean = false,
    val isPaused: Boolean = false,
    val elapsedTime: Int = 0, // in seconds
    val isResting: Boolean = false,
    val currentRestTime: Int = 0,
    val restDuration: Int = 60,
    val completedExercises: Set<Int> = emptySet(),
    val error: String? = null
)

/**
 * ViewModel for the Workout Execution screen.
 */
@HiltViewModel
class WorkoutExecutionViewModel @Inject constructor(
    private val workoutRepository: WorkoutRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(WorkoutExecutionUiState())
    val uiState: StateFlow<WorkoutExecutionUiState> = _uiState.asStateFlow()

    private var timerJob: Job? = null
    private var restTimerJob: Job? = null
    private var startTime: Long = 0
    private var pausedTime: Int = 0

    /**
     * Loads a workout by ID.
     */
    fun loadWorkout(workoutId: String) {
        _uiState.update { it.copy(isLoading = true, workoutId = workoutId) }

        viewModelScope.launch {
            // Simulate loading workout data
            // In a real app, this would fetch from repository or Cloud Function
            delay(500)

            // Generate sample exercises for demo
            val exercises = generateSampleExercises(workoutId)

            _uiState.update {
                it.copy(
                    isLoading = false,
                    workoutName = "Daily WOD",
                    wodType = WodType.AMRAP,
                    exercises = exercises,
                    totalExercises = exercises.size,
                    currentExerciseIndex = 0
                )
            }
        }
    }

    /**
     * Starts the workout timer.
     */
    fun startWorkout() {
        startTime = System.currentTimeMillis()
        _uiState.update { it.copy(isWorkoutActive = true, isPaused = false) }
        startTimer()
    }

    /**
     * Pauses the workout timer.
     */
    fun pauseWorkout() {
        pausedTime = _uiState.value.elapsedTime
        timerJob?.cancel()
        _uiState.update { it.copy(isPaused = true) }
    }

    /**
     * Resumes the workout timer.
     */
    fun resumeWorkout() {
        startTime = System.currentTimeMillis() - (pausedTime * 1000L)
        _uiState.update { it.copy(isPaused = false) }
        startTimer()
    }

    /**
     * Completes the current exercise and starts rest timer.
     */
    fun completeExercise(index: Int) {
        val exercise = _uiState.value.exercises.getOrNull(index) ?: return
        val restDuration = exercise.restSeconds

        _uiState.update {
            it.copy(
                completedExercises = it.completedExercises + index,
                currentExerciseIndex = index + 1,
                isResting = true,
                currentRestTime = restDuration,
                restDuration = restDuration
            )
        }

        startRestTimer(restDuration)
    }

    /**
     * Skips the rest timer.
     */
    fun skipRest() {
        restTimerJob?.cancel()
        _uiState.update { it.copy(isResting = false, currentRestTime = 0) }
    }

    /**
     * Completes the workout and saves it.
     */
    fun completeWorkout() {
        timerJob?.cancel()
        restTimerJob?.cancel()

        val state = _uiState.value
        val workout = CompletedWorkout(
            id = UUID.randomUUID().toString(),
            odUserID = "", // Would be set from auth
            workoutDate = System.currentTimeMillis(),
            workoutName = state.workoutName,
            programId = null,
            wodTypeRaw = state.wodType.name,
            duration = state.elapsedTime / 60, // Convert to minutes
            totalVolume = null,
            spicyRating = calculateSpicyRating(state.completedExercises.size, state.totalExercises),
            notes = null,
            createdAt = System.currentTimeMillis()
        )

        viewModelScope.launch {
            try {
                workoutRepository.logWorkout(workout)
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to save workout: ${e.message}") }
            }
        }
    }

    /**
     * Starts the main workout timer.
     */
    private fun startTimer() {
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
            while (true) {
                val elapsed = ((System.currentTimeMillis() - startTime) / 1000).toInt()
                _uiState.update { it.copy(elapsedTime = elapsed) }
                delay(1000)
            }
        }
    }

    /**
     * Starts the rest timer.
     */
    private fun startRestTimer(duration: Int) {
        restTimerJob?.cancel()
        restTimerJob = viewModelScope.launch {
            var remaining = duration
            while (remaining > 0) {
                _uiState.update { it.copy(currentRestTime = remaining) }
                delay(1000)
                remaining--
            }
            _uiState.update { it.copy(isResting = false, currentRestTime = 0) }
        }
    }

    /**
     * Calculates a "spicy rating" based on completion.
     */
    private fun calculateSpicyRating(completed: Int, total: Int): Int {
        if (total == 0) return 1
        val ratio = completed.toFloat() / total.toFloat()
        return when {
            ratio >= 1.0f -> 5
            ratio >= 0.8f -> 4
            ratio >= 0.6f -> 3
            ratio >= 0.4f -> 2
            else -> 1
        }
    }

    /**
     * Generates sample exercises for demo purposes.
     */
    private fun generateSampleExercises(workoutId: String): List<ExerciseItem> {
        return listOf(
            ExerciseItem(
                name = "Air Squats",
                sets = "3 sets",
                reps = "15 reps",
                restSeconds = 60
            ),
            ExerciseItem(
                name = "Push-ups",
                sets = "3 sets",
                reps = "12 reps",
                restSeconds = 60
            ),
            ExerciseItem(
                name = "Burpees",
                sets = "3 sets",
                reps = "10 reps",
                restSeconds = 90
            ),
            ExerciseItem(
                name = "Mountain Climbers",
                sets = "3 sets",
                reps = "20 reps",
                restSeconds = 45
            ),
            ExerciseItem(
                name = "Plank Hold",
                sets = "3 sets",
                reps = "45 seconds",
                restSeconds = 60
            ),
            ExerciseItem(
                name = "Jump Squats",
                sets = "3 sets",
                reps = "12 reps",
                restSeconds = 60
            )
        )
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        restTimerJob?.cancel()
    }
}
