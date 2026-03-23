package com.sundeefundee.ui.features.settings

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.domain.model.User
import com.sundeefundee.domain.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalTime
import javax.inject.Inject

/**
 * UI State for the Settings screen.
 */
data class SettingsUiState(
    val isLoading: Boolean = true,
    val user: User? = null,
    val weightUnit: String = "lb",
    val cycleTrackingEnabled: Boolean = true,
    val workoutRemindersEnabled: Boolean = true,
    val cycleRemindersEnabled: Boolean = true,
    val marketingNotificationsEnabled: Boolean = false,
    val dailyReminderTime: LocalTime = LocalTime.of(9, 0),
    val showSignOutDialog: Boolean = false,
    val error: String? = null
)

/**
 * ViewModel for the Settings screen.
 */
@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val userRepository: UserRepository,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val prefs = context.getSharedPreferences("notification_settings", Context.MODE_PRIVATE)
    
    private val _userId = MutableStateFlow<String?>(null)
    private val _showSignOutDialog = MutableStateFlow(false)
    private val _error = MutableStateFlow<String?>(null)
    
    // Notification settings stored locally
    private val _workoutRemindersEnabled = MutableStateFlow(prefs.getBoolean(KEY_WORKOUT_REMINDERS, true))
    private val _cycleRemindersEnabled = MutableStateFlow(prefs.getBoolean(KEY_CYCLE_REMINDERS, true))
    private val _marketingNotificationsEnabled = MutableStateFlow(prefs.getBoolean(KEY_MARKETING, false))
    private val _dailyReminderTime = MutableStateFlow(
        LocalTime.of(
            prefs.getInt(KEY_DAILY_HOUR, 9),
            prefs.getInt(KEY_DAILY_MINUTE, 0)
        )
    )

    // User data
    private val user: StateFlow<User?> = _userId
        .flatMapLatest { id ->
            if (id != null) {
                userRepository.getUserById(id)
            } else {
                flowOf(null)
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    // UI state
    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = user
        .stateIn(
            viewModelScope,
            SharingStarted.WhileSubscribed(5000),
            null
        ).let { userFlow ->
            kotlinx.coroutines.flow.combine(
                userFlow,
                _showSignOutDialog,
                _workoutRemindersEnabled,
                _cycleRemindersEnabled,
                _marketingNotificationsEnabled,
                _dailyReminderTime
            ) { user, showDialog, workoutEnabled, cycleEnabled, marketingEnabled, reminderTime ->
                SettingsUiState(
                    isLoading = false,
                    user = user,
                    weightUnit = user?.weightUnitRaw ?: "lb",
                    cycleTrackingEnabled = user?.cycleTrackingEnabled ?: true,
                    workoutRemindersEnabled = workoutEnabled,
                    cycleRemindersEnabled = cycleEnabled,
                    marketingNotificationsEnabled = marketingEnabled,
                    dailyReminderTime = reminderTime,
                    showSignOutDialog = showDialog,
                    error = _error.value
                )
            }.stateIn(
                viewModelScope,
                SharingStarted.WhileSubscribed(5000),
                SettingsUiState()
            )
        }

    /**
     * Sets the current user ID for data loading.
     */
    fun setUserId(id: String) {
        _userId.value = id
    }

    /**
     * Loads settings for the given user.
     */
    fun loadSettings(userId: String) {
        _userId.value = userId
    }

    /**
     * Updates the weight unit preference.
     */
    fun updateWeightUnit(unit: String) {
        val currentUser = user.value ?: return

        viewModelScope.launch {
            try {
                val updatedUser = currentUser.copy(
                    weightUnitRaw = unit,
                    profileUpdatedAt = System.currentTimeMillis()
                )
                userRepository.updateUser(updatedUser)
            } catch (e: Exception) {
                _error.value = "Failed to update weight unit: ${e.message}"
            }
        }
    }

    /**
     * Updates cycle tracking preference.
     */
    fun updateCycleTrackingEnabled(enabled: Boolean) {
        val currentUser = user.value ?: return

        viewModelScope.launch {
            try {
                val updatedUser = currentUser.copy(
                    cycleTrackingEnabled = enabled,
                    profileUpdatedAt = System.currentTimeMillis()
                )
                userRepository.updateUser(updatedUser)
            } catch (e: Exception) {
                _error.value = "Failed to update cycle tracking: ${e.message}"
            }
        }
    }

    /**
     * Updates workout reminders preference.
     */
    fun updateWorkoutRemindersEnabled(enabled: Boolean) {
        viewModelScope.launch {
            prefs.edit().putBoolean(KEY_WORKOUT_REMINDERS, enabled).apply()
            _workoutRemindersEnabled.value = enabled
        }
    }

    /**
     * Updates cycle reminders preference.
     */
    fun updateCycleRemindersEnabled(enabled: Boolean) {
        viewModelScope.launch {
            prefs.edit().putBoolean(KEY_CYCLE_REMINDERS, enabled).apply()
            _cycleRemindersEnabled.value = enabled
        }
    }

    /**
     * Updates marketing notifications preference.
     */
    fun updateMarketingNotificationsEnabled(enabled: Boolean) {
        viewModelScope.launch {
            prefs.edit().putBoolean(KEY_MARKETING, enabled).apply()
            _marketingNotificationsEnabled.value = enabled
        }
    }

    /**
     * Updates daily reminder time.
     */
    fun updateDailyReminderTime(time: LocalTime) {
        viewModelScope.launch {
            prefs.edit()
                .putInt(KEY_DAILY_HOUR, time.hour)
                .putInt(KEY_DAILY_MINUTE, time.minute)
                .apply()
            _dailyReminderTime.value = time
        }
    }

    /**
     * Shows the sign out confirmation dialog.
     */
    fun showSignOutDialog() {
        _showSignOutDialog.value = true
    }

    /**
     * Hides the sign out confirmation dialog.
     */
    fun hideSignOutDialog() {
        _showSignOutDialog.value = false
    }

    /**
     * Signs out the user.
     */
    fun signOut(onSignedOut: () -> Unit) {
        viewModelScope.launch {
            try {
                hideSignOutDialog()
                onSignedOut()
            } catch (e: Exception) {
                _error.value = "Failed to sign out: ${e.message}"
            }
        }
    }

    /**
     * Clears any error state.
     */
    fun clearError() {
        _error.value = null
    }

    companion object {
        private const val KEY_WORKOUT_REMINDERS = "workout_reminders_enabled"
        private const val KEY_CYCLE_REMINDERS = "cycle_reminders_enabled"
        private const val KEY_MARKETING = "marketing_notifications_enabled"
        private const val KEY_DAILY_HOUR = "daily_reminder_hour"
        private const val KEY_DAILY_MINUTE = "daily_reminder_minute"
    }
}
