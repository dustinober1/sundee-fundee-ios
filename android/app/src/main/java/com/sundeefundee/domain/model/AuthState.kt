package com.sundeefundee.domain.model

sealed class AuthState {
    data object Loading : AuthState()
    data object SignedOut : AuthState()
    data object SignedIn : AuthState()
    data object Guest : AuthState()
}
