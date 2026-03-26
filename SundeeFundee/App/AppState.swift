import SwiftUI
import SwiftData
import AuthenticationServices

/// Top-level auth state that drives routing.
enum AuthState {
    case loading
    case signedOut
    case needsOnboarding(userID: String, appleUserID: String)
    case authenticated(userID: String)
    case guest
}

@Observable
@MainActor
final class AppState {
    var authState: AuthState = .loading
    var currentUserID: String?
    var subscriptionTier: SubscriptionTier = .premium

    let authService = AuthService()

    func signInAsGuest() {
        authState = .guest
        currentUserID = nil
    }

    func signOut() {
        KeychainHelper.deleteAppleUserID()
        authState = .signedOut
        currentUserID = nil
    }

    func apply(_ state: AuthState) {
        authState = state
        if case .authenticated(let id) = state { currentUserID = id }
        else if case .needsOnboarding(let id, _) = state { currentUserID = id }
        else { currentUserID = nil }
    }

    // MARK: - Account Deletion

    func deleteAccount(modelContext: ModelContext) async {
        guard let userID = currentUserID else { return }

        // Revoke Sign in with Apple credential before clearing keychain.
        if let appleUserID = KeychainHelper.loadAppleUserID() {
            await Self.revokeAppleCredential(appleUserID: appleUserID)
        }

        Self.deleteAllUserData(modelContext: modelContext, userID: userID)
        KeychainHelper.deleteAuthorizationCode()
        KeychainHelper.deleteAppleUserID()
        authState = .signedOut
        currentUserID = nil
    }

    /// Best-effort SIWA credential revocation.
    /// Full token revocation requires a server-side endpoint that can generate
    /// a client_secret JWT and call POST https://appleid.apple.com/auth/revoke.
    /// This client-side check verifies credential state and logs the gap.
    private static func revokeAppleCredential(appleUserID: String) async {
        let provider = ASAuthorizationAppleIDProvider()
        let state = (try? await provider.credentialState(forUserID: appleUserID)) ?? .notFound
        if state == .authorized {
            // TODO: Call server-side token revocation endpoint.
            // The authorization code saved during sign-in can be exchanged for
            // a refresh token, which is then used to revoke via Apple's REST API.
            // This requires a backend (e.g. Cloudflare Worker) that holds the
            // .p8 private key and generates the client_secret JWT.
            print("[AccountDeletion] SIWA credential still authorized — server-side revocation needed")
        }
    }

    static func deleteAllUserData(modelContext: ModelContext, userID: String) {
        // Workouts
        deleteAll(modelContext, FetchDescriptor<CompletedSet>(predicate: #Predicate { $0.userID == userID }))
        deleteAll(modelContext, FetchDescriptor<CompletedWorkout>(predicate: #Predicate { $0.userID == userID }))
        deleteAll(modelContext, FetchDescriptor<GeneratedWorkoutRecord>(predicate: #Predicate { $0.userID == userID }))

        // Maxes & PRs
        deleteAll(modelContext, FetchDescriptor<OneRepMax>(predicate: #Predicate { $0.userID == userID }))
        deleteAll(modelContext, FetchDescriptor<PersonalRecord>(predicate: #Predicate { $0.userID == userID }))
        deleteAll(modelContext, FetchDescriptor<LiftMax>(predicate: #Predicate { $0.userID == userID }))
        deleteAll(modelContext, FetchDescriptor<ConditioningPR>(predicate: #Predicate { $0.userID == userID }))

        // Benchmarks
        deleteAll(modelContext, FetchDescriptor<BenchmarkResult>(predicate: #Predicate { $0.userID == userID }))
        deleteAll(modelContext, FetchDescriptor<BenchmarkDefinition>(predicate: #Predicate { $0.userID == userID }))

        // Cycle
        deleteAll(modelContext, FetchDescriptor<ActiveCycle>(predicate: #Predicate { $0.userID == userID }))
        deleteAll(modelContext, FetchDescriptor<PeriodLog>(predicate: #Predicate { $0.userID == userID }))
        deleteAll(modelContext, FetchDescriptor<SymptomLog>(predicate: #Predicate { $0.userID == userID }))
        deleteAll(modelContext, FetchDescriptor<CycleSettings>(predicate: #Predicate { $0.userID == userID }))
        deleteAll(modelContext, FetchDescriptor<CycleAdaptationPreferences>(predicate: #Predicate { $0.userID == userID }))

        // Injuries + PainLogs (child records)
        if let injuries = try? modelContext.fetch(FetchDescriptor<InjuryProfile>(predicate: #Predicate { $0.userID == userID })) {
            for injury in injuries {
                let injuryID = injury.id
                deleteAll(modelContext, FetchDescriptor<PainLog>(predicate: #Predicate { $0.injuryProfileID == injuryID }))
                modelContext.delete(injury)
            }
        }

        // Enrollments + Events (child records)
        if let enrollments = try? modelContext.fetch(FetchDescriptor<EnrolledProgram>(predicate: #Predicate { $0.userID == userID })) {
            for enrollment in enrollments {
                let enrollmentID = enrollment.id
                deleteAll(modelContext, FetchDescriptor<EnrollmentEvent>(predicate: #Predicate { $0.enrollmentID == enrollmentID }))
                modelContext.delete(enrollment)
            }
        }

        // User record last
        deleteAll(modelContext, FetchDescriptor<User>(predicate: #Predicate { $0.id == userID }))

        try? modelContext.save()
    }

    private static func deleteAll<T: PersistentModel>(_ context: ModelContext, _ descriptor: FetchDescriptor<T>) {
        if let items = try? context.fetch(descriptor) {
            for item in items { context.delete(item) }
        }
    }
}
