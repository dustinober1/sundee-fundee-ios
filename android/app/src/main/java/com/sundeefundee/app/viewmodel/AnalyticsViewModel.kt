package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.domain.analytics.ChartDataAggregator
import com.sundeefundee.core.domain.analytics.TimeRange
import com.sundeefundee.core.model.CyclePhaseInfo
import com.sundeefundee.core.model.OneRepMaxRecord
import com.sundeefundee.core.model.Workout
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AnalyticsViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory
) : ViewModel() {

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    private val _selectedRange = MutableStateFlow(TimeRange.THREE_MONTHS)
    val selectedRange = _selectedRange.asStateFlow()

    private val _strengthData = MutableStateFlow<List<ChartDataAggregator.StrengthDataPoint>>(emptyList())
    val strengthData = _strengthData.asStateFlow()

    private val _volumeData = MutableStateFlow<List<ChartDataAggregator.VolumeDataPoint>>(emptyList())
    val volumeData = _volumeData.asStateFlow()

    private val _frequencyData = MutableStateFlow<List<ChartDataAggregator.FrequencyDataPoint>>(emptyList())
    val frequencyData = _frequencyData.asStateFlow()

    private val _selectedExercise = MutableStateFlow<String?>(null)
    val selectedExercise = _selectedExercise.asStateFlow()

    private val _exerciseNames = MutableStateFlow<List<String>>(emptyList())
    val exerciseNames = _exerciseNames.asStateFlow()

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val workouts: List<Workout> = dataClientFactory.client.fetchAll("Workout")
                val maxes: List<OneRepMaxRecord> = dataClientFactory.client.fetchAll("OneRepMaxRecord")

                _exerciseNames.value = workouts.flatMap { it.exercises.map { ex -> ex.name } }.distinct().sorted()

                _strengthData.value = ChartDataAggregator.strengthProgression(maxes, _selectedRange.value)
                _volumeData.value = ChartDataAggregator.trainingVolume(workouts, _selectedRange.value)
                _frequencyData.value = ChartDataAggregator.workoutFrequency(workouts, _selectedRange.value)
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
            _isLoading.value = false
        }
    }

    fun selectRange(range: TimeRange) {
        _selectedRange.value = range
        loadData()
    }

    fun selectExercise(name: String?) {
        _selectedExercise.value = name
    }
}
