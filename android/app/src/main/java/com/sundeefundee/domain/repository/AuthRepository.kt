package com.sundeefundee.domain.repository

import com.sundeefundee.domain.model.AuthState
import com.sundeefundee.domain.model.User
import kotlinx.coroutines.flow.Flow

interface AuthRepository {
    val authState: Flow<AuthState>
    val currentUserId: String?
    val currentUser: User?

    suspend fun signIn(): Result<User>
    suspend fun signOut()
    suspend fun restoreSession()
    suspend fun enterGuestMode()
}
