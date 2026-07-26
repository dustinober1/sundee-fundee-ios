import Foundation
import os.log
import SwiftUI

private let authLogger = Logger(subsystem: "com.sundeefundee.app", category: "AppleAuth")

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

    public nonisolated static let guestUserID = "guest_local"

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

        // Capture guest state BEFORE credentials change — we use this after
        // sign-in succeeds to decide whether to migrate local data to CloudKit.
        let wasGuest = self.isGuest
        // Capture the pre-sign-in data client as the migration source. For a
        // guest this is LocalDataClient (set by continueAsGuest). We capture
        // BEFORE any factory swap so we read from the correct store.
        let migrationSession = DataClientFactory.shared.session
        let migrationSource: any DataClientProtocol = migrationSession.client

        do {
            let result = try await authClient.signIn(scopes: [.fullName, .email])
            let destination: any DataClientProtocol = CloudKitClient(
                containerIdentifier: "iCloud.com.sundeefundee.app"
            )

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
                let cloudName = await fetchUserNameFromCloudKit(
                    userID: result.userID,
                    using: destination
                )
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
            try await saveUserToCloudKit(result, using: destination)

            // If this user was previously a guest, copy their local-only data
            // to CloudKit before any ViewModel starts reading from the new
            // data store. Sign-in itself must never fail because of migration:
            // on error we log, surface a message, and leave the local data
            // (and the LocalDataClient factory) in place for a later retry.
            if wasGuest {
                let sourcePresenceStore = PresenceLocalStore(ownerID: Self.guestUserID)
                let destinationPresenceStore = PresenceLocalStore(ownerID: result.userID)
                do {
                    try await migrateLegacyPresenceIfNeeded(to: sourcePresenceStore)
                    let migrator = GuestDataMigrator(
                        source: migrationSource,
                        destination: destination,
                        sourcePresenceStore: sourcePresenceStore,
                        sourcePresenceOwnerID: Self.guestUserID,
                        destinationPresenceStore: destinationPresenceStore,
                        destinationPresenceOwnerID: result.userID
                    )
                    let migrationResult = try await migrator.migrate()
                    authLogger.info(
                        "✅ Migrated \(migrationResult.totalCount) guest records to CloudKit"
                    )
                    // Only swap to CloudKit after a successful migration. On
                    // failure we keep LocalDataClient so the guest's data is
                    // still readable during the retry.
                    DataClientFactory.shared.activate(
                        client: destination,
                        ownerID: result.userID
                    )
                    self.isGuest = false
                } catch {
                    authLogger.error("❌ Guest migration failed: \(error.localizedDescription)")
                    self.errorMessage = "You're signed in. We couldn't copy your guest data yet — it's still on this device. Try again later from Settings."
                }
            } else {
                DataClientFactory.shared.activate(
                    client: destination,
                    ownerID: result.userID
                )
                self.isGuest = false
            }

            self.isAuthenticated = true
            self.needsOnboarding = KeychainHelper.read(key: "onboarding_complete") == nil
        } catch {
            self.errorMessage = "Sign in failed. Please try again."
        }

        isLoading = false
    }

    /// Signs in as a guest (local-only, no CloudKit, no Apple auth)
    public func continueAsGuest() {
        // Switch to local storage before any ViewModels initialize
        DataClientFactory.shared.activate(
            client: LocalDataClient(),
            ownerID: Self.guestUserID
        )
        Task {
            let store = PresenceLocalStore(ownerID: Self.guestUserID)
            try? await migrateLegacyPresenceIfNeeded(to: store)
        }

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
            let session = DataClientFactory.shared.session
            let deletingOwnerID = userID ?? session.ownerID

            // 1. Delete all data from CloudKit or Local storage
            try await session.client.deleteAllData()
            try await PresenceLocalStore(ownerID: deletingOwnerID).clear(
                ownerID: deletingOwnerID
            )

            // 2. Revoke Apple ID token if not a guest
            if !isGuest {
                // Re-authenticate to get a fresh authorization code for revocation
                let result = try await authClient.signIn(scopes: [])
                try await authClient.revokeToken(authorizationCode: result.authorizationCode)
            }

            // 3. Reset state and clear credentials
            await resetState()
        } catch {
            self.errorMessage = "We couldn't delete your account. Check your connection and try again."
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
            DataClientFactory.shared.activate(
                client: CloudKitClient(
                    containerIdentifier: "iCloud.com.sundeefundee.app"
                ),
                ownerID: "signed-out"
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
                DataClientFactory.shared.activate(
                    client: LocalDataClient(),
                    ownerID: Self.guestUserID
                )
                let store = PresenceLocalStore(ownerID: Self.guestUserID)
                try? await migrateLegacyPresenceIfNeeded(to: store)
                isAuthenticated = true
                needsOnboarding = KeychainHelper.read(key: "onboarding_complete") == nil
                return
            }

            do {
                let credentialState = try await authClient.getCredentialState(forUserID: userID)
                switch credentialState {
                case .authorized:
                    break
                case .revoked, .notFound, .transferred:
                    await clearSignedInSession()
                    errorMessage = "Your Apple sign-in needs to be refreshed. Please sign in again."
                    return
                }
            } catch {
                // If the credential state check fails, keep the cached session.
                authLogger.info("Credential state check failed during restore: \(error.localizedDescription)")
            }

            // If userName wasn't in Keychain, try fetching from CloudKit
            let restoredClient = DataClientFactory.shared.session.client
            DataClientFactory.shared.activate(client: restoredClient, ownerID: userID)
            if userName == nil || userName?.isEmpty == true {
                if let cloudName = await fetchUserNameFromCloudKit(
                    userID: userID,
                    using: restoredClient
                ) {
                    self.userName = cloudName
                    _ = KeychainHelper.save(key: KeychainHelper.userNameKey, value: cloudName)
                }
            }

            isAuthenticated = true
            needsOnboarding = KeychainHelper.read(key: "onboarding_complete") == nil
        }
    }

    private func clearSignedInSession() async {
        _ = KeychainHelper.delete(key: KeychainHelper.userIDKey)
        _ = KeychainHelper.delete(key: KeychainHelper.userEmailKey)
        _ = KeychainHelper.delete(key: KeychainHelper.userNameKey)
        _ = KeychainHelper.delete(key: "onboarding_complete")
        DataClientFactory.shared.activate(
            client: CloudKitClient(
                containerIdentifier: "iCloud.com.sundeefundee.app"
            ),
            ownerID: "signed-out"
        )
        isAuthenticated = false
        isGuest = false
        userID = nil
        userEmail = nil
        userName = nil
        needsOnboarding = false
    }

    /// Fetches user's first name from CloudKit UserData record
    private func fetchUserNameFromCloudKit(
        userID: String,
        using client: any DataClientProtocol
    ) async -> String? {
        do {
            let results: [UserData] = try await client.fetch(
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
    private func saveUserToCloudKit(
        _ result: AppleAuthResult,
        using client: any DataClientProtocol
    ) async throws {
        let userData = UserData(
            userID: result.userID,
            email: result.email ?? "",
            givenName: result.givenName ?? "",
            familyName: result.familyName ?? "",
            createdAt: Date()
        )

        try await client.save(userData, recordType: "UserData")
    }

    private func migrateLegacyPresenceIfNeeded(
        to store: PresenceLocalStore
    ) async throws {
        let legacyURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SundeeFundee", isDirectory: true)
            .appendingPathComponent("daily-presence.json")
        try await store.migrateLegacyCache(
            from: legacyURL,
            ownerID: Self.guestUserID
        )
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
