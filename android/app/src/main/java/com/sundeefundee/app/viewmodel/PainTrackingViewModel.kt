package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.domain.injury.BodyRegion
import com.sundeefundee.core.domain.injury.InjuryAdaptationEngine
import com.sundeefundee.core.model.DailyPainLog
import com.sundeefundee.core.model.Injury
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PainTrackingViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory
) : ViewModel() {

    private val _painLogs = MutableStateFlow<List<DailyPainLog>>(emptyList())
    val painLogs = _painLogs.asStateFlow()

    private val _injuries = MutableStateFlow<List<Injury>>(emptyList())
    val injuries = _injuries.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    private val _selectedRegion = MutableStateFlow<String?>(null)
    val selectedRegion = _selectedRegion.asStateFlow()

    private val _painIntensity = MutableStateFlow(5)
    val painIntensity = _painIntensity.asStateFlow()

    private val _painType = MutableStateFlow("soreness")
    val painType = _painType.asStateFlow()

    private val _notes = MutableStateFlow("")
    val notes = _notes.asStateFlow()

    private val _substitutions = MutableStateFlow<List<String>>(emptyList())
    val substitutions = _substitutions.asStateFlow()

    val bodyRegions = BodyRegion.ALL

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _painLogs.value = dataClientFactory.client.fetchAll("DailyPainLog")
                _injuries.value = dataClientFactory.client.fetchAll("Injury")
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
            _isLoading.value = false
        }
    }

    fun selectRegion(region: String) {
        _selectedRegion.value = region
        updateSubstitutions()
    }

    fun setIntensity(intensity: Int) {
        _painIntensity.value = intensity
    }

    fun setPainType(type: String) {
        _painType.value = type
    }

    fun setNotes(text: String) {
        _notes.value = text
    }

    fun savePainLog() {
        viewModelScope.launch {
            val region = _selectedRegion.value ?: return@launch
            val log = DailyPainLog(
                id = java.util.UUID.randomUUID().toString(),
                bodyRegion = region,
                intensity = _painIntensity.value,
                painType = _painType.value,
                notes = _notes.value.ifBlank { null },
                date = kotlinx.datetime.Clock.System.now().toString()
            )
            try {
                dataClientFactory.client.save(log, "DailyPainLog")
                _selectedRegion.value = null
                _painIntensity.value = 5
                _notes.value = ""
                loadData()
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }

    fun saveInjury(name: String, region: String, notes: String?) {
        viewModelScope.launch {
            val injury = Injury(
                id = java.util.UUID.randomUUID().toString(),
                name = name,
                bodyRegion = region,
                notes = notes,
                dateOccurred = kotlinx.datetime.Clock.System.now().toString(),
                isActive = true
            )
            try {
                dataClientFactory.client.save(injury, "Injury")
                loadData()
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }

    private fun updateSubstitutions() {
        val region = _selectedRegion.value ?: return
        _substitutions.value = InjuryAdaptationEngine.getSubstitutionsForRegion(region)
    }
}
