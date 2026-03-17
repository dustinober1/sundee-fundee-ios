import Foundation
import AuthenticationServices
import SwiftData

protocol AppleIDCredentialProviding {
    var user: String { get }
    var fullName: PersonNameComponents? { get }
    var email: String? { get }
}

extension ASAuthorizationAppleIDCredential: AppleIDCredentialProviding {}

@MainActor
protocol AppleAuthorizationControlling: AnyObject {
    var delegate: ASAuthorizationControllerDelegate? { get set }
    var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding? { get set }
    func performRequests()
}

extension ASAuthorizationController: AppleAuthorizationControlling {}

/// Handles Sign in with Apple and session restoration.
///
/// This service is injected into the environment via AppState and called
/// from SignInView. On success it writes the user ID to the keychain and
/// updates AppState accordingly.
@MainActor
final class AuthService: NSObject, ObservableObject {

    struct AppleSignInCredential {
        let userID: String
        let fullName: PersonNameComponents?
        let email: String?
    }

    struct Dependencies {
        typealias AppleSignInPerformer = @MainActor (
            _ request: ASAuthorizationAppleIDRequest,
            _ presentationAnchor: ASPresentationAnchor,
            _ completion: @escaping (Result<AppleSignInCredential, Error>) -> Void
        ) -> AnyObject
        typealias AuthorizationControllerFactory = @MainActor ([ASAuthorizationRequest]) -> any AppleAuthorizationControlling

        @MainActor
        static var makeAuthorizationController: AuthorizationControllerFactory = { requests in
            ASAuthorizationController(authorizationRequests: requests)
        }

        let saveAppleUserID: (String) -> Void
        let loadAppleUserID: () -> String?
        let deleteAppleUserID: () -> Void
        let credentialStateForUserID: (String) async -> ASAuthorizationAppleIDProvider.CredentialState
        let makeUUID: () -> String
        let performAppleSignInRequest: AppleSignInPerformer

        init(
            saveAppleUserID: @escaping (String) -> Void,
            loadAppleUserID: @escaping () -> String?,
            deleteAppleUserID: @escaping () -> Void,
            credentialStateForUserID: @escaping (String) async -> ASAuthorizationAppleIDProvider.CredentialState,
            makeUUID: @escaping () -> String,
            performAppleSignInRequest: @escaping AppleSignInPerformer = Dependencies.defaultPerformAppleSignInRequest
        ) {
            self.saveAppleUserID = saveAppleUserID
            self.loadAppleUserID = loadAppleUserID
            self.deleteAppleUserID = deleteAppleUserID
            self.credentialStateForUserID = credentialStateForUserID
            self.makeUUID = makeUUID
            self.performAppleSignInRequest = performAppleSignInRequest
        }

        @MainActor
        private static func defaultPerformAppleSignInRequest(
            request: ASAuthorizationAppleIDRequest,
            presentationAnchor: ASPresentationAnchor,
            completion: @escaping (Result<AppleSignInCredential, Error>) -> Void
        ) -> AnyObject {
            let controller = makeAuthorizationController([request])
            let delegate = AppleSignInDelegate(
                presentationAnchor: presentationAnchor,
                completion: completion
            )
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
            return delegate
        }

        @MainActor static let live = Dependencies(
            saveAppleUserID: KeychainHelper.saveAppleUserID,
            loadAppleUserID: KeychainHelper.loadAppleUserID,
            deleteAppleUserID: KeychainHelper.deleteAppleUserID,
            credentialStateForUserID: { userID in
                (try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)) ?? .notFound
            },
            makeUUID: { UUID().uuidString }
        )
    }

    enum SessionRestorationAction: Equatable {
        case resolveAuthorized
        case signedOut(shouldDeleteStoredUserID: Bool)
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies = .live) {
        self.dependencies = dependencies
        super.init()
    }

    // MARK: - Public

    /// Process an ASAuthorizationAppleIDCredential obtained from SwiftUI's SignInWithAppleButton.
    func resolveAfterCredential(
        credential: any AppleIDCredentialProviding,
        modelContext: ModelContext
    ) async -> AuthState {
        await resolveAfterCredential(
            userID: credential.user,
            fullName: credential.fullName,
            email: credential.email,
            modelContext: modelContext
        )
    }

    @MainActor
    func resolveAfterCredential(
        userID: String,
        fullName: PersonNameComponents? = nil,
        email: String? = nil,
        modelContext: ModelContext
    ) async -> AuthState {
        await resolveAfterAppleSignIn(
            appleUserID: userID,
            fullName: fullName,
            email: email,
            modelContext: modelContext
        )
    }

    @MainActor
    func resolveAfterAppleSignIn(
        appleUserID: String,
        fullName: PersonNameComponents? = nil,
        email: String? = nil,
        modelContext: ModelContext
    ) async -> AuthState {
        dependencies.saveAppleUserID(appleUserID)
        return await resolveAuthState(
            appleUserID: appleUserID,
            fullName: fullName,
            email: email,
            modelContext: modelContext
        )
    }

    /// Attempt to restore the previous session from the keychain.
    /// Returns `.signedOut` if no stored credential or the credential was revoked.
    @MainActor
    func restoreSession(modelContext: ModelContext) async -> AuthState {
        guard let appleUserID = dependencies.loadAppleUserID() else {
            return .signedOut
        }

        switch Self.sessionRestorationAction(for: await dependencies.credentialStateForUserID(appleUserID)) {
        case .resolveAuthorized:
            return await resolveAuthState(appleUserID: appleUserID, modelContext: modelContext)
        case .signedOut(let shouldDeleteStoredUserID):
            if shouldDeleteStoredUserID {
                dependencies.deleteAppleUserID()
            }
            return .signedOut
        }
    }

    static func sessionRestorationAction(
        for credentialState: ASAuthorizationAppleIDProvider.CredentialState
    ) -> SessionRestorationAction {
        switch credentialState {
        case .authorized:
            return .resolveAuthorized
        case .revoked, .notFound, .transferred:
            return .signedOut(shouldDeleteStoredUserID: true)
        @unknown default:
            return .signedOut(shouldDeleteStoredUserID: false)
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
            self.pendingDelegate = dependencies.performAppleSignInRequest(
                request,
                presentationAnchor
            ) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let credential):
                    Task { @MainActor in
                        let state = await self.resolveAfterAppleSignIn(
                            appleUserID: credential.userID,
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
        }
    }

    // MARK: - Private

    private var pendingDelegate: AnyObject?

    /// Look up or create a User record and return the appropriate AuthState.
    @MainActor
    func resolveAuthState(
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
            return Self.authState(for: user, appleUserID: appleUserID)
        }

        // New user: create a stub record and send to onboarding.
        let userID = dependencies.makeUUID()
        let displayName = Self.displayName(from: fullName)

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

    static func authState(for user: User, appleUserID: String) -> AuthState {
        user.onboardingComplete
            ? .authenticated(userID: user.id)
            : .needsOnboarding(userID: user.id, appleUserID: appleUserID)
    }

    static func displayName(from fullName: PersonNameComponents?) -> String {
        [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

// MARK: - Delegate

final class AppleSignInDelegate: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private let presentationAnchor: ASPresentationAnchor
    let completion: (Result<AuthService.AppleSignInCredential, Error>) -> Void

    init(
        presentationAnchor: ASPresentationAnchor,
        completion: @escaping (Result<AuthService.AppleSignInCredential, Error>) -> Void
    ) {
        self.presentationAnchor = presentationAnchor
        self.completion = completion
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentationAnchor
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? any AppleIDCredentialProviding else {
            completion(.failure(AuthError.invalidCredential))
            return
        }
        completion(.success(.init(
            userID: credential.user,
            fullName: credential.fullName,
            email: credential.email
        )))
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
