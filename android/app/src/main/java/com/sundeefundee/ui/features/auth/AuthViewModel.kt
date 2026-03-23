package com.sundeefundee.ui.features.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sundeefundee.domain.model.AuthState
import com.sundeefundee.domain.model.User
import com.sundeefundee.domain.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    val authState: StateFlow<AuthState> = authRepository.authState
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), AuthState.Loading)

    val currentUser: StateFlow<User?> = kotlinx.coroutines.flow.flow {
        emit(authRepository.currentUser)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    fun signIn() {
        viewModelScope.launch {
            authRepository.signIn()
        }
    }

    fun signOut() {
        viewModelScope.launch {
            authRepository.signOut()
        }
    }

    fun enterGuestMode() {
        viewModelScope.launch {
            authRepository.enterGuestMode()
        }
    }

    fun restoreSession() {
        viewModelScope.launch {
            authRepository.restoreSession()
        }
    }
}
