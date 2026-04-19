package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.model.Workout
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class WorkoutsViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory
) : ViewModel() {

    private val _workouts = MutableStateFlow<List<Workout>>(emptyList())
    val workouts = _workouts.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    fun loadWorkouts() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val workouts: List<Workout> = dataClientFactory.client.fetchAll("Workout")
                _workouts.value = workouts.sortedByDescending { it.completedAt ?: it.date }
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
            _isLoading.value = false
        }
    }

    fun deleteWorkout(workoutId: String) {
        viewModelScope.launch {
            try {
                dataClientFactory.client.delete(listOf(workoutId), "Workout")
                _workouts.value = _workouts.value.filter { it.id != workoutId }
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }
}
