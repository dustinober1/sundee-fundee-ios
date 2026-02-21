import AuthenticationServices
import Foundation
import SwiftData

enum AuthState {
    case loading
    case unauthenticated
    case needsOnboarding
    case authenticated
}

@Observable
final class AuthenticationViewModel {
    var authState: AuthState = .loading
    var errorMessage: String?
    private(set) var currentUser: User?

    private let keychainKey = "com.sundeefundee.appleUserID"

    func checkAuthState(context: ModelContext) {
        guard let storedUserID = KeychainHelper.load(key: keychainKey) else {
            authState = .unauthenticated
            return
        }

        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserID == storedUserID }
        )

        if let user = try? context.fetch(descriptor).first {
            currentUser = user
            authState = .authenticated
        } else {
            authState = .needsOnboarding
        }
    }

    func handleSignIn(result: Result<ASAuthorization, Error>, context: ModelContext) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Invalid credential type"
                return
            }

            let userID = credential.user
            KeychainHelper.save(key: keychainKey, value: userID)

            let descriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.appleUserID == userID }
            )

            if let existingUser = try? context.fetch(descriptor).first {
                currentUser = existingUser
                authState = .authenticated
            } else {
                authState = .needsOnboarding
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func completeOnboarding(
        name: String,
        experienceLevel: ExperienceLevel,
        primaryGoal: PrimaryGoal,
        gender: Gender,
        context: ModelContext
    ) {
        guard let appleUserID = KeychainHelper.load(key: keychainKey) else {
            errorMessage = "No Apple ID found. Please sign in again."
            authState = .unauthenticated
            return
        }

        let user = User(
            name: name,
            experienceLevel: experienceLevel,
            primaryGoal: primaryGoal,
            gender: gender,
            appleUserID: appleUserID
        )

        context.insert(user)
        try? context.save()
        currentUser = user
        authState = .authenticated
    }

    func signOut() {
        KeychainHelper.delete(key: keychainKey)
        currentUser = nil
        authState = .unauthenticated
    }
}
