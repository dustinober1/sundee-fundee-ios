import AuthenticationServices
import Foundation

// MARK: - AppleAuthClientProtocol

/// Protocol defining Sign in with Apple authentication operations.
///
/// Implementations handle user authentication via Apple ID, credential state
/// checking, and sign-out functionality.
///
/// ## Example Usage
/// ```swift
/// let result = try await authClient.signIn(scopes: [.email, .fullName])
/// let state = try await authClient.getCredentialState(forUserID: result.userID)
/// ```
public protocol AppleAuthClientProtocol: Sendable {
    /// Signs in the user with Apple ID.
    ///
    /// - Parameter scopes: The authorization scopes to request (defaults to email and full name).
    /// - Returns: The authentication result containing user information.
    /// - Throws: `AuthError` if the sign-in fails.
    func signIn(scopes: AppleAuthScope) async throws -> AppleAuthResult

    /// Retrieves the credential state for a given user.
    ///
    /// - Parameter userID: The Apple user identifier.
    /// - Returns: The current state of the user's credential.
    /// - Throws: `AuthError` if the state check fails.
    func getCredentialState(forUserID userID: String) async throws -> AppleCredentialState

    /// Signs out the user.
    ///
    /// This method clears any stored credentials. Note that Sign in with Apple
    /// does not have a traditional sign-out; users revoke access via Settings.
    func signOut() async
}

// MARK: - AppleAuthClient

/// Thread-safe client for Sign in with Apple authentication.
///
/// `AppleAuthClient` is an actor that provides a safe, concurrent interface to
/// Apple's AuthenticationServices framework. It handles the authorization flow,
/// credential state checking, and user information extraction.
///
/// ## Thread Safety
/// As an actor, `AppleAuthClient` ensures all authentication operations are
/// serialized and thread-safe. Call methods from any queue or task without
/// worrying about data races.
///
/// ## Example Usage
/// ```swift
/// let authClient = AppleAuthClient()
///
/// // Sign in
/// let result = try await authClient.signIn(scopes: [.email, .fullName])
/// print("Signed in as: \(result.userID)")
///
/// // Check credential state at app launch
/// let state = try await authClient.getCredentialState(forUserID: storedUserID)
/// if state == .revoked {
///     // Show sign-in UI
/// }
/// ```
public actor AppleAuthClient: AppleAuthClientProtocol {
    // MARK: - Properties

    /// The presentation context provider for the authorization UI.
    private weak var presentationContextProvider: (any ASAuthorizationControllerPresentationContextProviding)?

    /// Delegate proxy that handles authorization callbacks.
    private var delegateProxy: AuthorizationDelegateProxy?

    // MARK: - Initialization

    /// Creates a new `AppleAuthClient`.
    ///
    /// - Parameter presentationContextProvider: An optional presentation context provider
    ///   for the authorization UI. If not set, the client will attempt to find a suitable
    ///   presentation context automatically.
    public init(presentationContextProvider: (any ASAuthorizationControllerPresentationContextProviding)? = nil) {
        self.presentationContextProvider = presentationContextProvider
    }

    // MARK: - Configuration

    /// Sets the presentation context provider for authorization UI.
    ///
    /// - Parameter provider: The provider that supplies the window for presenting
    ///   the Sign in with Apple UI.
    public func setPresentationContextProvider(_ provider: any ASAuthorizationControllerPresentationContextProviding) {
        self.presentationContextProvider = provider
    }

    // MARK: - AppleAuthClientProtocol

    /// Signs in the user with Apple ID.
    ///
    /// This method presents the Sign in with Apple UI and waits for the user to
    /// complete authentication. The returned `AppleAuthResult` contains the user's
    /// information and tokens for backend verification.
    ///
    /// - Parameter scopes: The authorization scopes to request (defaults to email and full name).
    /// - Returns: The authentication result containing user information.
    /// - Throws: `AuthError` if the sign-in fails or is cancelled.
    public func signIn(scopes: AppleAuthScope = .all) async throws -> AppleAuthResult {
        let provider = ASAuthorizationAppleIDProvider()
        // Create the authorization request
        let request = provider.createRequest()

        // Map scopes to ASAuthorization.Scope
        var requestedScopes: [ASAuthorization.Scope] = []
        if scopes.contains(.email) {
            requestedScopes.append(.email)
        }
        if scopes.contains(.fullName) {
            requestedScopes.append(.fullName)
        }
        request.requestedScopes = requestedScopes

        // Create the authorization controller
        let controller = ASAuthorizationController(authorizationRequests: [request])

        // Create and configure the delegate proxy on MainActor
        let delegateProxy = await AuthorizationDelegateProxy()
        self.delegateProxy = delegateProxy

        controller.delegate = delegateProxy

        // Set presentation context if available
        if let presentationContextProvider = presentationContextProvider {
            controller.presentationContextProvider = presentationContextProvider
        }

        // Perform the authorization with async/await
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                delegateProxy.setContinuation(continuation)
            }
            controller.performRequests()
        }
    }

    /// Retrieves the credential state for a given user.
    ///
    /// Use this method at app launch to check if the user's authorization is still
    /// valid. If the state is `.revoked` or `.notFound`, you should show the sign-in UI.
    ///
    /// - Parameter userID: The Apple user identifier obtained from a previous sign-in.
    /// - Returns: The current state of the user's credential.
    /// - Throws: `AuthError.credentialStateCheckFailed` if the check fails.
    public func getCredentialState(forUserID userID: String) async throws -> AppleCredentialState {
        let provider = ASAuthorizationAppleIDProvider()
        return try await withCheckedThrowingContinuation { continuation in
            provider.getCredentialState(forUserID: userID) { state, error in
                if let error = error {
                    continuation.resume(throwing: AuthError.credentialStateCheckFailed(underlying: error))
                    return
                }

                let credentialState: AppleCredentialState
                switch state {
                case .authorized:
                    credentialState = .authorized
                case .revoked:
                    credentialState = .revoked
                case .notFound:
                    credentialState = .notFound
                case .transferred:
                    credentialState = .transferred
                @unknown default:
                    credentialState = .notFound
                }

                continuation.resume(returning: credentialState)
            }
        }
    }

    /// Signs out the user.
    ///
    /// This method clears any stored credentials in the client. Note that Sign in with Apple
    /// does not have a traditional sign-out mechanism; users must revoke access via
    /// Settings > Apple ID > Password & Security > Apps Using Your Apple ID.
    public func signOut() async {
        delegateProxy = nil
    }
}

// MARK: - AuthorizationDelegateProxy

/// A delegate proxy that bridges ASAuthorizationControllerDelegate callbacks to async/await.
///
/// This class is isolated to the MainActor to match ASAuthorizationControllerDelegate requirements.
@MainActor
private final class AuthorizationDelegateProxy: NSObject, ASAuthorizationControllerDelegate {
    // MARK: - Properties

    /// The continuation for the current authorization flow.
    private var continuation: CheckedContinuation<AppleAuthResult, Error>?

    // MARK: - Configuration

    /// Sets the continuation for the current authorization flow.
    func setContinuation(_ continuation: CheckedContinuation<AppleAuthResult, Error>) {
        self.continuation = continuation
    }

    // MARK: - ASAuthorizationControllerDelegate

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            Task { @MainActor in
                continuation?.resume(throwing: AuthError.authorizationFailed(underlying: nil))
                continuation = nil
            }
            return
        }

        // Extract scopes
        var authorizedScopes: AppleAuthScope = []
        for scope in appleIDCredential.authorizedScopes {
            if scope == .email {
                authorizedScopes.insert(.email)
            } else if scope == .fullName {
                authorizedScopes.insert(.fullName)
            }
        }

        let result = AppleAuthResult(
            userID: appleIDCredential.user,
            email: appleIDCredential.email,
            fullName: appleIDCredential.fullName,
            identityToken: appleIDCredential.identityToken,
            authorizationCode: appleIDCredential.authorizationCode,
            authorizedScopes: authorizedScopes
        )

        Task { @MainActor in
            continuation?.resume(returning: result)
            continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let asError = error as? ASAuthorizationError
        let authError: AuthError

        if let asError = asError {
            switch asError.code {
            case .canceled:
                authError = .cancelled
            case .failed, .unknown:
                authError = .authorizationFailed(underlying: error)
            case .invalidResponse:
                authError = .invalidIdentityToken
            case .notHandled:
                authError = .noPresentationContext
            case .notInteractive:
                authError = .notAvailable
            case .matchedExcludedCredential,
                 .credentialImport,
                 .credentialExport,
                 .preferSignInWithApple,
                 .deviceNotConfiguredForPasskeyCreation:
                authError = .authorizationFailed(underlying: error)
            @unknown default:
                authError = .authorizationFailed(underlying: error)
            }
        } else {
            authError = .authorizationFailed(underlying: error)
        }

        Task { @MainActor in
            continuation?.resume(throwing: authError)
            continuation = nil
        }
    }
}

// MARK: - Notification Extensions

extension AppleAuthClient {
    /// The notification name for credential revocation.
    ///
    /// Observe this notification to detect when the user revokes their
    /// Sign in with Apple credentials outside your app.
    public static var credentialRevokedNotification: Notification.Name {
        ASAuthorizationAppleIDProvider.credentialRevokedNotification
    }
}
