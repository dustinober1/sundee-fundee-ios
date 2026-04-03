import Foundation
import SwiftUI

// MARK: - AuthViewModel
//
// View model for authentication operations.
// Manages Sign in with Apple flow and authentication state.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public class AuthViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var isAuthenticated: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var userID: String?
    @Published public var userEmail: String?
    @Published public var userName: String?
    @Published public var needsOnboarding: Bool = false

    // MARK: - Dependencies

    private let authClient: AppleAuthClientProtocol
    private let dataClient: DataClientProtocol

    // MARK: - Initialization

    public init(
        authClient: AppleAuthClientProtocol = AppleAuthClient(),
        dataClient: DataClientProtocol = CloudKitClient(containerIdentifier: "icloud.com.sundeefundee.app")
    ) {
        self.authClient = authClient
        self.dataClient = dataClient

        // Check for existing session on init
        Task {
            await checkExistingSession()
        }
    }

    // MARK: - Public Methods

    /// Signs in with Apple
    public func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await authClient.signIn(scopes: [.fullName, .email])

            // Store user info
            self.userID = result.userID
            self.userEmail = result.email
            self.userName = result.displayName

            // Persist to Keychain for session restoration
            _ = KeychainHelper.save(key: KeychainHelper.userIDKey, value: result.userID)
            if let email = result.email {
                _ = KeychainHelper.save(key: KeychainHelper.userEmailKey, value: email)
            }
            if let name = result.displayName {
                _ = KeychainHelper.save(key: KeychainHelper.userNameKey, value: name)
            }

            // Save user to CloudKit
            try await saveUserToCloudKit(result)

            self.isAuthenticated = true
            self.needsOnboarding = KeychainHelper.read(key: "onboarding_complete") == nil
        } catch {
            self.errorMessage = "Sign in failed: \(error.localizedDescription)"
            print("Auth error: \(error)")
        }

        isLoading = false
    }

    /// Marks onboarding as complete
    public func completeOnboarding() {
        _ = KeychainHelper.save(key: "onboarding_complete", value: "true")
        needsOnboarding = false
    }

    /// Signs out the current user
    public func signOut() {
        Task {
            await authClient.signOut()

            // Clear Keychain
            _ = KeychainHelper.delete(key: KeychainHelper.userIDKey)
            _ = KeychainHelper.delete(key: KeychainHelper.userEmailKey)
            _ = KeychainHelper.delete(key: KeychainHelper.userNameKey)

            await MainActor.run {
                isAuthenticated = false
                userID = nil
                userEmail = nil
                userName = nil
                errorMessage = nil
            }
        }
    }

    // MARK: - Private Methods

    /// Checks for an existing authenticated session
    private func checkExistingSession() async {
        if let userID = await fetchStoredUserID() {
            self.userID = userID
            isAuthenticated = true
            needsOnboarding = KeychainHelper.read(key: "onboarding_complete") == nil
        }
    }

    /// Saves user info to CloudKit after successful authentication
    private func saveUserToCloudKit(_ result: AppleAuthResult) async throws {
        let userData = UserData(
            userID: result.userID,
            email: result.email ?? "",
            givenName: result.givenName ?? "",
            familyName: result.familyName ?? "",
            createdAt: Date()
        )

        try await dataClient.save(userData, recordType: "UserData")
    }

    /// Fetches stored user ID from Keychain
    private func fetchStoredUserID() async -> String? {
        guard let storedID = KeychainHelper.read(key: KeychainHelper.userIDKey) else {
            return nil
        }

        // Restore cached user info from Keychain
        self.userEmail = KeychainHelper.read(key: KeychainHelper.userEmailKey)
        self.userName = KeychainHelper.read(key: KeychainHelper.userNameKey)

        return storedID
    }
}

// MARK: - UserData Model

struct UserData: Codable, Sendable {
    let userID: String
    let email: String
    let givenName: String
    let familyName: String
    let createdAt: Date
}
