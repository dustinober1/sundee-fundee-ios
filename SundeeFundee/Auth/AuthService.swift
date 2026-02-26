import Foundation
import AuthenticationServices
import SwiftData

/// Handles Sign in with Apple and session restoration.
///
/// This service is injected into the environment via AppState and called
/// from SignInView. On success it writes the user ID to the keychain and
/// updates AppState accordingly.
@MainActor
final class AuthService: NSObject, ObservableObject {

    // MARK: - Public

    /// Process an ASAuthorizationAppleIDCredential obtained from SwiftUI's SignInWithAppleButton.
    func resolveAfterCredential(
        credential: ASAuthorizationAppleIDCredential,
        modelContext: ModelContext
    ) async -> AuthState {
        KeychainHelper.saveAppleUserID(credential.user)
        return await resolveAuthState(
            appleUserID: credential.user,
            fullName: credential.fullName,
            email: credential.email,
            modelContext: modelContext
        )
    }

    /// Attempt to restore the previous session from the keychain.
    /// Returns `.signedOut` if no stored credential or the credential was revoked.
    func restoreSession(modelContext: ModelContext) async -> AuthState {
        guard let appleUserID = KeychainHelper.loadAppleUserID() else {
            return .signedOut
        }

        // Check the credential is still valid with Apple.
        let state = (try? await ASAuthorizationAppleIDProvider()
            .credentialState(forUserID: appleUserID)) ?? .notFound
        switch state {
        case .authorized:
            return await resolveAuthState(appleUserID: appleUserID, modelContext: modelContext)
        case .revoked, .notFound:
            KeychainHelper.deleteAppleUserID()
            return .signedOut
        case .transferred:
            // Treat transferred as signedOut for now; handle migration if needed later.
            KeychainHelper.deleteAppleUserID()
            return .signedOut
        @unknown default:
            return .signedOut
        }
    }

    /// Trigger the Sign in with Apple sheet.
    func signInWithApple(
        presentationAnchor: ASPresentationAnchor,
        modelContext: ModelContext
    ) async throws -> AuthState {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        return try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate(
                presentationAnchor: presentationAnchor,
                modelContext: modelContext,
                completion: { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let credential):
                        Task { @MainActor in
                            KeychainHelper.saveAppleUserID(credential.user)
                            let state = await self.resolveAuthState(
                                appleUserID: credential.user,
                                fullName: credential.fullName,
                                email: credential.email,
                                modelContext: modelContext
                            )
                            continuation.resume(returning: state)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
            // Retain delegate for the duration of the request
            self.pendingDelegate = delegate
        }
    }

    // MARK: - Private

    private var pendingDelegate: AppleSignInDelegate?

    /// Look up or create a User record and return the appropriate AuthState.
    private func resolveAuthState(
        appleUserID: String,
        fullName: PersonNameComponents? = nil,
        email: String? = nil,
        modelContext: ModelContext
    ) async -> AuthState {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserID == appleUserID }
        )
        let existing = try? modelContext.fetch(descriptor)

        if let user = existing?.first {
            return user.onboardingComplete
                ? .authenticated(userID: user.id)
                : .needsOnboarding(userID: user.id, appleUserID: appleUserID)
        }

        // New user: create a stub record and send to onboarding.
        let userID = UUID().uuidString
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        let newUser = User(
            id: userID,
            name: displayName,
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            appleUserID: appleUserID,
            onboardingComplete: false
        )
        modelContext.insert(newUser)
        try? modelContext.save()

        return .needsOnboarding(userID: userID, appleUserID: appleUserID)
    }
}

// MARK: - Delegate

private final class AppleSignInDelegate: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private let presentationAnchor: ASPresentationAnchor
    private let modelContext: ModelContext
    let completion: (Result<ASAuthorizationAppleIDCredential, Error>) -> Void

    init(
        presentationAnchor: ASPresentationAnchor,
        modelContext: ModelContext,
        completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void
    ) {
        self.presentationAnchor = presentationAnchor
        self.modelContext = modelContext
        self.completion = completion
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentationAnchor
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion(.failure(AuthError.invalidCredential))
            return
        }
        completion(.success(credential))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        completion(.failure(error))
    }
}

enum AuthError: LocalizedError {
    case invalidCredential
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid Apple credential received."
        case .cancelled: return "Sign in was cancelled."
        }
    }
}
