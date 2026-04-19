package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.domain.exercise.epley1RM
import com.sundeefundee.core.domain.exercise.lbsToKg
import com.sundeefundee.core.domain.exercise.kgToLbs
import com.sundeefundee.core.model.OneRepMaxRecord
import com.sundeefundee.core.model.WeightUnit
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class MaxesViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory
) : ViewModel() {

    private val _maxes = MutableStateFlow<List<OneRepMaxRecord>>(emptyList())
    val maxes = _maxes.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    private val _unit = MutableStateFlow(WeightUnit.LBS)
    val unit = _unit.asStateFlow()

    fun loadMaxes() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _maxes.value = dataClientFactory.client.fetchAll("OneRepMaxRecord")
                    .sortedByDescending { it.date }
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
            _isLoading.value = false
        }
    }

    fun saveMax(exerciseName: String, weight: Double, reps: Int, unit: WeightUnit) {
        viewModelScope.launch {
            val estimated1RM = epley1RM(weight, reps)
            val record = OneRepMaxRecord(
                id = java.util.UUID.randomUUID().toString(),
                exerciseName = exerciseName,
                oneRepMax = estimated1RM,
                weight = weight,
                reps = reps,
                unit = unit,
                date = kotlinx.datetime.Clock.System.now().toString()
            )
            try {
                dataClientFactory.client.save(record, "OneRepMaxRecord")
                loadMaxes()
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }

    fun deleteMax(maxId: String) {
        viewModelScope.launch {
            try {
                dataClientFactory.client.delete(listOf(maxId), "OneRepMaxRecord")
                _maxes.value = _maxes.value.filter { it.id != maxId }
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }

    fun toggleUnit() {
        _unit.value = if (_unit.value == WeightUnit.LBS) WeightUnit.KG else WeightUnit.LBS
    }

    fun convertWeight(weight: Double): Double {
        return if (_unit.value == WeightUnit.KG) lbsToKg(weight) else weight
    }
}
