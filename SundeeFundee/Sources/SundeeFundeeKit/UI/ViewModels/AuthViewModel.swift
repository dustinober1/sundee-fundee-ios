import Foundation
import os.log
import SwiftUI

private let authLogger = Logger(subsystem: "com.sundeefundee.app", category: "AppleAuth")

protocol AuthSessionStoring: Sendable {
    func read(key: String) -> String?

    @discardableResult
    func save(key: String, value: String) -> Bool

    @discardableResult
    func delete(key: String) -> Bool
}

private struct KeychainAuthSessionStore: AuthSessionStoring {
    func read(key: String) -> String? {
        KeychainHelper.read(key: key)
    }

    func save(key: String, value: String) -> Bool {
        KeychainHelper.save(key: key, value: value)
    }

    func delete(key: String) -> Bool {
        KeychainHelper.delete(key: key)
    }
}

protocol AuthDataSessionManaging: Sendable {
    var session: DataClientFactory.Session { get }
    func activate(client: any DataClientProtocol, ownerID: String)
}

extension DataClientFactory: AuthDataSessionManaging {}

private struct PendingGuestMigration: Codable, Sendable {
    let sourceOwnerID: String
    let destinationUserID: String
    let email: String?
    let givenName: String?
    let familyName: String?
    let dateCreated: Date
}

private enum AuthLifecycleError: Error {
    case pendingMigrationCouldNotBeSaved
    case authenticatedSessionCouldNotBeSaved
    case pendingMigrationCouldNotBeCleared
}

typealias GuestMigrationOperation = @Sendable (
    _ source: any DataClientProtocol,
    _ destination: any DataClientProtocol,
    _ sourceOwnerID: String,
    _ destinationOwnerID: String
) async throws -> GuestMigrationResult

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
    nonisolated static let pendingGuestMigrationKey = "guest_migration_pending"

    // MARK: - Dependencies

    private let authClient: AppleAuthClientProtocol
    private let sessionStore: any AuthSessionStoring
    private let sessionManager: any AuthDataSessionManaging
    private let destinationClientFactory: @Sendable () -> any DataClientProtocol
    private let localClientFactory: @Sendable () -> any DataClientProtocol
    private let guestMigration: GuestMigrationOperation

    // MARK: - Initialization

    public convenience init(
        authClient: AppleAuthClientProtocol = AppleAuthClient(),
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        _ = dataClient
        self.init(
            authClient: authClient,
            sessionStore: KeychainAuthSessionStore(),
            sessionManager: DataClientFactory.shared,
            destinationClientFactory: {
                CloudKitClient(containerIdentifier: "iCloud.com.sundeefundee.app")
            },
            localClientFactory: { LocalDataClient() },
            guestMigration: Self.defaultGuestMigration,
            restoreSessionOnInit: true
        )
    }

    init(
        authClient: any AppleAuthClientProtocol,
        sessionStore: any AuthSessionStoring,
        sessionManager: any AuthDataSessionManaging,
        destinationClientFactory: @escaping @Sendable () -> any DataClientProtocol,
        localClientFactory: @escaping @Sendable () -> any DataClientProtocol,
        guestMigration: @escaping GuestMigrationOperation,
        restoreSessionOnInit: Bool
    ) {
        self.authClient = authClient
        self.sessionStore = sessionStore
        self.sessionManager = sessionManager
        self.destinationClientFactory = destinationClientFactory
        self.localClientFactory = localClientFactory
        self.guestMigration = guestMigration

        if restoreSessionOnInit {
            Task { [weak self] in
                await self?.restoreSession()
            }
        }
    }

    // MARK: - Public Methods

    /// Signs in with Apple
    public func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let wasGuest = isGuest
        let migrationSession = sessionManager.session
        let migrationSource: any DataClientProtocol = migrationSession.client

        do {
            let result = try await authClient.signIn(scopes: [.fullName, .email])
            let destination = destinationClientFactory()
            let email = resolvedEmail(for: result)
            let name = await resolvedName(for: result, using: destination)

            if wasGuest {
                let marker = PendingGuestMigration(
                    sourceOwnerID: migrationSession.ownerID,
                    destinationUserID: result.userID,
                    email: email,
                    givenName: result.givenName ?? name,
                    familyName: result.familyName,
                    dateCreated: Date()
                )
                try savePendingGuestMigration(marker)
                persistProfile(email: email, name: name)

                do {
                    try await saveUserToCloudKit(marker, using: destination)
                    let migrationResult = try await guestMigration(
                        migrationSource,
                        destination,
                        marker.sourceOwnerID,
                        marker.destinationUserID
                    )
                    authLogger.info(
                        "✅ Migrated \(migrationResult.totalCount) guest records to CloudKit"
                    )
                    try activateMigratedAccount(
                        marker,
                        destination: destination,
                        displayName: name
                    )
                } catch {
                    authLogger.error("❌ Guest migration failed: \(error.localizedDescription)")
                    keepGuestSession(
                        source: migrationSource,
                        ownerID: marker.sourceOwnerID
                    )
                    self.errorMessage = "You're signed in. We couldn't copy your guest data yet — "
                        + "it's still on this device. Try again later from Settings."
                    return
                }
            } else {
                try await saveUserToCloudKit(result, using: destination)
                try persistAuthenticatedUserID(result.userID)
                persistProfile(email: email, name: name)
                sessionManager.activate(
                    client: destination,
                    ownerID: result.userID
                )
                publishAuthenticatedAccount(
                    userID: result.userID,
                    email: email,
                    name: name
                )
            }

            isAuthenticated = true
            needsOnboarding = sessionStore.read(key: "onboarding_complete") == nil
        } catch {
            self.errorMessage = "Sign in failed. Please try again."
        }
    }

    /// Signs in as a guest (local-only, no CloudKit, no Apple auth)
    public func continueAsGuest() {
        let localClient = localClientFactory()
        sessionManager.activate(
            client: localClient,
            ownerID: Self.guestUserID
        )
        Task {
            let store = PresenceLocalStore(ownerID: Self.guestUserID)
            try? await Self.migrateLegacyPresenceIfNeeded(
                to: store,
                ownerID: Self.guestUserID
            )
        }

        isGuest = true
        userID = AuthViewModel.guestUserID
        userName = "Guest"
        userEmail = nil

        // Persist guest session so it survives app restarts
        _ = sessionStore.save(
            key: KeychainHelper.userIDKey,
            value: AuthViewModel.guestUserID
        )

        isAuthenticated = true
        needsOnboarding = sessionStore.read(key: "onboarding_complete") == nil
    }

    /// Marks onboarding as complete
    public func completeOnboarding() {
        _ = sessionStore.save(key: "onboarding_complete", value: "true")
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
            let session = sessionManager.session
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
            _ = sessionStore.delete(key: Self.pendingGuestMigrationKey)
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
        _ = sessionStore.delete(key: KeychainHelper.userIDKey)
        _ = sessionStore.delete(key: KeychainHelper.userEmailKey)
        _ = sessionStore.delete(key: KeychainHelper.userNameKey)
        _ = sessionStore.delete(key: "onboarding_complete")

        await MainActor.run {
            // Reset to CloudKit for the next sign-in
            sessionManager.activate(
                client: destinationClientFactory(),
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

    /// Restores a guest, signed-in, or interrupted guest-conversion session.
    ///
    /// A pending conversion always wins over the stored user ID so a process
    /// interruption cannot activate the destination account before local data
    /// has finished migrating.
    func restoreSession() async {
        if let pendingMigration = loadPendingGuestMigration() {
            await resumePendingGuestMigration(pendingMigration)
            return
        }

        if let userID = await fetchStoredUserID() {
            self.userID = userID

            // Restore guest state and local data client if this was a guest session
            if userID == AuthViewModel.guestUserID {
                isGuest = true
                sessionManager.activate(
                    client: localClientFactory(),
                    ownerID: Self.guestUserID
                )
                let store = PresenceLocalStore(ownerID: Self.guestUserID)
                try? await Self.migrateLegacyPresenceIfNeeded(
                    to: store,
                    ownerID: Self.guestUserID
                )
                isAuthenticated = true
                needsOnboarding = sessionStore.read(key: "onboarding_complete") == nil
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
            let restoredClient = destinationClientFactory()
            sessionManager.activate(client: restoredClient, ownerID: userID)
            if userName == nil || userName?.isEmpty == true {
                if let cloudName = await fetchUserNameFromCloudKit(
                    userID: userID,
                    using: restoredClient
                ) {
                    self.userName = cloudName
                    _ = sessionStore.save(
                        key: KeychainHelper.userNameKey,
                        value: cloudName
                    )
                }
            }

            isAuthenticated = true
            needsOnboarding = sessionStore.read(key: "onboarding_complete") == nil
        }
    }

    private func clearSignedInSession() async {
        _ = sessionStore.delete(key: KeychainHelper.userIDKey)
        _ = sessionStore.delete(key: KeychainHelper.userEmailKey)
        _ = sessionStore.delete(key: KeychainHelper.userNameKey)
        _ = sessionStore.delete(key: "onboarding_complete")
        sessionManager.activate(
            client: destinationClientFactory(),
            ownerID: "signed-out"
        )
        isAuthenticated = false
        isGuest = false
        userID = nil
        userEmail = nil
        userName = nil
        needsOnboarding = false
    }

    private func resumePendingGuestMigration(
        _ marker: PendingGuestMigration
    ) async {
        let source = localClientFactory()
        keepGuestSession(source: source, ownerID: marker.sourceOwnerID)

        do {
            let credentialState = try await authClient.getCredentialState(
                forUserID: marker.destinationUserID
            )
            guard credentialState == .authorized else {
                errorMessage = "Your Apple sign-in needs to be refreshed before we can finish copying your guest data."
                return
            }
        } catch {
            authLogger.info(
                "Credential state check failed while resuming guest migration: \(error.localizedDescription)"
            )
        }

        let destination = destinationClientFactory()
        do {
            try await saveUserToCloudKit(marker, using: destination)
            let migrationResult = try await guestMigration(
                source,
                destination,
                marker.sourceOwnerID,
                marker.destinationUserID
            )
            authLogger.info(
                "✅ Resumed migration of \(migrationResult.totalCount) guest records to CloudKit"
            )
            try activateMigratedAccount(
                marker,
                destination: destination,
                displayName: marker.givenName
            )
            errorMessage = nil
        } catch {
            authLogger.error(
                "❌ Resuming guest migration failed: \(error.localizedDescription)"
            )
            keepGuestSession(source: source, ownerID: marker.sourceOwnerID)
            errorMessage = "We still couldn't copy your guest data. "
                + "It's safe on this device, and we'll try again next time."
        }
    }

    private func keepGuestSession(
        source: any DataClientProtocol,
        ownerID: String
    ) {
        sessionManager.activate(client: source, ownerID: ownerID)
        userID = ownerID
        userEmail = nil
        userName = "Guest"
        isGuest = true
        isAuthenticated = true
        needsOnboarding = sessionStore.read(key: "onboarding_complete") == nil
    }

    private func publishAuthenticatedAccount(
        userID: String,
        email: String?,
        name: String?
    ) {
        self.userID = userID
        userEmail = email
        userName = name
        isGuest = false
        isAuthenticated = true
        needsOnboarding = sessionStore.read(key: "onboarding_complete") == nil
    }

    private func resolvedEmail(for result: AppleAuthResult) -> String? {
        if let email = result.email, !email.isEmpty {
            return email
        }
        if let tokenEmail = result.tokenEmail, !tokenEmail.isEmpty {
            return tokenEmail
        }
        return sessionStore.read(key: KeychainHelper.userEmailKey)
    }

    private func resolvedName(
        for result: AppleAuthResult,
        using destination: any DataClientProtocol
    ) async -> String? {
        if let givenName = result.givenName, !givenName.isEmpty {
            return givenName
        }
        if let stored = sessionStore.read(key: KeychainHelper.userNameKey),
           !stored.isEmpty {
            return stored
        }
        return await fetchUserNameFromCloudKit(
            userID: result.userID,
            using: destination
        )
    }

    private func persistProfile(email: String?, name: String?) {
        if let email, !email.isEmpty {
            _ = sessionStore.save(
                key: KeychainHelper.userEmailKey,
                value: email
            )
        }
        if let name, !name.isEmpty {
            _ = sessionStore.save(
                key: KeychainHelper.userNameKey,
                value: name
            )
        }
    }

    private func persistAuthenticatedUserID(_ userID: String) throws {
        guard sessionStore.save(
            key: KeychainHelper.userIDKey,
            value: userID
        ) else {
            throw AuthLifecycleError.authenticatedSessionCouldNotBeSaved
        }
    }

    private func savePendingGuestMigration(
        _ marker: PendingGuestMigration
    ) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(marker)
        guard let encoded = String(data: data, encoding: .utf8),
              sessionStore.save(
                key: Self.pendingGuestMigrationKey,
                value: encoded
              ) else {
            throw AuthLifecycleError.pendingMigrationCouldNotBeSaved
        }
    }

    private func loadPendingGuestMigration() -> PendingGuestMigration? {
        guard let encoded = sessionStore.read(
            key: Self.pendingGuestMigrationKey
        ), let data = encoded.data(using: .utf8) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(PendingGuestMigration.self, from: data)
    }

    private func activateMigratedAccount(
        _ marker: PendingGuestMigration,
        destination: any DataClientProtocol,
        displayName: String?
    ) throws {
        try persistAuthenticatedUserID(marker.destinationUserID)
        persistProfile(email: marker.email, name: displayName)
        guard sessionStore.delete(key: Self.pendingGuestMigrationKey) else {
            throw AuthLifecycleError.pendingMigrationCouldNotBeCleared
        }
        sessionManager.activate(
            client: destination,
            ownerID: marker.destinationUserID
        )
        publishAuthenticatedAccount(
            userID: marker.destinationUserID,
            email: marker.email,
            name: displayName
        )
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
        try await client.save(
            UserData(
                userID: result.userID,
                email: result.email ?? "",
                givenName: result.givenName ?? "",
                familyName: result.familyName ?? "",
                createdAt: Date()
            ),
            recordType: "UserData"
        )
    }

    private func saveUserToCloudKit(
        _ marker: PendingGuestMigration,
        using client: any DataClientProtocol
    ) async throws {
        try await client.save(
            UserData(
                userID: marker.destinationUserID,
                email: marker.email ?? "",
                givenName: marker.givenName ?? "",
                familyName: marker.familyName ?? "",
                createdAt: marker.dateCreated
            ),
            recordType: "UserData"
        )
    }

    private nonisolated static func defaultGuestMigration(
        source: any DataClientProtocol,
        destination: any DataClientProtocol,
        sourceOwnerID: String,
        destinationOwnerID: String
    ) async throws -> GuestMigrationResult {
        let sourcePresenceStore = PresenceLocalStore(ownerID: sourceOwnerID)
        let destinationPresenceStore = PresenceLocalStore(
            ownerID: destinationOwnerID
        )
        try await migrateLegacyPresenceIfNeeded(
            to: sourcePresenceStore,
            ownerID: sourceOwnerID
        )
        return try await GuestDataMigrator(
            source: source,
            destination: destination,
            sourcePresenceStore: sourcePresenceStore,
            sourcePresenceOwnerID: sourceOwnerID,
            destinationPresenceStore: destinationPresenceStore,
            destinationPresenceOwnerID: destinationOwnerID
        ).migrate()
    }

    private nonisolated static func migrateLegacyPresenceIfNeeded(
        to store: PresenceLocalStore,
        ownerID: String
    ) async throws {
        let legacyURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SundeeFundee", isDirectory: true)
            .appendingPathComponent("daily-presence.json")
        try await store.migrateLegacyCache(
            from: legacyURL,
            ownerID: ownerID
        )
    }

    /// Fetches stored user ID from Keychain
    private func fetchStoredUserID() async -> String? {
        guard let storedID = sessionStore.read(
            key: KeychainHelper.userIDKey
        ) else {
            return nil
        }

        // Restore cached user info from Keychain
        userEmail = sessionStore.read(key: KeychainHelper.userEmailKey)
        userName = sessionStore.read(key: KeychainHelper.userNameKey)

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
