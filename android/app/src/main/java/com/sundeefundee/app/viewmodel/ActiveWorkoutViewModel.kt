package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.domain.exercise.epley1RM
import com.sundeefundee.core.domain.cycle.CycleAdaptationPolicy
import com.sundeefundee.core.model.CyclePhase
import com.sundeefundee.core.model.Exercise
import com.sundeefundee.core.model.ExerciseSet
import com.sundeefundee.core.model.Workout
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import javax.inject.Inject

@HiltViewModel
class ActiveWorkoutViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory
) : ViewModel() {

    private val _exercises = MutableStateFlow<List<Exercise>>(emptyList())
    val exercises = _exercises.asStateFlow()

    private val _currentExerciseIndex = MutableStateFlow(0)
    val currentExerciseIndex = _currentExerciseIndex.asStateFlow()

    private val _currentSetIndex = MutableStateFlow(0)
    val currentSetIndex = _currentSetIndex.asStateFlow()

    private val _isResting = MutableStateFlow(false)
    val isResting = _isResting.asStateFlow()

    private val _restTimeRemaining = MutableStateFlow(0)
    val restTimeRemaining = _restTimeRemaining.asStateFlow()

    private val _elapsedSeconds = MutableStateFlow(0)
    val elapsedSeconds = _elapsedSeconds.asStateFlow()

    private val _isComplete = MutableStateFlow(false)
    val isComplete = _isComplete.asStateFlow()

    private val _isPaused = MutableStateFlow(false)
    val isPaused = _isPaused.asStateFlow()

    private val _cyclePhase = MutableStateFlow<CyclePhase?>(null)
    val cyclePhase = _cyclePhase.asStateFlow()

    private val _personalRecords = MutableStateFlow<List<String>>(emptyList())
    val personalRecords = _personalRecords.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    private val _restDuration = MutableStateFlow(90)
    val restDuration = _restDuration.asStateFlow()

    private var startTime: Instant? = null
    private var elapsedJob: Job? = null
    private var restJob: Job? = null

    fun startWorkout(exerciseList: List<Exercise>, phase: CyclePhase? = null) {
        _exercises.value = exerciseList.map { exercise ->
            exercise.copy(sets = exercise.sets.map { set ->
                set.copy(completed = false, actualReps = null, actualWeight = null)
            })
        }
        _cyclePhase.value = phase
        _currentExerciseIndex.value = 0
        _currentSetIndex.value = 0
        _isComplete.value = false
        _isPaused.value = false
        _personalRecords.value = emptyList()
        startTime = Clock.System.now()
        startElapsedTime()
    }

    fun logSet(reps: Int, weight: Double) {
        val exercises = _exercises.value.toMutableList()
        val exIdx = _currentExerciseIndex.value
        val setIdx = _currentSetIndex.value

        if (exIdx >= exercises.size) return
        val exercise = exercises[exIdx]
        if (setIdx >= exercise.sets.size) return

        val currentSet = exercise.sets[setIdx]
        val adjustedWeight = _cyclePhase.value?.let {
            CycleAdaptationPolicy.adjustWeightByPhase(weight, it)
        } ?: weight

        val updatedSet = currentSet.copy(
            completed = true,
            actualReps = reps,
            actualWeight = adjustedWeight
        )

        val updatedSets = exercise.sets.toMutableList()
        updatedSets[setIdx] = updatedSet
        exercises[exIdx] = exercise.copy(sets = updatedSets)
        _exercises.value = exercises

        // Check for PR (simplified — compare to Epley 1RM)
        val estimated1RM = if (reps > 0) epley1RM(adjustedWeight, reps) else 0.0
        if (reps >= 1 && estimated1RM > 0) {
            // In a full implementation, compare against saved maxes
        }

        startRest()
        advanceToNext()
    }

    fun skipSet() {
        advanceToNext()
    }

    fun startRest() {
        _isResting.value = true
        _restTimeRemaining.value = _restDuration.value
        restJob?.cancel()
        restJob = viewModelScope.launch {
            while (_restTimeRemaining.value > 0 && isActive) {
                delay(1000)
                _restTimeRemaining.value -= 1
            }
            _isResting.value = false
        }
    }

    fun skipRest() {
        restJob?.cancel()
        _isResting.value = false
        _restTimeRemaining.value = 0
    }

    fun setRestDuration(seconds: Int) {
        _restDuration.value = seconds
    }

    fun togglePause() {
        _isPaused.value = !_isPaused.value
    }

    fun completeWorkout() {
        viewModelScope.launch {
            val now = Clock.System.now()
            val workout = Workout(
                id = java.util.UUID.randomUUID().toString(),
                exercises = _exercises.value,
                date = startTime?.toString() ?: now.toString(),
                completedAt = now.toString(),
                totalDuration = _elapsedSeconds.value
            )
            try {
                dataClientFactory.client.save(workout, "Workout")
                _isComplete.value = true
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }

    private fun advanceToNext() {
        val exercises = _exercises.value
        val exIdx = _currentExerciseIndex.value
        val setIdx = _currentSetIndex.value

        if (exIdx >= exercises.size) return
        val currentExercise = exercises[exIdx]

        if (setIdx + 1 < currentExercise.sets.size) {
            _currentSetIndex.value = setIdx + 1
        } else if (exIdx + 1 < exercises.size) {
            _currentExerciseIndex.value = exIdx + 1
            _currentSetIndex.value = 0
        } else {
            // All sets complete
            completeWorkout()
        }
    }

    private fun startElapsedTime() {
        elapsedJob?.cancel()
        elapsedJob = viewModelScope.launch {
            while (isActive) {
                if (!_isPaused.value) {
                    _elapsedSeconds.value += 1
                }
                delay(1000)
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        elapsedJob?.cancel()
        restJob?.cancel()
    }

    fun formatTime(seconds: Int): String {
        val mins = seconds / 60
        val secs = seconds % 60
        return String.format("%d:%02d", mins, secs)
    }

    fun formatElapsedTime(): String = formatTime(_elapsedSeconds.value)
}
