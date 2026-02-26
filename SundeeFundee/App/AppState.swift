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
final class AppState {
    var authState: AuthState = .loading
    var currentUserID: String?

    func signInAsGuest() {
        authState = .guest
        currentUserID = nil
    }

    func signOut() {
        authState = .signedOut
        currentUserID = nil
    }
}
