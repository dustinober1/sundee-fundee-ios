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

    func apply(_ state: AuthState) {
        authState = state
        if case .authenticated(let id) = state { currentUserID = id }
        else if case .needsOnboarding(let id, _) = state { currentUserID = id }
        else { currentUserID = nil }
    }
}
