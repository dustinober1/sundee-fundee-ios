import CloudKit
import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("Auth view model guest conversion", .serialized)
@MainActor
struct AuthViewModelTests {
    @Test("direct Apple conversion marks migration pending before upload and activates after success")
    func directGuestConversionActivatesOnlyAfterMigration() async throws {
        let sessionStore = TestAuthSessionStore()
        let source = MockCloudKitClient()
        let destination = LifecycleDestinationClient(
            markerProbe: {
                sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) != nil
            }
        )
        let sessionManager = TestAuthDataSessionManager(
            ownerID: "signed-out",
            client: MockCloudKitClient(),
            activationProbe: { ownerID in
                ownerID != "account-a"
                    || source.recordCount(for: "Workout") == 0
            }
        )
        let authClient = TestAppleAuthClient(result: makeAuthResult())
        try await source.save(makeWorkout(), recordType: "Workout")
        let viewModel = makeViewModel(
            authClient: authClient,
            sessionStore: sessionStore,
            sessionManager: sessionManager,
            source: source,
            destination: destination
        )

        viewModel.continueAsGuest()
        await viewModel.signInWithApple()

        let signOutCount = await authClient.signOutCount
        #expect(signOutCount == 0)
        #expect(destination.markerWasPresentAtFirstSave)
        #expect(source.recordCount(for: "Workout") == 0)
        #expect(destination.recordCount(for: "Workout") == 1)
        #expect(sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) == nil)
        #expect(sessionStore.read(key: KeychainHelper.userIDKey) == "account-a")
        #expect(sessionManager.session.ownerID == "account-a")
        #expect(sessionManager.accountActivationWasSafe)
        #expect(viewModel.userID == "account-a")
        #expect(viewModel.isAuthenticated)
        #expect(!viewModel.isGuest)
    }

    @Test("failed conversion stays guest and relaunch retries before account activation")
    func failedGuestConversionResumesOnRelaunch() async throws {
        let sessionStore = TestAuthSessionStore()
        let source = MockCloudKitClient()
        let destination = LifecycleDestinationClient(
            failWorkoutSaves: true,
            markerProbe: {
                sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) != nil
            }
        )
        let firstSessionManager = TestAuthDataSessionManager(
            ownerID: "signed-out",
            client: MockCloudKitClient(),
            activationProbe: { ownerID in
                ownerID != "account-a"
                    || source.recordCount(for: "Workout") == 0
            }
        )
        let authClient = TestAppleAuthClient(result: makeAuthResult())
        try await source.save(makeWorkout(), recordType: "Workout")
        let firstViewModel = makeViewModel(
            authClient: authClient,
            sessionStore: sessionStore,
            sessionManager: firstSessionManager,
            source: source,
            destination: destination
        )

        firstViewModel.continueAsGuest()
        await firstViewModel.signInWithApple()

        #expect(destination.markerWasPresentAtFirstSave)
        #expect(sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) != nil)
        #expect(sessionStore.read(key: KeychainHelper.userIDKey) == AuthViewModel.guestUserID)
        #expect(firstSessionManager.session.ownerID == AuthViewModel.guestUserID)
        #expect(firstViewModel.userID == AuthViewModel.guestUserID)
        #expect(firstViewModel.isGuest)
        #expect(source.recordCount(for: "Workout") == 1)
        #expect(destination.recordCount(for: "Workout") == 0)

        // Simulate interruption after a destination credential was persisted.
        // The durable migration marker must still take precedence on launch.
        _ = sessionStore.save(
            key: KeychainHelper.userIDKey,
            value: "account-a"
        )
        destination.failWorkoutSaves = false
        let restoredSessionManager = TestAuthDataSessionManager(
            ownerID: "signed-out",
            client: MockCloudKitClient(),
            activationProbe: { ownerID in
                ownerID != "account-a"
                    || source.recordCount(for: "Workout") == 0
            }
        )
        let restoredViewModel = makeViewModel(
            authClient: authClient,
            sessionStore: sessionStore,
            sessionManager: restoredSessionManager,
            source: source,
            destination: destination
        )

        await restoredViewModel.restoreSession()

        #expect(source.recordCount(for: "Workout") == 0)
        #expect(destination.recordCount(for: "Workout") == 1)
        #expect(sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) == nil)
        #expect(sessionStore.read(key: KeychainHelper.userIDKey) == "account-a")
        #expect(restoredSessionManager.session.ownerID == "account-a")
        #expect(restoredSessionManager.accountActivationWasSafe)
        #expect(restoredViewModel.userID == "account-a")
        #expect(restoredViewModel.isAuthenticated)
        #expect(!restoredViewModel.isGuest)
    }

    @Test("deleting a pending conversion clears guest and Apple data before removing its marker")
    func pendingConversionDeletionCleansBothAccounts() async throws {
        let presenceDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: presenceDirectory) }

        let sessionStore = TestAuthSessionStore()
        let source = MockCloudKitClient()
        let destination = LifecycleDestinationClient(
            failWorkoutSaves: true,
            markerProbe: {
                sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) != nil
            }
        )
        let sessionManager = TestAuthDataSessionManager(
            ownerID: "signed-out",
            client: MockCloudKitClient()
        )
        let authClient = TestAppleAuthClient(result: makeAuthResult())
        let guestPresenceStore = PresenceLocalStore(
            ownerID: AuthViewModel.guestUserID,
            baseDirectoryURL: presenceDirectory
        )
        let destinationPresenceStore = PresenceLocalStore(
            ownerID: "account-a",
            baseDirectoryURL: presenceDirectory
        )
        let presence = DailyPresenceRecord(
            dayKey: "2026-07-26",
            timeZoneIdentifier: "America/New_York",
            firstOpenDate: Date(timeIntervalSince1970: 1_753_528_400)
        )
        _ = try await guestPresenceStore.save(
            presence,
            ownerID: AuthViewModel.guestUserID
        )
        _ = try await destinationPresenceStore.save(
            presence,
            ownerID: "account-a"
        )
        try await source.save(makeWorkout(), recordType: "Workout")
        let viewModel = makeViewModel(
            authClient: authClient,
            sessionStore: sessionStore,
            sessionManager: sessionManager,
            source: source,
            destination: destination,
            presenceCleanup: { ownerID in
                try await PresenceLocalStore(
                    ownerID: ownerID,
                    baseDirectoryURL: presenceDirectory
                ).clear(ownerID: ownerID)
            }
        )
        viewModel.continueAsGuest()
        await viewModel.signInWithApple()
        #expect(sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) != nil)
        #expect(destination.recordCount(for: "UserData") == 1)

        await viewModel.deleteAccount()

        let revokeCount = await authClient.revokeCount
        #expect(source.recordCount(for: "Workout") == 0)
        #expect(destination.recordCount(for: "UserData") == 0)
        #expect(
            try await guestPresenceStore.load(
                ownerID: AuthViewModel.guestUserID
            ).isEmpty
        )
        #expect(
            try await destinationPresenceStore.load(ownerID: "account-a").isEmpty
        )
        #expect(revokeCount == 1)
        #expect(sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) == nil)
        #expect(!viewModel.isAuthenticated)
    }

    @Test("pending marker survives destination cleanup failure")
    func pendingConversionDeletionRetainsMarkerWhenDestinationFails() async throws {
        let sessionStore = TestAuthSessionStore()
        let source = MockCloudKitClient()
        let destination = LifecycleDestinationClient(
            failWorkoutSaves: true,
            failDeleteAllData: true,
            markerProbe: {
                sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) != nil
            }
        )
        let sessionManager = TestAuthDataSessionManager(
            ownerID: "signed-out",
            client: MockCloudKitClient()
        )
        let authClient = TestAppleAuthClient(result: makeAuthResult())
        try await source.save(makeWorkout(), recordType: "Workout")
        let viewModel = makeViewModel(
            authClient: authClient,
            sessionStore: sessionStore,
            sessionManager: sessionManager,
            source: source,
            destination: destination
        )
        viewModel.continueAsGuest()
        await viewModel.signInWithApple()

        await viewModel.deleteAccount()

        let revokeCount = await authClient.revokeCount
        #expect(destination.recordCount(for: "UserData") == 1)
        #expect(revokeCount == 0)
        #expect(sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) != nil)
        #expect(viewModel.isAuthenticated)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("pending marker survives Apple revocation failure")
    func pendingConversionDeletionRetainsMarkerWhenRevocationFails() async throws {
        let sessionStore = TestAuthSessionStore()
        let source = MockCloudKitClient()
        let destination = LifecycleDestinationClient(
            failWorkoutSaves: true,
            markerProbe: {
                sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) != nil
            }
        )
        let sessionManager = TestAuthDataSessionManager(
            ownerID: "signed-out",
            client: MockCloudKitClient()
        )
        let authClient = TestAppleAuthClient(
            result: makeAuthResult(),
            failRevocation: true
        )
        try await source.save(makeWorkout(), recordType: "Workout")
        let viewModel = makeViewModel(
            authClient: authClient,
            sessionStore: sessionStore,
            sessionManager: sessionManager,
            source: source,
            destination: destination
        )
        viewModel.continueAsGuest()
        await viewModel.signInWithApple()

        await viewModel.deleteAccount()

        let revokeCount = await authClient.revokeCount
        #expect(destination.recordCount(for: "UserData") == 0)
        #expect(revokeCount == 1)
        #expect(sessionStore.read(key: AuthViewModel.pendingGuestMigrationKey) != nil)
        #expect(viewModel.isAuthenticated)
        #expect(viewModel.errorMessage != nil)
    }

    private func makeViewModel(
        authClient: TestAppleAuthClient,
        sessionStore: TestAuthSessionStore,
        sessionManager: TestAuthDataSessionManager,
        source: MockCloudKitClient,
        destination: LifecycleDestinationClient,
        presenceCleanup: @escaping @Sendable (String) async throws -> Void = { _ in }
    ) -> AuthViewModel {
        AuthViewModel(
            authClient: authClient,
            sessionStore: sessionStore,
            sessionManager: sessionManager,
            destinationClientFactory: { destination },
            localClientFactory: { source },
            guestMigration: { source, destination, _, _ in
                try await GuestDataMigrator(
                    source: source,
                    destination: destination
                ).migrate()
            },
            presenceCleanup: presenceCleanup,
            restoreSessionOnInit: false
        )
    }

    private func makeAuthResult() -> AppleAuthResult {
        var name = PersonNameComponents()
        name.givenName = "Avery"
        name.familyName = "Athlete"
        return AppleAuthResult(
            userID: "account-a",
            email: "avery@example.com",
            fullName: name,
            identityToken: nil,
            authorizationCode: Data("code".utf8),
            authorizedScopes: [.email, .fullName]
        )
    }

    private func makeWorkout() -> Workout {
        Workout(
            id: "guest-workout",
            date: Date(timeIntervalSince1970: 1_753_528_400),
            name: "Guest Session",
            exercises: [],
            duration: 30
        )
    }
}

private final class TestAuthSessionStore: AuthSessionStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: String] = [:]

    func read(key: String) -> String? {
        lock.withLock { values[key] }
    }

    @discardableResult
    func save(key: String, value: String) -> Bool {
        lock.withLock { values[key] = value }
        return true
    }

    @discardableResult
    func delete(key: String) -> Bool {
        _ = lock.withLock { values.removeValue(forKey: key) }
        return true
    }
}

private final class TestAuthDataSessionManager: AuthDataSessionManaging, @unchecked Sendable {
    private let lock = NSLock()
    private let activationProbe: @Sendable (String) -> Bool
    private var currentSession: DataClientFactory.Session
    private var didActivateAccountSafely = true

    init(
        ownerID: String,
        client: any DataClientProtocol,
        activationProbe: @escaping @Sendable (String) -> Bool = { _ in true }
    ) {
        currentSession = DataClientFactory.Session(ownerID: ownerID, client: client)
        self.activationProbe = activationProbe
    }

    var session: DataClientFactory.Session {
        lock.withLock { currentSession }
    }

    var accountActivationWasSafe: Bool {
        lock.withLock { didActivateAccountSafely }
    }

    func activate(client: any DataClientProtocol, ownerID: String) {
        lock.withLock {
            didActivateAccountSafely = didActivateAccountSafely
                && activationProbe(ownerID)
            currentSession = DataClientFactory.Session(ownerID: ownerID, client: client)
        }
    }
}

private actor TestAppleAuthClient: AppleAuthClientProtocol {
    private let result: AppleAuthResult
    private let failRevocation: Bool
    private(set) var signOutCount = 0
    private(set) var revokeCount = 0

    init(
        result: AppleAuthResult,
        failRevocation: Bool = false
    ) {
        self.result = result
        self.failRevocation = failRevocation
    }

    func signIn(scopes: AppleAuthScope) async throws -> AppleAuthResult {
        result
    }

    func getCredentialState(forUserID userID: String) async throws -> AppleCredentialState {
        .authorized
    }

    func signOut() async {
        signOutCount += 1
    }

    func revokeToken(authorizationCode: Data?) async throws {
        revokeCount += 1
        if failRevocation {
            throw AuthError.authorizationFailed(underlying: nil)
        }
    }
}

private final class LifecycleDestinationClient: DataClientProtocol, @unchecked Sendable {
    private let backing = MockCloudKitClient()
    private let lock = NSLock()
    private let markerProbe: @Sendable () -> Bool
    private var hasObservedFirstSave = false
    private var didSeeMarker = false
    private var shouldFailWorkoutSaves: Bool
    private let failDeleteAllData: Bool

    init(
        failWorkoutSaves: Bool = false,
        failDeleteAllData: Bool = false,
        markerProbe: @escaping @Sendable () -> Bool
    ) {
        shouldFailWorkoutSaves = failWorkoutSaves
        self.failDeleteAllData = failDeleteAllData
        self.markerProbe = markerProbe
    }

    var failWorkoutSaves: Bool {
        get { lock.withLock { shouldFailWorkoutSaves } }
        set { lock.withLock { shouldFailWorkoutSaves = newValue } }
    }

    var markerWasPresentAtFirstSave: Bool {
        lock.withLock { didSeeMarker }
    }

    func recordCount(for recordType: String) -> Int {
        backing.recordCount(for: recordType)
    }

    func fetch<T>(
        recordType: String,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]?
    ) async throws -> [T] where T: Decodable & Sendable {
        try await backing.fetch(
            recordType: recordType,
            predicate: predicate,
            sortDescriptors: sortDescriptors
        )
    }

    func save<T>(
        _ records: [T],
        recordType: String
    ) async throws where T: Encodable & Sendable {
        lock.withLock {
            if !hasObservedFirstSave {
                hasObservedFirstSave = true
                didSeeMarker = markerProbe()
            }
        }
        if recordType == "Workout", failWorkoutSaves {
            throw DataError.networkError(underlying: nil)
        }
        try await backing.save(records, recordType: recordType)
    }

    func delete(
        recordIDs: [CKRecord.ID],
        recordType: String
    ) async throws {
        try await backing.delete(recordIDs: recordIDs, recordType: recordType)
    }

    func deleteAllData() async throws {
        if failDeleteAllData {
            throw DataError.networkError(underlying: nil)
        }
        try await backing.deleteAllData()
    }

    func saveFromJSON(
        _ jsonRecords: [Data],
        recordType: String
    ) async throws {
        try await backing.saveFromJSON(jsonRecords, recordType: recordType)
    }
}
