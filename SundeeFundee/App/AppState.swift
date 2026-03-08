import SwiftUI
import SwiftData

/// Top-level auth state that drives routing.
enum AuthState {
    case loading
    case signedOut
    case needsOnboarding(userID: String, appleUserID: String)
    case authenticated(userID: String)
    case guest
}

@Observable
@MainActor
final class AppState {
    var authState: AuthState = .loading
    var currentUserID: String?

    let authService = AuthService()

    func signInAsGuest() {
        authState = .guest
        currentUserID = nil
    }

    func signOut() {
        KeychainHelper.deleteAppleUserID()
        authState = .signedOut
        currentUserID = nil
    }

    func deleteAccountAndData(modelContext: ModelContext) {
        let allModelTypes: [any PersistentModel.Type] = AppSchemaV10.models
        for type in allModelTypes {
            try? modelContext.delete(model: type)
        }
        try? modelContext.save()
        KeychainHelper.deleteAppleUserID()
        UserDefaults.standard.removeObject(forKey: "com.sundeefundee.subscription.tier")
        UserDefaults.standard.removeObject(forKey: "dismissedPhaseTransitions")
        UserDefaults.standard.removeObject(forKey: "com.sundeefundee.ai.dataConsent")
        authState = .signedOut
        currentUserID = nil
    }

    func apply(_ state: AuthState) {
        authState = state
        if case .authenticated(let id) = state { currentUserID = id }
        else if case .needsOnboarding(let id, _) = state { currentUserID = id }
        else { currentUserID = nil }
    }
}
