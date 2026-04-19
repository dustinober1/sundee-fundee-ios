package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.auth.SessionManager
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.domain.export.DataExportService
import com.sundeefundee.core.model.UserSettings
import com.sundeefundee.core.model.WeightUnit
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    private val _settings = MutableStateFlow(UserSettings())
    val settings = _settings.asStateFlow()

    private val _isExporting = MutableStateFlow(false)
    val isExporting = _isExporting.asStateFlow()

    private val _exportJson = MutableStateFlow<String?>(null)
    val exportJson = _exportJson.asStateFlow()

    private val _isSignedOut = MutableStateFlow(false)
    val isSignedOut = _isSignedOut.asStateFlow()

    fun loadSettings() {
        viewModelScope.launch {
            try {
                val allSettings: List<UserSettings> = dataClientFactory.client.fetchAll("UserSettings")
                _settings.value = allSettings.firstOrNull() ?: UserSettings()
            } catch (_: Exception) {}
        }
    }

    fun updateWeightUnit(unit: WeightUnit) {
        viewModelScope.launch {
            val updated = _settings.value.copy(weightUnit = unit)
            try {
                dataClientFactory.client.save(updated, "UserSettings")
                _settings.value = updated
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }

    fun exportData() {
        viewModelScope.launch {
            _isExporting.value = true
            try {
                val client = dataClientFactory.client
                val service = DataExportService(object : com.sundeefundee.core.domain.export.DataExportClient {
                    override suspend fun <T : Any> fetchAll(recordType: String): List<T> = client.fetchAll(recordType)
                })
                val exported = service.exportAll()
                _exportJson.value = exported
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
            _isExporting.value = false
        }
    }

    fun signOut() {
        viewModelScope.launch {
            dataClientFactory.switchToGuest()
            sessionManager.clearSession()
            _isSignedOut.value = true
        }
    }

    fun deleteAccount() {
        viewModelScope.launch {
            try {
                dataClientFactory.client.deleteAllData()
                sessionManager.clearSession()
                _isSignedOut.value = true
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }
}
