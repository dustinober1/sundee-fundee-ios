package com.sundeefundee.core.auth

import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Task

// Auth client interface — mirrors iOS AppleAuthClientProtocol
interface AuthClient {
    suspend fun signIn(idToken: String): AuthResult
    suspend fun signOut()
    suspend fun revokeAccess()
    val isSignedIn: Boolean
}

data class AuthResult(
    val userId: String,
    val email: String?,
    val displayName: String?,
    val idToken: String?
)

sealed class AuthError : Exception() {
    data object Cancelled : AuthError() { override val message = "Sign in was cancelled" }
    data class NetworkError(override val message: String) : AuthError()
    data class InvalidToken(override val message: String) : AuthError()
    data class Unknown(override val message: String) : AuthError()
}

// Google Sign-In configuration
fun googleSignInOptions(serverClientId: String): GoogleSignInOptions =
    GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
        .requestIdToken(serverClientId)
        .requestEmail()
        .requestProfile()
        .build()

// Parse Google Sign-In result
fun parseSignInResult(task: Task<GoogleSignInAccount>): AuthResult {
    val account = task.getResult(ApiException::class.java)
        ?: throw AuthError.Unknown("No account returned")
    return AuthResult(
        userId = account.id ?: throw AuthError.Unknown("No user ID"),
        email = account.email,
        displayName = account.displayName,
        idToken = account.idToken
    )
}
