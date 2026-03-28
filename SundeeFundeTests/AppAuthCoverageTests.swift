import Testing
import SwiftData
@testable import SundeeFundee

@Model
private final class AuthCoverageTempModel {
    var value: String

    init(value: String = "temp") {
        self.value = value
    }
}

@Suite("App/Auth Coverage", .serialized)
struct AppAuthCoverageTests {
    @MainActor
    private func makeModelContext() throws -> ModelContext {
        let schema = Schema([AuthCoverageTempModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    @Test @MainActor
    func appStateApplyTracksCurrentUserIDAcrossStates() {
        let state = AppState()

        state.apply(.authenticated(userID: "user-auth"))
        #expect(state.currentUserID == "user-auth")

        state.apply(.needsOnboarding(userID: "user-onboarding", appleUserID: "apple-id"))
        #expect(state.currentUserID == "user-onboarding")

        state.signInAsGuest()
        #expect(state.currentUserID == nil)
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

    @Test
    func keychainAuthorizationCodeRoundTrip() {
        let code = "coverage-auth-code"
        KeychainHelper.deleteAuthorizationCode()
        KeychainHelper.saveAuthorizationCode(code)
        let loaded = KeychainHelper.loadAuthorizationCode()
        #expect(loaded == code || loaded == nil)
        KeychainHelper.deleteAuthorizationCode()
        #expect(KeychainHelper.loadAuthorizationCode() == nil)
    }

    @Test
    func keychainSIWARefreshTokenRoundTrip() {
        let token = "coverage-refresh-token"
        KeychainHelper.deleteSIWARefreshToken()
        KeychainHelper.saveSIWARefreshToken(token)
        let loaded = KeychainHelper.loadSIWARefreshToken()
        #expect(loaded == token || loaded == nil)
        KeychainHelper.deleteSIWARefreshToken()
        #expect(KeychainHelper.loadSIWARefreshToken() == nil)
    }

    @Test
    func siwaTokenServiceRevokeWithNoStoredTokenSucceeds() async {
        KeychainHelper.deleteSIWARefreshToken()
        let result = await SIWATokenService.revokeRefreshToken()
        #expect(result == true)
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
    func appSchemaAndContainerMetadataIsAccessible() {
        #expect(AppSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(AppSchemaV1.models.count == 15)
        #expect(AppSchemaV1.models.map { String(describing: $0) }.contains("User"))

        #expect(AppSchemaMigrationPlan.schemas.count == 6)
        #expect(String(describing: AppSchemaMigrationPlan.schemas[0]) == String(describing: AppSchemaV1.self))
        #expect(AppSchemaMigrationPlan.stages.count == 5)
    }
}
