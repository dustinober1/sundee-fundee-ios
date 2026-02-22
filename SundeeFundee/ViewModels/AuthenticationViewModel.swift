import AuthenticationServices
import Foundation
import SwiftData

enum AuthState {
    case loading
    case unauthenticated
    case needsOnboarding
    case authenticated
    case guest
}

@Observable
final class AuthenticationViewModel {
    var authState: AuthState = .loading
    var errorMessage: String?
    private(set) var currentUser: User?

    private let keychainKey = "com.sundeefundee.appleUserID"
    private let guestModeKey = "com.sundeefundee.guestModeEnabled"

    func checkAuthState(context: ModelContext) {
        errorMessage = nil

        guard let storedUserID = KeychainHelper.load(key: keychainKey) else {
            currentUser = nil
            authState = UserDefaults.standard.bool(forKey: guestModeKey) ? .guest : .unauthenticated
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
            UserDefaults.standard.set(false, forKey: guestModeKey)
            errorMessage = nil

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

    func continueAsGuest() {
        KeychainHelper.delete(key: keychainKey)
        UserDefaults.standard.set(true, forKey: guestModeKey)
        currentUser = nil
        errorMessage = nil
        authState = .guest
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
        UserDefaults.standard.set(false, forKey: guestModeKey)
        currentUser = nil
        authState = .unauthenticated
    }
}
