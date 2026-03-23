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
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI State for the Program Detail screen.
 */
data class ProgramDetailUiState(
    val isLoading: Boolean = true,
    val program: Program? = null,
    val enrollment: EnrolledProgram? = null,
    val error: String? = null
)

/**
 * ViewModel for the Program Detail screen.
 */
@HiltViewModel
class ProgramDetailViewModel @Inject constructor(
    private val programRepository: ProgramRepository
) : ViewModel() {

    private val _programId = MutableStateFlow<String?>(null)
    private val _userId = MutableStateFlow<String?>(null)
    private val _error = MutableStateFlow<String?>(null)

    // Program details
    private val program: StateFlow<Program?> = _programId
        .flatMapLatest { id ->
            if (id != null) {
                programRepository.getProgramById(id)
            } else {
                flowOf(null)
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    // User's enrollment in this program
    private val enrollment: StateFlow<EnrolledProgram?> = combine(
        _programId,
        _userId
    ) { programId, userId ->
        Pair(programId, userId)
    }.flatMapLatest { (programId, userId) ->
        if (programId != null && userId != null) {
            programRepository.getEnrollmentsForUser(userId).flatMapLatest { enrollments ->
                val enrollment = enrollments.find { it.programId == programId }
                flowOf(enrollment)
            }
        } else {
            flowOf(null)
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    // Combined UI state
    val uiState: StateFlow<ProgramDetailUiState> = combine(
        program,
        enrollment,
        _error
    ) { prog, enroll, error ->
        ProgramDetailUiState(
            isLoading = false,
            program = prog,
            enrollment = enroll,
            error = error
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        ProgramDetailUiState()
    )

    /**
     * Loads program details.
     */
    fun loadProgram(programId: String, userId: String) {
        _programId.value = programId
        _userId.value = userId
    }

    /**
     * Enrolls in the current program.
     */
    fun enrollInProgram() {
        val programId = _programId.value ?: return
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
     * Updates enrollment progress.
     */
    fun updateProgress(week: Int, day: Int, completedWorkouts: Int) {
        val currentEnrollment = enrollment.value ?: return

        viewModelScope.launch {
            try {
                val updated = currentEnrollment.copy(
                    currentWeek = week,
                    currentDay = day,
                    completedWorkouts = completedWorkouts
                )
                programRepository.updateEnrollment(updated)
            } catch (e: Exception) {
                _error.value = "Failed to update progress: ${e.message}"
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
