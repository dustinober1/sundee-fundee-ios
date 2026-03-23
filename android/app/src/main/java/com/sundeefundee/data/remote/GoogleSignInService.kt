package com.sundeefundee.data.remote

import android.content.Context
import androidx.activity.result.ActivityResultLauncher
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Task
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

data class GoogleSignInResult(
    val idToken: String,
    val displayName: String?,
    val email: String?
)

class GoogleSignInService(private val context: Context) {

    private val gso: GoogleSignInOptions = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
        .requestEmail()
        .requestIdToken(getWebClientId())
        .build()

    private val googleSignInClient: GoogleSignInClient = GoogleSignIn.getClient(context, gso)

    private var signInLauncher: ActivityResultLauncher<com.google.android.gms.common.api.Scope>? = null

    fun setSignInLauncher(launcher: ActivityResultLauncher<com.google.android.gms.common.api.Scope>) {
        signInLauncher = launcher
    }

    private fun getWebClientId(): String {
        // This should be configured via BuildConfig or resources
        // For now, return a placeholder - in production, use your actual web client ID
        return "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
    }

    suspend fun signIn(): Result<GoogleSignInResult> = suspendCancellableCoroutine { continuation ->
        val task = googleSignInClient.signInIntent
        val pendingTask = GoogleSignIn.getClient(context, gso).signInIntent

        try {
            googleSignInClient.silentSignIn().addOnSuccessListener { account ->
                val result = GoogleSignInResult(
                    idToken = account.idToken ?: "",
                    displayName = account.displayName,
                    email = account.email
                )
                continuation.resume(Result.success(result))
            }.addOnFailureListener { e ->
                // Silent sign-in failed, need to show UI
                continuation.resume(Result.failure(e))
            }
        } catch (e: ApiException) {
            continuation.resume(Result.failure(e))
        }
    }

    fun observeSignInResult(launcher: ActivityResultLauncher<com.google.android.gms.common.api.Scope>): Flow<Result<GoogleSignInResult>> = callbackFlow {
        signInLauncher = launcher

        val task = googleSignInClient.silentSignIn()
        if (task.isSuccessful) {
            val account = task.result
            val result = GoogleSignInResult(
                idToken = account.idToken ?: "",
                displayName = account.displayName,
                email = account.email
            )
            trySend(Result.success(result))
            close()
        } else {
            // Try to launch sign-in
            launcher.launch(com.google.android.gms.common.api.Scope("https://www.googleapis.com/auth/plus.login"))
        }

        awaitClose { }
    }

    suspend fun signInWithLauncher(): Result<GoogleSignInResult> = suspendCancellableCoroutine { continuation ->
        try {
            googleSignInClient.silentSignIn().addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    val account = task.result
                    val result = GoogleSignInResult(
                        idToken = account.idToken ?: "",
                        displayName = account.displayName,
                        email = account.email
                    )
                    continuation.resume(Result.success(result))
                } else {
                    continuation.resume(Result.failure(task.exception ?: Exception("Sign-in failed")))
                }
            }
        } catch (e: Exception) {
            continuation.resume(Result.failure(e))
        }
    }

    suspend fun signOut(): Result<Unit> = suspendCancellableCoroutine { continuation ->
        googleSignInClient.signOut()
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    continuation.resume(Result.success(Unit))
                } else {
                    continuation.resume(Result.failure(task.exception ?: Exception("Sign-out failed")))
                }
            }
    }

    suspend fun restorePreviousSignIn(): Result<GoogleSignInResult> = suspendCancellableCoroutine { continuation ->
        googleSignInClient.silentSignIn()
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    val account = task.result
                    val result = GoogleSignInResult(
                        idToken = account.idToken ?: "",
                        displayName = account.displayName,
                        email = account.email
                    )
                    continuation.resume(Result.success(result))
                } else {
                    continuation.resume(Result.failure(task.exception ?: Exception("No previous sign-in found")))
                }
            }
    }

    fun getSignedInUser(): GoogleSignInAccount? {
        return GoogleSignIn.getLastSignedInAccount(context)
    }

    fun isSignedIn(): Boolean {
        return getSignedInUser() != null
    }
}
