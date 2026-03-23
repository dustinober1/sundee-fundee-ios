package com.sundeefundee.ui.features.programs

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.domain.model.EnrolledProgram
import com.sundeefundee.domain.model.Program
import com.sundeefundee.domain.repository.ProgramRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI State for the Programs screen.
 */
data class ProgramsUiState(
    val isLoading: Boolean = true,
    val availablePrograms: List<Program> = emptyList(),
    val enrolledPrograms: List<EnrolledProgramWithProgram> = emptyList(),
    val selectedTab: Int = 0, // 0 = Available, 1 = Enrolled
    val error: String? = null
)

/**
 * Enrolled program with its associated program details.
 */
data class EnrolledProgramWithProgram(
    val enrollment: EnrolledProgram,
    val program: Program
)

/**
 * ViewModel for the Programs screen.
 */
@HiltViewModel
class ProgramsViewModel @Inject constructor(
    private val programRepository: ProgramRepository
) : ViewModel() {

    private val _userId = MutableStateFlow<String?>(null)
    private val _selectedTab = MutableStateFlow(0)
    private val _error = MutableStateFlow<String?>(null)

    val userId: StateFlow<String?> = _userId.asStateFlow()

    // All available programs
    private val allPrograms: StateFlow<List<Program>> = programRepository.getAllPrograms()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // User's enrolled programs
    private val enrolledPrograms: StateFlow<List<EnrolledProgram>> = _userId
        .flatMapLatest { id ->
            if (id != null) {
                programRepository.getEnrollmentsForUser(id)
            } else {
                flowOf(emptyList())
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Combined UI state
    val uiState: StateFlow<ProgramsUiState> = combine(
        allPrograms,
        enrolledPrograms,
        _selectedTab,
        _error
    ) { programs, enrollments, selectedTab, error ->
        val enrolledWithPrograms = enrollments.mapNotNull { enrollment ->
            val program = programs.find { it.id == enrollment.programId }
            if (program != null) {
                EnrolledProgramWithProgram(enrollment, program)
            } else null
        }

        ProgramsUiState(
            isLoading = false,
            availablePrograms = programs,
            enrolledPrograms = enrolledWithPrograms,
            selectedTab = selectedTab,
            error = error
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        ProgramsUiState()
    )

    /**
     * Sets the current user ID for data loading.
     */
    fun setUserId(id: String) {
        _userId.value = id
    }

    /**
     * Loads programs data.
     */
    fun loadPrograms(userId: String) {
        _userId.value = userId
        viewModelScope.launch {
            try {
                programRepository.seedProgramsFromBundle()
            } catch (e: Exception) {
                _error.value = "Failed to load programs: ${e.message}"
            }
        }
    }

    /**
     * Selects a tab.
     */
    fun selectTab(index: Int) {
        _selectedTab.value = index
    }

    /**
     * Enrolls in a program.
     */
    fun enrollInProgram(programId: String) {
        val userId = _userId.value ?: return
        viewModelScope.launch {
            try {
                val enrollment = EnrolledProgram(
                    id = "",
                    odUserID = userId,
                    programId = programId,
                    enrolledAt = System.currentTimeMillis(),
                    currentWeek = 1,
                    currentDay = 1,
                    completedWorkouts = 0,
                    isActive = true
                )
                programRepository.enrollInProgram(enrollment)
            } catch (e: Exception) {
                _error.value = "Failed to enroll: ${e.message}"
            }
        }
    }

    /**
     * Clears any error state.
     */
    fun clearError() {
        _error.value = null
    }
}
