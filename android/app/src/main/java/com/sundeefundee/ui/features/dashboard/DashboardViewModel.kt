package com.sundeefundee.ui.features.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.domain.CyclePhase
import com.sundeefundee.domain.getPhaseRecommendation
import com.sundeefundee.domain.model.ActiveCycle
import com.sundeefundee.domain.model.CompletedWorkout
import com.sundeefundee.domain.model.User
import com.sundeefundee.domain.repository.CycleRepository
import com.sundeefundee.domain.repository.UserRepository
import com.sundeefundee.domain.repository.WorkoutRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * UI State for the Dashboard screen.
 */
data class DashboardUiState(
    val isLoading: Boolean = true,
    val user: User? = null,
    val currentPhase: CyclePhase = CyclePhase.FOLLICULAR,
    val phaseRecommendation: String = "",
    val recentWorkouts: List<CompletedWorkout> = emptyList(),
    val todaysSuggestedWorkout: WorkoutSuggestion? = null,
    val weeklyWorkoutCount: Int = 0,
    val currentStreak: Int = 0,
    val cycleTrackingEnabled: Boolean = true,
    val error: String? = null
)

/**
 * Suggested workout for today.
 */
data class WorkoutSuggestion(
    val id: String,
    val name: String,
    val wodType: String,
    val estimatedDuration: Int?,
    val recommendation: String?
)

/**
 * ViewModel for the Dashboard screen.
 */
@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val workoutRepository: WorkoutRepository,
    private val cycleRepository: CycleRepository,
    private val userRepository: UserRepository
) : ViewModel() {

    private val _userId = MutableStateFlow<String?>(null)

    // Load user ID from auth state
    private val userId = _userId.asStateFlow()

    // Active cycle data
    private val activeCycle: StateFlow<ActiveCycle?> = userId
        .flatMapLatest { id ->
            if (id != null) {
                cycleRepository.getActiveCycle(id)
            } else {
                flowOf(null)
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    // Recent workouts (last 3)
    private val recentWorkouts: StateFlow<List<CompletedWorkout>> = userId
        .flatMapLatest { id ->
            if (id != null) {
                workoutRepository.getRecentWorkouts(id, 3)
            } else {
                flowOf(emptyList())
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // User data
    private val userData: StateFlow<User?> = userId
        .flatMapLatest { id ->
            if (id != null) {
                userRepository.getUserById(id)
            } else {
                flowOf(null)
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    // Weekly workout count
    private val weeklyWorkoutCount: StateFlow<Int> = userId
        .flatMapLatest { id ->
            if (id != null) {
                val now = System.currentTimeMillis()
                val weekAgo = now - (7 * 24 * 60 * 60 * 1000L)
                workoutRepository.getWorkoutsForDateRange(id, weekAgo, now)
                    .map { it.size }
            } else {
                flowOf(0)
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    // Combined UI state
    val uiState: StateFlow<DashboardUiState> = combine(
        userData,
        activeCycle,
        recentWorkouts,
        weeklyWorkoutCount
    ) { user, cycle, workouts, weeklyCount ->
        val phase = cycle?.currentPhaseRaw?.let {
            try { CyclePhase.valueOf(it.uppercase()) } catch (e: Exception) { CyclePhase.FOLLICULAR }
        } ?: CyclePhase.FOLLICULAR

        DashboardUiState(
            isLoading = false,
            user = user,
            currentPhase = phase,
            phaseRecommendation = getPhaseRecommendation(phase),
            recentWorkouts = workouts,
            todaysSuggestedWorkout = generateTodaysWorkout(phase),
            weeklyWorkoutCount = weeklyCount,
            currentStreak = calculateStreak(workouts),
            cycleTrackingEnabled = user?.cycleTrackingEnabled ?: true
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        DashboardUiState()
    )

    /**
     * Sets the current user ID for data loading.
     */
    fun setUserId(id: String) {
        _userId.value = id
    }

    /**
     * Loads dashboard data for the given user.
     */
    fun loadDashboardData(userId: String) {
        _userId.value = userId
    }

    /**
     * Refreshes dashboard data.
     */
    fun refresh() {
        _userId.value?.let { loadDashboardData(it) }
    }

    /**
     * Generates a suggested workout based on cycle phase.
     */
    private fun generateTodaysWorkout(phase: CyclePhase): WorkoutSuggestion {
        return when (phase) {
            CyclePhase.MENSTRUAL -> WorkoutSuggestion(
                id = "suggested_rest",
                name = "Recovery Day",
                wodType = "REST",
                estimatedDuration = 30,
                recommendation = "Gentle stretching and mobility work"
            )
            CyclePhase.FOLLICULAR -> WorkoutSuggestion(
                id = "suggested_strength",
                name = "Full Body Strength",
                wodType = "STRENGTH",
                estimatedDuration = 45,
                recommendation = "High energy workout - perfect for PRs!"
            )
            CyclePhase.OVULATION -> WorkoutSuggestion(
                id = "suggested_hitt",
                name = "Peak Performance HIIT",
                wodType = "AMRAP",
                estimatedDuration = 30,
                recommendation = "Your peak day - go all out!"
            )
            CyclePhase.LUTEAL -> WorkoutSuggestion(
                id = "suggested_moderate",
                name = "Moderate Circuit",
                wodType = "CIRCUIT",
                estimatedDuration = 35,
                recommendation = "Steady-state workout for today"
            )
        }
    }

    /**
     * Calculates the current workout streak.
     */
    private fun calculateStreak(workouts: List<CompletedWorkout>): Int {
        if (workouts.isEmpty()) return 0

        val sortedWorkouts = workouts.sortedByDescending { it.workoutDate }
        var streak = 0
        var currentDate = System.currentTimeMillis()
        val oneDayMs = 24 * 60 * 60 * 1000L

        for (workout in sortedWorkouts) {
            val daysDiff = (currentDate - workout.workoutDate) / oneDayMs
            if (daysDiff <= 1) {
                streak++
                currentDate = workout.workoutDate
            } else {
                break
            }
        }

        return streak
    }
}
