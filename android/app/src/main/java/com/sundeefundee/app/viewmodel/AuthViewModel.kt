package com.sundeefundee.app.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.core.auth.SessionManager
import com.sundeefundee.core.data.protocol.DataClient
import com.sundeefundee.core.model.UserSettings
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AuthState(
    val isAuthenticated: Boolean = false,
    val isGuest: Boolean = false,
    val needsOnboarding: Boolean = true,
    val isLoading: Boolean = false,
    val userName: String? = null,
    val error: String? = null
)

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _state = MutableStateFlow(AuthState())
    val state: StateFlow<AuthState> = _state.asStateFlow()

    init {
        checkExistingSession()
    }

    private fun checkExistingSession() {
        val userId = sessionManager.userId
        val isGuest = sessionManager.isGuest
        val isOnboarded = sessionManager.isOnboardingComplete

        when {
            isGuest -> {
                _state.value = AuthState(
                    isAuthenticated = true,
                    isGuest = true,
                    needsOnboarding = !isOnboarded,
                    userName = "Guest"
                )
            }
            userId != null -> {
                _state.value = AuthState(
                    isAuthenticated = true,
                    isGuest = false,
                    needsOnboarding = !isOnboarded,
                    userName = sessionManager.userName
                )
            }
            else -> {
                _state.value = AuthState(isAuthenticated = false, needsOnboarding = true)
            }
        }
    }

    fun onGoogleSignInSuccess(userId: String, email: String?, name: String?) {
        sessionManager.saveSession(userId, email, name)
        _state.value = AuthState(
            isAuthenticated = true,
            isGuest = false,
            needsOnboarding = !sessionManager.isOnboardingComplete,
            userName = name ?: email
        )
    }

    fun continueAsGuest() {
        sessionManager.saveGuestSession()
        _state.value = AuthState(
            isAuthenticated = true,
            isGuest = true,
            needsOnboarding = !sessionManager.isOnboardingComplete,
            userName = "Guest"
        )
    }

    fun completeOnboarding() {
        sessionManager.isOnboardingComplete = true
        _state.value = _state.value.copy(needsOnboarding = false)
    }

    fun signOut() {
        sessionManager.clearSession()
        _state.value = AuthState(isAuthenticated = false, needsOnboarding = true)
    }

    fun deleteAccount() {
        viewModelScope.launch {
            // TODO: Delete all data from Supabase/Room via DataClient
            sessionManager.clearSession()
            _state.value = AuthState(isAuthenticated = false, needsOnboarding = true)
        }
    }

    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
}
