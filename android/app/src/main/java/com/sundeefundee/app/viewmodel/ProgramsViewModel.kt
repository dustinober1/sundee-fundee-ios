package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.data.factory.DataClientFactory
import com.sundeefundee.core.model.EnrolledProgramRecord
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ProgramsViewModel @Inject constructor(
    private val dataClientFactory: DataClientFactory
) : ViewModel() {

    private val _enrolledPrograms = MutableStateFlow<List<EnrolledProgramRecord>>(emptyList())
    val enrolledPrograms = _enrolledPrograms.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage = _errorMessage.asStateFlow()

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                _enrolledPrograms.value = dataClientFactory.client.fetchAll("EnrolledProgramRecord")
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
            _isLoading.value = false
        }
    }

    fun enroll(templateName: String) {
        viewModelScope.launch {
            val record = EnrolledProgramRecord(
                id = java.util.UUID.randomUUID().toString(),
                name = templateName,
                isActive = true
            )
            try {
                dataClientFactory.client.save(record, "EnrolledProgramRecord")
                loadData()
            } catch (e: Exception) {
                _errorMessage.value = e.message
            }
        }
    }
}
