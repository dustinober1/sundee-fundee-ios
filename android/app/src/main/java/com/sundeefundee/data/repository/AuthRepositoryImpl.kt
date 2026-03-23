package com.sundeefundee.data.repository

import com.sundeefundee.data.remote.GoogleSignInResult
import com.sundeefundee.data.remote.GoogleSignInService
import com.sundeefundee.domain.model.AuthState
import com.sundeefundee.domain.model.User
import com.sundeefundee.domain.repository.AuthRepository
import com.sundeefundee.domain.repository.UserRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import java.util.UUID
import javax.inject.Inject

class AuthRepositoryImpl @Inject constructor(
    private val googleSignInService: GoogleSignInService,
    private val userRepository: UserRepository
) : AuthRepository {

    private val _authState = MutableStateFlow<AuthState>(AuthState.Loading)
    override val authState: Flow<AuthState> = _authState.asStateFlow()

    private val _currentUser = MutableStateFlow<User?>(null)
    override val currentUser: User?
        get() = _currentUser.value

    override val currentUserId: String?
        get() = _currentUser.value?.id

    override suspend fun signIn(): Result<User> {
        return try {
            val signInResult = googleSignInService.signIn()
            signInResult.fold(
                onSuccess = { googleResult ->
                    val user = getOrCreateUser(googleResult)
                    _currentUser.value = user
                    _authState.value = AuthState.SignedIn
                    Result.success(user)
                },
                onFailure = { error ->
                    _authState.value = AuthState.SignedOut
                    Result.failure(error)
                }
            )
        } catch (e: Exception) {
            _authState.value = AuthState.SignedOut
            Result.failure(e)
        }
    }

    override suspend fun signOut() {
        try {
            googleSignInService.signOut()
            _currentUser.value = null
            _authState.value = AuthState.SignedOut
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun restoreSession() {
        try {
            if (googleSignInService.isSignedIn()) {
                val result = googleSignInService.restorePreviousSignIn()
                result.fold(
                    onSuccess = { googleResult ->
                        val user = getOrCreateUser(googleResult)
                        _currentUser.value = user
                        _authState.value = AuthState.SignedIn
                    },
                    onFailure = {
                        _authState.value = AuthState.SignedOut
                    }
                )
            } else {
                _authState.value = AuthState.SignedOut
            }
        } catch (e: Exception) {
            _authState.value = AuthState.SignedOut
        }
    }

    override suspend fun enterGuestMode() {
        val guestUser = User(
            id = UUID.randomUUID().toString(),
            name = "Guest",
            experienceLevelRaw = "beginner",
            primaryGoalRaw = "general_fitness",
            genderRaw = "unspecified",
            weightUnitRaw = "lbs",
            googleUserID = "guest_${UUID.randomUUID()}",
            cycleTrackingEnabled = false,
            onboardingComplete = false,
            createdAt = System.currentTimeMillis(),
            profileUpdatedAt = null
        )
        _currentUser.value = guestUser
        _authState.value = AuthState.Guest
    }

    private suspend fun getOrCreateUser(googleResult: GoogleSignInResult): User {
        val existingUser = userRepository.getUserByGoogleId(googleResult.idToken).first()
        
        return existingUser ?: run {
            val newUser = User(
                id = UUID.randomUUID().toString(),
                name = googleResult.displayName ?: "User",
                experienceLevelRaw = "intermediate",
                primaryGoalRaw = "general_fitness",
                genderRaw = "unspecified",
                weightUnitRaw = "lbs",
                googleUserID = googleResult.idToken,
                cycleTrackingEnabled = false,
                onboardingComplete = false,
                createdAt = System.currentTimeMillis(),
                profileUpdatedAt = null
            )
            userRepository.createUser(newUser)
            newUser
        }
    }
}
