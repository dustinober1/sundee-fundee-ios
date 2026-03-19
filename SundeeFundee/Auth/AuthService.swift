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
        let loadGuestUserID: () -> String?
        let deleteGuestUserID: () -> Void
        let credentialStateForUserID: (String) async -> ASAuthorizationAppleIDProvider.CredentialState
        let makeUUID: () -> String
        let performAppleSignInRequest: AppleSignInPerformer

        init(
            saveAppleUserID: @escaping (String) -> Void,
            loadAppleUserID: @escaping () -> String?,
            deleteAppleUserID: @escaping () -> Void,
            loadGuestUserID: @escaping () -> String? = { nil },
            deleteGuestUserID: @escaping () -> Void = {},
            credentialStateForUserID: @escaping (String) async -> ASAuthorizationAppleIDProvider.CredentialState,
            makeUUID: @escaping () -> String,
            performAppleSignInRequest: @escaping AppleSignInPerformer = Dependencies.defaultPerformAppleSignInRequest
        ) {
            self.saveAppleUserID = saveAppleUserID
            self.loadAppleUserID = loadAppleUserID
            self.deleteAppleUserID = deleteAppleUserID
            self.loadGuestUserID = loadGuestUserID
            self.deleteGuestUserID = deleteGuestUserID
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
            loadGuestUserID: KeychainHelper.loadGuestUserID,
            deleteGuestUserID: KeychainHelper.deleteGuestUserID,
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
        // Migrate any guest-owned records to the Apple user ID (FIX-03).
        migrateGuestRecords(toAppleUserID: appleUserID, modelContext: modelContext)
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
            // Retry pending guest migration if interrupted on a previous launch (FIX-03).
            if UserDefaults.standard.bool(forKey: "guestMigrationPending") {
                migrateGuestRecords(toAppleUserID: appleUserID, modelContext: modelContext)
            }
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

    /// Batch-updates all SwiftData records owned by the guest UUID to the Apple user ID.
    ///
    /// Sets a `guestMigrationPending` flag before starting so that if the process is
    /// interrupted (crash, force-quit), `restoreSession` will retry on next launch.
    @MainActor
    private func migrateGuestRecords(toAppleUserID appleUserID: String, modelContext: ModelContext) {
        guard let guestUUID = dependencies.loadGuestUserID() else { return }
        guard guestUUID != appleUserID else { return }

        UserDefaults.standard.set(true, forKey: "guestMigrationPending")

        do {
            // Migrate all model types that carry a userID field.
            try migrateUserID(in: CompletedWorkout.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: CompletedSet.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: OneRepMax.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: PersonalRecord.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: LiftMax.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: PeriodLog.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: SymptomLog.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: BenchmarkResult.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: ConditioningPR.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: GeneratedWorkoutRecord.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: ActiveCycle.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: EnrolledProgram.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: InjuryProfile.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: BarbellPreset.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: ExerciseBarMapping.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: SharedWorkoutTemplateRecord.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)
            try migrateUserID(in: BenchmarkDefinition.self, from: guestUUID, to: appleUserID, keyPath: \.userID, context: modelContext)

            try modelContext.save()
            // Migration succeeded — clear pending flag and remove the guest UUID from Keychain.
            UserDefaults.standard.removeObject(forKey: "guestMigrationPending")
            dependencies.deleteGuestUserID()
        } catch {
            // Leave guestMigrationPending set so restoreSession retries on next launch.
            print("[AuthService] Guest migration failed, will retry: \(error)")
        }
    }

    /// Fetches all records of `ModelType` where the given KeyPath equals `fromID`, then updates each to `toID`.
    private func migrateUserID<ModelType: PersistentModel>(
        in _: ModelType.Type,
        from fromID: String,
        to toID: String,
        keyPath: ReferenceWritableKeyPath<ModelType, String>,
        context: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<ModelType>()
        let records = try context.fetch(descriptor)
        for record in records where record[keyPath: keyPath] == fromID {
            record[keyPath: keyPath] = toID
        }
    }

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
