import AuthenticationServices
import Foundation
import XCTest
@testable import SundeeFundeeKit

// MARK: - AppleAuthClientTests
//
// NOTE: Sign in with Apple tests require a real device and cannot run in CI.
// The full sign-in flow tests are commented out and should be run manually.
// Use MockAppleAuthClient for unit testing instead.

// MARK: - AuthError Tests (can run without Apple ID)

final class AuthErrorTests: XCTestCase {
    func testCancelled_Description() {
        let error = AuthError.cancelled

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("cancelled"))
    }

    func testAuthorizationFailed_WithUnderlying_Description() {
        let underlying = NSError(
            domain: "Test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Connection failed"]
        )
        let error = AuthError.authorizationFailed(underlying: underlying)

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Authorization failed"))
    }

    func testAuthorizationFailed_WithoutUnderlying_Description() {
        let error = AuthError.authorizationFailed(underlying: nil)

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertEqual(description, "Authorization failed.")
    }

    func testNoPresentationContext_Description() {
        let error = AuthError.noPresentationContext

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("present"))
    }

    func testCredentialStateCheckFailed_Description() {
        let error = AuthError.credentialStateCheckFailed(underlying: nil)

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("credential state"))
    }

    func testInvalidIdentityToken_Description() {
        let error = AuthError.invalidIdentityToken

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("identity token"))
    }

    func testMissingUserInfo_Description() {
        let error = AuthError.missingUserInfo(field: "email")

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("email"))
    }

    func testNotAvailable_Description() {
        let error = AuthError.notAvailable

        let description = error.errorDescription

        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("not available"))
    }

    func testRecoverySuggestion_Cancelled() {
        let error = AuthError.cancelled

        let suggestion = error.recoverySuggestion

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("again"))
    }

    func testRecoverySuggestion_AuthorizationFailed() {
        let error = AuthError.authorizationFailed(underlying: nil)

        let suggestion = error.recoverySuggestion

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("Apple ID"))
    }

    func testRecoverySuggestion_NoPresentationContext() {
        let error = AuthError.noPresentationContext

        let suggestion = error.recoverySuggestion

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("foreground"))
    }

    func testRecoverySuggestion_CredentialStateCheckFailed() {
        let error = AuthError.credentialStateCheckFailed(underlying: nil)

        let suggestion = error.recoverySuggestion

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("network"))
    }

    func testRecoverySuggestion_InvalidIdentityToken() {
        let error = AuthError.invalidIdentityToken

        let suggestion = error.recoverySuggestion

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("signing in"))
    }

    func testRecoverySuggestion_MissingUserInfo() {
        let error = AuthError.missingUserInfo(field: "name")

        let suggestion = error.recoverySuggestion

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("required"))
    }

    func testRecoverySuggestion_NotAvailable() {
        let error = AuthError.notAvailable

        let suggestion = error.recoverySuggestion

        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("iOS"))
    }

    func testEquality_SameCases() {
        // Test simple cases without associated values
        XCTAssertTrue(AuthError.cancelled == AuthError.cancelled)
        XCTAssertTrue(AuthError.noPresentationContext == AuthError.noPresentationContext)
        XCTAssertTrue(AuthError.invalidIdentityToken == AuthError.invalidIdentityToken)
        XCTAssertTrue(AuthError.notAvailable == AuthError.notAvailable)
        XCTAssertTrue(AuthError.missingUserInfo(field: "email") == AuthError.missingUserInfo(field: "email"))
    }

    func testEquality_DifferentCases() {
        // Test different cases
        XCTAssertTrue(AuthError.cancelled != AuthError.noPresentationContext)
        XCTAssertTrue(AuthError.missingUserInfo(field: "email") != AuthError.missingUserInfo(field: "name"))
    }
}

// MARK: - AppleAuthResult Tests

final class AppleAuthResultTests: XCTestCase {
    func testInit_WithAllFields() {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "John"
        nameComponents.familyName = "Doe"

        let identityToken = "test-token".data(using: .utf8)
        let authCode = "test-code".data(using: .utf8)

        let result = AppleAuthResult(
            userID: "001234.abcd",
            email: "john@example.com",
            fullName: nameComponents,
            identityToken: identityToken,
            authorizationCode: authCode,
            authorizedScopes: [.email, .fullName]
        )

        XCTAssertEqual(result.userID, "001234.abcd")
        XCTAssertEqual(result.email, "john@example.com")
        XCTAssertEqual(result.givenName, "John")
        XCTAssertEqual(result.familyName, "Doe")
        XCTAssertEqual(result.identityToken, identityToken)
        XCTAssertEqual(result.authorizationCode, authCode)
        XCTAssertTrue(result.hasEmailScope)
        XCTAssertTrue(result.hasFullNameScope)
    }

    func testInit_WithMinimalFields() {
        let result = AppleAuthResult(
            userID: "001234.abcd",
            email: nil,
            fullName: nil,
            identityToken: nil,
            authorizationCode: nil,
            authorizedScopes: []
        )

        XCTAssertEqual(result.userID, "001234.abcd")
        XCTAssertNil(result.email)
        XCTAssertNil(result.fullName)
        XCTAssertNil(result.givenName)
        XCTAssertNil(result.familyName)
        XCTAssertNil(result.identityToken)
        XCTAssertNil(result.authorizationCode)
        XCTAssertFalse(result.hasEmailScope)
        XCTAssertFalse(result.hasFullNameScope)
    }

    func testIdentityTokenString() {
        let token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9"
        let result = AppleAuthResult(
            userID: "001234.abcd",
            email: nil,
            fullName: nil,
            identityToken: token.data(using: .utf8),
            authorizationCode: nil,
            authorizedScopes: []
        )

        XCTAssertEqual(result.identityTokenString, token)
    }

    func testIdentityTokenString_Nil() {
        let result = AppleAuthResult(
            userID: "001234.abcd",
            email: nil,
            fullName: nil,
            identityToken: nil,
            authorizationCode: nil,
            authorizedScopes: []
        )

        XCTAssertNil(result.identityTokenString)
    }

    func testAuthorizationCodeString() {
        let code = "c1234567890abcdef"
        let result = AppleAuthResult(
            userID: "001234.abcd",
            email: nil,
            fullName: nil,
            identityToken: nil,
            authorizationCode: code.data(using: .utf8),
            authorizedScopes: []
        )

        XCTAssertEqual(result.authorizationCodeString, code)
    }

    func testDisplayName() {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "Jane"
        nameComponents.familyName = "Smith"

        let result = AppleAuthResult(
            userID: "001234.abcd",
            email: nil,
            fullName: nameComponents,
            identityToken: nil,
            authorizationCode: nil,
            authorizedScopes: []
        )

        XCTAssertNotNil(result.displayName)
        XCTAssertTrue(result.displayName!.contains("Jane"))
    }

    func testDisplayName_Nil() {
        let result = AppleAuthResult(
            userID: "001234.abcd",
            email: nil,
            fullName: nil,
            identityToken: nil,
            authorizationCode: nil,
            authorizedScopes: []
        )

        XCTAssertNil(result.displayName)
    }

    func testEquatable() {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "Test"

        let result1 = AppleAuthResult(
            userID: "001234.abcd",
            email: "test@example.com",
            fullName: nameComponents,
            identityToken: "token".data(using: .utf8),
            authorizationCode: "code".data(using: .utf8),
            authorizedScopes: [.email]
        )

        let result2 = AppleAuthResult(
            userID: "001234.abcd",
            email: "test@example.com",
            fullName: nameComponents,
            identityToken: "token".data(using: .utf8),
            authorizationCode: "code".data(using: .utf8),
            authorizedScopes: [.email]
        )

        let result3 = AppleAuthResult(
            userID: "different",
            email: "test@example.com",
            fullName: nameComponents,
            identityToken: "token".data(using: .utf8),
            authorizationCode: "code".data(using: .utf8),
            authorizedScopes: [.email]
        )

        XCTAssertEqual(result1, result2)
        XCTAssertNotEqual(result1, result3)
    }
}

// MARK: - AppleAuthScope Tests

final class AppleAuthScopeTests: XCTestCase {
    func testNone() {
        let scope = AppleAuthScope.none
        XCTAssertTrue(scope.isEmpty)
        XCTAssertFalse(scope.contains(.email))
        XCTAssertFalse(scope.contains(.fullName))
    }

    func testEmail() {
        let scope = AppleAuthScope.email
        XCTAssertTrue(scope.contains(.email))
        XCTAssertFalse(scope.contains(.fullName))
    }

    func testFullName() {
        let scope = AppleAuthScope.fullName
        XCTAssertFalse(scope.contains(.email))
        XCTAssertTrue(scope.contains(.fullName))
    }

    func testAll() {
        let scope = AppleAuthScope.all
        XCTAssertTrue(scope.contains(.email))
        XCTAssertTrue(scope.contains(.fullName))
    }

    func testUnion() {
        let scope = AppleAuthScope.email.union(.fullName)
        XCTAssertEqual(scope, .all)
    }

    func testIntersection() {
        let scope = AppleAuthScope.all.intersection(.email)
        XCTAssertEqual(scope, .email)
    }

    func testEquatable() {
        XCTAssertEqual(AppleAuthScope.email, AppleAuthScope.email)
        XCTAssertNotEqual(AppleAuthScope.email, AppleAuthScope.fullName)
    }
}

// MARK: - AppleCredentialState Tests

final class AppleCredentialStateTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(AppleCredentialState.authorized, AppleCredentialState.authorized)
        XCTAssertEqual(AppleCredentialState.revoked, AppleCredentialState.revoked)
        XCTAssertEqual(AppleCredentialState.notFound, AppleCredentialState.notFound)
        XCTAssertEqual(AppleCredentialState.transferred, AppleCredentialState.transferred)

        XCTAssertNotEqual(AppleCredentialState.authorized, AppleCredentialState.revoked)
        XCTAssertNotEqual(AppleCredentialState.revoked, AppleCredentialState.notFound)
        XCTAssertNotEqual(AppleCredentialState.notFound, AppleCredentialState.transferred)
    }
}

// MARK: - AppleAuthClient Basic Tests

final class AppleAuthClientBasicTests: XCTestCase {
    func testInit() async {
        let client = AppleAuthClient()
        XCTAssertNotNil(client)
    }

    func testCredentialRevokedNotification() {
        XCTAssertEqual(
            AppleAuthClient.credentialRevokedNotification,
            ASAuthorizationAppleIDProvider.credentialRevokedNotification
        )
    }

    func testSignOut() async {
        let client = AppleAuthClient()

        // signOut should not throw and should complete
        await client.signOut()
    }
}

// MARK: - Sign In Tests (Manual Only)
//
// Uncomment these tests to run on a real device with proper provisioning.

/*
 final class AppleAuthClientSignInTests: XCTestCase {
 var sut: AppleAuthClient!

 override func setUp() async throws {
 sut = AppleAuthClient()
 }

 override func tearDown() async throws {
 await sut.signOut()
 sut = nil
 }

 func testSignIn_WithEmailAndName() async throws {
 // Note: This test requires a real device and user interaction
 let result = try await sut.signIn(scopes: [.email, .fullName])

 XCTAssertFalse(result.userID.isEmpty)
 // Email and name are only provided on first sign-in
 }

 func testSignIn_WithNoScopes() async throws {
 let result = try await sut.signIn(scopes: [])

 XCTAssertFalse(result.userID.isEmpty)
 XCTAssertFalse(result.hasEmailScope)
 XCTAssertFalse(result.hasFullNameScope)
 }

 func testGetCredentialState_Authorized() async throws {
 // First sign in
 let result = try await sut.signIn()

 // Then check state
 let state = try await sut.getCredentialState(forUserID: result.userID)

 // Should be authorized since we just signed in
 XCTAssertEqual(state, .authorized)
 }

 func testGetCredentialState_NotFound() async throws {
 // Use a fake user ID
 let state = try await sut.getCredentialState(forUserID: "fake.user.id")

 XCTAssertEqual(state, .notFound)
 }
 }
 */
