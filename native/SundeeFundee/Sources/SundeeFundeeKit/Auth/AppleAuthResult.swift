import Foundation

// MARK: - AppleAuthResult

/// The result of a successful Sign in with Apple authentication.
///
/// `AppleAuthResult` contains all the relevant user information returned by Apple
/// after a successful authentication, including identity tokens for backend verification.
///
/// ## Example Usage
/// ```swift
/// let result = try await appleAuthClient.signIn()
/// print("User ID: \(result.userID)")
/// print("Email: \(result.email ?? "not provided")")
/// print("Name: \(result.fullName?.formatted() ?? "not provided")")
/// ```
public struct AppleAuthResult: Sendable, Equatable {
    // MARK: - Properties

    /// The unique user identifier provided by Apple.
    ///
    /// This identifier is stable across app installs and can be used to identify
    /// the user on your backend. It's specific to your app and Team ID.
    public let userID: String

    /// The user's email address, if provided.
    ///
    /// Apple may return either the user's real email or an obfuscated proxy email
    /// (e.g., `xyz@privaterelay.appleid.com`) depending on user preference.
    /// This value is only provided on the **first** sign-in.
    public let email: String?

    /// The user's full name components, if provided.
    ///
    /// This value is only provided on the **first** sign-in for privacy reasons.
    public let fullName: PersonNameComponents?

    /// The user's given (first) name.
    public var givenName: String? {
        fullName?.givenName
    }

    /// The user's family (last) name.
    public var familyName: String? {
        fullName?.familyName
    }

    /// A JSON Web Token (JWT) that securely communicates information about the user to your app.
    ///
    /// This token can be sent to your backend for verification with Apple's servers.
    /// The token contains the user's email, email verification status, and other claims.
    public let identityToken: Data?

    /// A short-lived token used to prove the user authenticated with Apple.
    ///
    /// This token can be exchanged with Apple's servers for a refresh token.
    /// Typically used for server-side verification flows.
    public let authorizationCode: Data?

    /// The scopes that were authorized during sign in.
    ///
    /// Indicates whether the user authorized access to their email and/or full name.
    public let authorizedScopes: AppleAuthScope

    // MARK: - Initialization

    /// Creates a new `AppleAuthResult` with the provided user information.
    ///
    /// - Parameters:
    ///   - userID: The unique Apple user identifier.
    ///   - email: The user's email address (may be proxied).
    ///   - fullName: The user's full name components.
    ///   - identityToken: The JWT identity token.
    ///   - authorizationCode: The authorization code for server exchange.
    ///   - authorizedScopes: The scopes that were authorized.
    public init(
        userID: String,
        email: String?,
        fullName: PersonNameComponents?,
        identityToken: Data?,
        authorizationCode: Data?,
        authorizedScopes: AppleAuthScope
    ) {
        self.userID = userID
        self.email = email
        self.fullName = fullName
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.authorizedScopes = authorizedScopes
    }

    // MARK: - Computed Properties

    /// The identity token decoded as a UTF-8 string.
    ///
    /// Returns `nil` if the identity token is not present or cannot be decoded.
    public var identityTokenString: String? {
        guard let data = identityToken else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// The authorization code decoded as a UTF-8 string.
    ///
    /// Returns `nil` if the authorization code is not present or cannot be decoded.
    public var authorizationCodeString: String? {
        guard let data = authorizationCode else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// A display-friendly name from the name components.
    ///
    /// Returns the formatted name using the user's locale, or `nil` if no name was provided.
    public var displayName: String? {
        fullName?.formatted(.name(style: .medium))
    }

    /// Whether the user authorized access to their email.
    public var hasEmailScope: Bool {
        authorizedScopes.contains(.email)
    }

    /// Whether the user authorized access to their full name.
    public var hasFullNameScope: Bool {
        authorizedScopes.contains(.fullName)
    }
}

// MARK: - AppleAuthScope

/// The authorization scopes that can be requested during Sign in with Apple.
///
/// These scopes determine what user information Apple will provide in the
/// authentication result. Note that Apple only provides this information
/// on the user's first sign-in.
public struct AppleAuthScope: OptionSet, Sendable, Equatable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// No additional scopes requested.
    public static let none: AppleAuthScope = []

    /// Request access to the user's email address.
    public static let email = AppleAuthScope(rawValue: 1 << 0)

    /// Request access to the user's full name.
    public static let fullName = AppleAuthScope(rawValue: 1 << 1)

    /// Request both email and full name.
    public static let all: AppleAuthScope = [.email, .fullName]
}

// MARK: - AppleCredentialState

/// The state of a user's Sign in with Apple credential.
///
/// Use this to determine if the user's authorization is still valid
/// or if they need to sign in again.
public enum AppleCredentialState: Sendable, Equatable {
    /// The credential is authorized and valid.
    case authorized

    /// The user has revoked the credential (signed out).
    case revoked

    /// The credential was not found (user never signed in).
    case notFound

    /// The credential state is transitioning to a new state.
    case transferred
}
