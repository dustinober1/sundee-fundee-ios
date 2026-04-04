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
    @Published public var isGuest: Bool = false

    public static let guestUserID = "guest_local"

    // MARK: - Dependencies

    private let authClient: AppleAuthClientProtocol
    private let dataClient: DataClientProtocol

    // MARK: - Initialization

    public init(
        authClient: AppleAuthClientProtocol = AppleAuthClient(),
        dataClient: DataClientProtocol = DataClientFactory.shared.client
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

            // Identify with RevenueCat for subscription tracking
            if let subscriptionClient = SubscriptionClientFactory.shared.client as? RevenueCatClient {
                await subscriptionClient.identify(userId: result.userID)
            }

            self.isAuthenticated = true
            self.needsOnboarding = KeychainHelper.read(key: "onboarding_complete") == nil
        } catch {
            self.errorMessage = "Sign in failed: \(error.localizedDescription)"
            print("Auth error: \(error)")
        }

        isLoading = false
    }

    /// Signs in as a guest (local-only, no CloudKit, no Apple auth)
    public func continueAsGuest() {
        // Switch to local storage before any ViewModels initialize
        DataClientFactory.shared.client = LocalDataClient()

        isGuest = true
        userID = AuthViewModel.guestUserID
        userName = "Guest"

        // Persist guest session so it survives app restarts
        _ = KeychainHelper.save(key: KeychainHelper.userIDKey, value: AuthViewModel.guestUserID)

        isAuthenticated = true
        needsOnboarding = KeychainHelper.read(key: "onboarding_complete") == nil
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
            await resetState()
        }
    }

    /// Deletes the user's account and all associated data.
    ///
    /// This is a destructive operation that cannot be undone.
    /// Required for App Store compliance.
    public func deleteAccount() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Delete all data from CloudKit or Local storage
            try await dataClient.deleteAllData()

            // 2. Revoke Apple ID token if not a guest
            if !isGuest {
                // We'd ideally have the authorization code stored or prompt again.
                // For now, we'll perform a best-effort revocation.
                try await authClient.revokeToken(authorizationCode: nil)
            }

            // 3. Reset state and clear credentials
            await resetState()
        } catch {
            self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
            print("Delete account error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Private Methods

    /// Resets the authentication state and clears stored credentials
    private func resetState() async {
        // Logout from RevenueCat
        if let subscriptionClient = SubscriptionClientFactory.shared.client as? RevenueCatClient {
            await subscriptionClient.logout()
        }

        // Clear Keychain
        _ = KeychainHelper.delete(key: KeychainHelper.userIDKey)
        _ = KeychainHelper.delete(key: KeychainHelper.userEmailKey)
        _ = KeychainHelper.delete(key: KeychainHelper.userNameKey)
        _ = KeychainHelper.delete(key: "onboarding_complete")

        await MainActor.run {
            // Reset to CloudKit for the next sign-in
            DataClientFactory.shared.client = CloudKitClient(
                containerIdentifier: "icloud.com.sundeefundee.app"
            )
            isAuthenticated = false
            isGuest = false
            userID = nil
            userEmail = nil
            userName = nil
            errorMessage = nil
            needsOnboarding = false
        }
    }

    /// Checks for an existing authenticated session
    private func checkExistingSession() async {
        if let userID = await fetchStoredUserID() {
            self.userID = userID

            // Restore guest state and local data client if this was a guest session
            if userID == AuthViewModel.guestUserID {
                isGuest = true
                DataClientFactory.shared.client = LocalDataClient()
            } else {
                // Re-identify with RevenueCat for returning signed-in users
                if let subscriptionClient = SubscriptionClientFactory.shared.client as? RevenueCatClient {
                    await subscriptionClient.identify(userId: userID)
                }
            }

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
