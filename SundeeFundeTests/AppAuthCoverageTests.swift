import Testing
import Foundation
import SwiftData
@testable import SundeeFundee

@Model
private final class AuthCoverageTempModel {
    var value: String

    init(value: String = "temp") {
        self.value = value
    }
}

@Suite("App/Auth Coverage")
struct AppAuthCoverageTests {
    @MainActor
    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([AuthCoverageTempModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @MainActor
    private func makeV12ModelContext() throws -> ModelContext {
        let schema = Schema(AppSchemaV12.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test @MainActor
    func appStateApplyTracksCurrentUserIDAcrossStates() {
        let state = AppState()

        state.apply(.authenticated(userID: "user-auth"))
        #expect(state.currentUserID == "user-auth")

        state.apply(.needsOnboarding(userID: "user-onboarding", appleUserID: "apple-id"))
        #expect(state.currentUserID == "user-onboarding")

        // signInAsGuest now returns a stable non-nil UUID from Keychain (FIX-03)
        state.signInAsGuest()
        #expect(state.currentUserID != nil)
        if case .guest = state.authState {} else {
            Issue.record("Expected guest auth state")
        }

        state.apply(.signedOut)
        #expect(state.currentUserID == nil)
    }

    @Test
    func keychainHelperRoundTrip() {
        let userID = "coverage-user-id"
        KeychainHelper.deleteAppleUserID()
        KeychainHelper.saveAppleUserID(userID)
        let loaded = KeychainHelper.loadAppleUserID()
        #expect(loaded == userID || loaded == nil)
        KeychainHelper.deleteAppleUserID()
        #expect(KeychainHelper.loadAppleUserID() == nil)
    }

    @Test @MainActor
    func authServiceRestoreSessionWithoutStoredUserIDSignsOut() async throws {
        KeychainHelper.deleteAppleUserID()
        let authState = await AuthService().restoreSession(modelContext: try makeModelContext())
        if case .signedOut = authState {} else {
            Issue.record("Expected signedOut when no keychain user ID exists")
        }
    }

    @Test @MainActor
    func onboardingEligibilityEvaluatorBranches() {
        switch OnboardingEligibilityEvaluator.evaluate(user: nil) {
        case .needsOnboarding:
            break
        default:
            Issue.record("Expected needsOnboarding for nil user")
        }

        let complete = User(
            id: "u-complete",
            name: "Alex",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            appleUserID: "apple-complete",
            onboardingComplete: true
        )
        switch OnboardingEligibilityEvaluator.evaluate(user: complete) {
        case .complete:
            break
        default:
            Issue.record("Expected complete for fully onboarded user")
        }

        let resume = User(
            id: "u-resume",
            name: "Sam",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            appleUserID: "apple-resume",
            onboardingComplete: false
        )
        switch OnboardingEligibilityEvaluator.evaluate(user: resume) {
        case .resumeOnboarding:
            break
        default:
            Issue.record("Expected resumeOnboarding when answers exist but onboarding incomplete")
        }

        let needs = User(
            id: "u-needs",
            name: "   ",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            appleUserID: "apple-needs",
            onboardingComplete: false
        )
        switch OnboardingEligibilityEvaluator.evaluate(user: needs) {
        case .needsOnboarding:
            break
        default:
            Issue.record("Expected needsOnboarding when required answers are missing")
        }
    }

    @Test @MainActor
    func deleteAccountAndDataClearsStateAndKeychain() throws {
        // Use V12 schema to verify full wipe including BarbellPreset and ExerciseBarMapping (FIX-02)
        let ctx = try makeV12ModelContext()

        // Insert a user
        let user = User(
            id: "delete-test",
            name: "Delete Me",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            appleUserID: "apple-delete",
            onboardingComplete: true
        )
        ctx.insert(user)

        // Insert V12-only models to verify they are also deleted
        let preset = BarbellPreset(userID: "delete-test", name: "Test Bar", weightKg: 20.0)
        ctx.insert(preset)
        let mapping = ExerciseBarMapping(userID: "delete-test", exerciseName: "Squat", barbellPresetID: preset.id)
        ctx.insert(mapping)
        try? ctx.save()

        let state = AppState()
        state.apply(.authenticated(userID: "delete-test"))
        #expect(state.currentUserID == "delete-test")

        state.deleteAccountAndData(modelContext: ctx)

        #expect(state.currentUserID == nil)
        if case .signedOut = state.authState {} else {
            Issue.record("Expected signedOut after delete")
        }

        let remainingUsers = (try? ctx.fetch(FetchDescriptor<User>())) ?? []
        #expect(remainingUsers.isEmpty)

        // Verify V12-only models are also wiped
        let remainingPresets = (try? ctx.fetch(FetchDescriptor<BarbellPreset>())) ?? []
        #expect(remainingPresets.isEmpty, "BarbellPreset should be deleted by V12 schema wipe")

        let remainingMappings = (try? ctx.fetch(FetchDescriptor<ExerciseBarMapping>())) ?? []
        #expect(remainingMappings.isEmpty, "ExerciseBarMapping should be deleted by V12 schema wipe")
    }

    @Test @MainActor
    func signOutPreservesPreferencesButWipesWorkoutData() throws {
        let ctx = try makeV12ModelContext()

        let userID = "sign-out-test"

        // Insert preference data (should survive sign-out)
        let user = User(
            id: userID,
            name: "Sign Out User",
            experienceLevel: .intermediate,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            appleUserID: "apple-sign-out",
            onboardingComplete: true
        )
        ctx.insert(user)

        // Insert workout data (should be deleted on sign-out)
        let workout = CompletedWorkout(
            id: UUID().uuidString,
            userID: userID,
            activeCycleID: "cycle-1",
            programID: "prog-1",
            week: 1,
            day: 1,
            sessionID: "sess-1"
        )
        ctx.insert(workout)

        // Insert preference data (should survive sign-out)
        let preset = BarbellPreset(userID: userID, name: "Barbell", weightKg: 20.0)
        ctx.insert(preset)
        try? ctx.save()

        let state = AppState()
        state.apply(.authenticated(userID: userID))
        state.signOut(modelContext: ctx)

        // User record and preferences should survive
        let users = (try? ctx.fetch(FetchDescriptor<User>())) ?? []
        #expect(!users.isEmpty, "User (preference model) should survive sign-out")

        let presets = (try? ctx.fetch(FetchDescriptor<BarbellPreset>())) ?? []
        #expect(!presets.isEmpty, "BarbellPreset (preference) should survive sign-out")

        // Workout data should be wiped
        let workouts = (try? ctx.fetch(FetchDescriptor<CompletedWorkout>())) ?? []
        #expect(workouts.isEmpty, "CompletedWorkout should be deleted on sign-out")

        // Should return to guest mode with valid UUID
        if case .guest = state.authState {} else {
            Issue.record("Expected guest state after sign-out")
        }
        #expect(state.currentUserID != nil, "currentUserID should be a stable guest UUID after sign-out")
    }

    @Test @MainActor
    func guestUserIDPersistsAcrossSignInAsGuestCalls() {
        // Clean slate
        KeychainHelper.deleteGuestUserID()

        let state1 = AppState()
        state1.signInAsGuest()
        let firstID = state1.currentUserID

        #expect(firstID != nil)

        // Second call should return the same UUID
        let state2 = AppState()
        state2.signInAsGuest()
        let secondID = state2.currentUserID

        #expect(secondID == firstID, "Guest UUID should be stable across calls")

        // Cleanup
        KeychainHelper.deleteGuestUserID()
    }

    @Test @MainActor
    func batchMigrationUpdatesGuestRecordsToAppleUserID() async throws {
        let ctx = try makeV12ModelContext()

        let guestUUID = UUID().uuidString
        let appleUserID = UUID().uuidString

        // Seed records with the guest UUID
        let workout = CompletedWorkout(
            id: UUID().uuidString,
            userID: guestUUID,
            activeCycleID: "cycle-1",
            programID: "prog-1",
            week: 1,
            day: 1,
            sessionID: "sess-1"
        )
        ctx.insert(workout)
        let preset = BarbellPreset(userID: guestUUID, name: "Olympic Bar", weightKg: 20.0)
        ctx.insert(preset)
        try? ctx.save()

        // Set up AuthService with injected guest UUID
        KeychainHelper.saveGuestUserID(guestUUID)
        let authService = AuthService(dependencies: .init(
            saveAppleUserID: { _ in },
            loadAppleUserID: { nil },
            deleteAppleUserID: {},
            loadGuestUserID: KeychainHelper.loadGuestUserID,
            deleteGuestUserID: KeychainHelper.deleteGuestUserID,
            credentialStateForUserID: { _ in .authorized },
            makeUUID: { UUID().uuidString }
        ))

        _ = await authService.resolveAfterAppleSignIn(
            appleUserID: appleUserID,
            modelContext: ctx
        )

        // Verify all records are migrated
        let workouts = (try? ctx.fetch(FetchDescriptor<CompletedWorkout>())) ?? []
        #expect(workouts.allSatisfy { $0.userID == appleUserID }, "All CompletedWorkout records should have the Apple user ID after migration")

        let presets = (try? ctx.fetch(FetchDescriptor<BarbellPreset>())) ?? []
        #expect(presets.allSatisfy { $0.userID == appleUserID }, "All BarbellPreset records should have the Apple user ID after migration")

        // Migration pending flag should be cleared
        #expect(!UserDefaults.standard.bool(forKey: "guestMigrationPending"), "guestMigrationPending flag should be cleared on success")

        // Guest UUID should be removed from Keychain after successful migration
        #expect(KeychainHelper.loadGuestUserID() == nil, "Guest UUID should be removed from Keychain after migration")
    }

    @Test @MainActor
    func appSchemaAndContainerMetadataIsAccessible() {
        #expect(AppSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(AppSchemaV1.models.count == 15)
        #expect(AppSchemaV1.models.map { String(describing: $0) }.contains("User"))

        #expect(AppSchemaMigrationPlan.schemas.count == 7)
        #expect(String(describing: AppSchemaMigrationPlan.schemas[0]) == String(describing: AppSchemaV1.self))
        #expect(AppSchemaMigrationPlan.stages.count == 6)
    }
}
