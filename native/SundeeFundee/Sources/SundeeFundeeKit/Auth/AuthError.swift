import Foundation

// MARK: - AuthError

/// Errors that can occur during Sign in with Apple authentication.
///
/// `AuthError` provides detailed error cases for common authentication failures,
/// with localized descriptions and recovery suggestions for user-facing display.
public enum AuthError: Error, LocalizedError, Sendable {
    /// The user cancelled the authentication flow.
    case cancelled

    /// The authorization failed with an underlying error.
    case authorizationFailed(underlying: Error?)

    /// No authorization controller is available to present the sign-in UI.
    case noPresentationContext

    /// The credential state check failed.
    case credentialStateCheckFailed(underlying: Error?)

    /// The identity token could not be decoded.
    case invalidIdentityToken

    /// Required user information is missing from the credential.
    case missingUserInfo(field: String)

    /// Authorization is not available on this device.
    case notAvailable

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Sign in was cancelled."
        case .authorizationFailed(let underlying):
            if let underlying = underlying {
                return "Authorization failed: \(underlying.localizedDescription)"
            }
            return "Authorization failed."
        case .noPresentationContext:
            return "Unable to present sign in interface."
        case .credentialStateCheckFailed(let underlying):
            if let underlying = underlying {
                return "Failed to check credential state: \(underlying.localizedDescription)"
            }
            return "Failed to check credential state."
        case .invalidIdentityToken:
            return "Invalid identity token received from Apple."
        case .missingUserInfo(let field):
            return "Missing required user information: \(field)"
        case .notAvailable:
            return "Sign in with Apple is not available on this device."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .cancelled:
            return "Try signing in again when ready."
        case .authorizationFailed:
            return "Check your Apple ID settings and try again."
        case .noPresentationContext:
            return "Make sure the app is in the foreground."
        case .credentialStateCheckFailed:
            return "Check your network connection and try again."
        case .invalidIdentityToken:
            return "Try signing in again."
        case .missingUserInfo:
            return "Complete all required fields during sign in."
        case .notAvailable:
            return "Sign in with Apple requires iOS 13.0 or later."
        }
    }

    // MARK: - Equatable

    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled):
            return true
        case (.authorizationFailed(let l), .authorizationFailed(let r)):
            return l?.localizedDescription == r?.localizedDescription
        case (.noPresentationContext, .noPresentationContext):
            return true
        case (.credentialStateCheckFailed(let l), .credentialStateCheckFailed(let r)):
            return l?.localizedDescription == r?.localizedDescription
        case (.invalidIdentityToken, .invalidIdentityToken):
            return true
        case (.missingUserInfo(let l), .missingUserInfo(let r)):
            return l == r
        case (.notAvailable, .notAvailable):
            return true
        default:
            return false
        }
    }
}
