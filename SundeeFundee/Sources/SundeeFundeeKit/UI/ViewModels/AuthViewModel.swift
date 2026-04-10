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

            // Apple only sends email via credential on the first authorization.
            // On subsequent sign-ins, extract from the identity token JWT
            // or fall back to Keychain.
            if let email = result.email, !email.isEmpty {
                self.userEmail = email
            } else if let tokenEmail = result.tokenEmail {
                self.userEmail = tokenEmail
            } else {
                self.userEmail = KeychainHelper.read(key: KeychainHelper.userEmailKey)
            }

            // Apple only provides the name on the very first sign-in for this Apple ID + app.
            // On subsequent sign-ins (including after account deletion), fullName is nil.
            // Priority: Apple credential → Keychain → CloudKit (saved after first sign-in).
            if let givenName = result.givenName, !givenName.isEmpty {
                self.userName = givenName
            } else if let stored = KeychainHelper.read(key: KeychainHelper.userNameKey), !stored.isEmpty {
                self.userName = stored
            } else {
                // Final fallback: fetch from CloudKit (saved during first-ever sign-in)
                let cloudName = await fetchUserNameFromCloudKit(userID: result.userID)
                self.userName = cloudName
            }

            // Persist to Keychain for session restoration
            _ = KeychainHelper.save(key: KeychainHelper.userIDKey, value: result.userID)
            if let email = self.userEmail {
                _ = KeychainHelper.save(key: KeychainHelper.userEmailKey, value: email)
            }
            if let name = self.userName, !name.isEmpty {
                _ = KeychainHelper.save(key: KeychainHelper.userNameKey, value: name)
            }

            // Save user to CloudKit
            try await saveUserToCloudKit(result)

            self.isAuthenticated = true
            self.needsOnboarding = KeychainHelper.read(key: "onboarding_complete") == nil
        } catch {
            self.errorMessage = "Sign in failed: \(error.localizedDescription)"
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
        }

        isLoading = false
    }

    // MARK: - Private Methods

    /// Resets the authentication state and clears stored credentials
    private func resetState() async {
        // Clear Keychain
        _ = KeychainHelper.delete(key: KeychainHelper.userIDKey)
        _ = KeychainHelper.delete(key: KeychainHelper.userEmailKey)
        _ = KeychainHelper.delete(key: KeychainHelper.userNameKey)
        _ = KeychainHelper.delete(key: "onboarding_complete")

        await MainActor.run {
            // Reset to CloudKit for the next sign-in
            DataClientFactory.shared.client = CloudKitClient(
                containerIdentifier: "iCloud.com.sundeefundee.app"
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
            }

            // If userName wasn't in Keychain, try fetching from CloudKit
            if userName == nil || userName?.isEmpty == true {
                if let cloudName = await fetchUserNameFromCloudKit(userID: userID) {
                    self.userName = cloudName
                    _ = KeychainHelper.save(key: KeychainHelper.userNameKey, value: cloudName)
                }
            }

            isAuthenticated = true
            needsOnboarding = KeychainHelper.read(key: "onboarding_complete") == nil
        }
    }

    /// Fetches user's first name from CloudKit UserData record
    private func fetchUserNameFromCloudKit(userID: String) async -> String? {
        do {
            let results: [UserData] = try await dataClient.fetch(
                recordType: "UserData",
                predicate: NSPredicate(format: "userID == %@", userID),
                sortDescriptors: nil
            )
            if let user = results.first, !user.givenName.isEmpty {
                return user.givenName
            }
        } catch {
            // Silently fail — will show "Athlete" as fallback
        }
        return nil
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
