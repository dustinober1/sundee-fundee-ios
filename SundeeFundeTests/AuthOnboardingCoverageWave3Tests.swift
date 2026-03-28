import Testing
import Foundation
import SwiftData
import AuthenticationServices
import SwiftUI
import UIKit
@testable import SundeeFundee

@Suite("AuthOnboarding Wave3", .serialized)
struct AuthOnboardingCoverageWave3Tests {
    @MainActor
    private func makeContext() throws -> ModelContext {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)  // ModelContext strongly holds container, keeping it alive for async tasks
    }

    @Test
    @MainActor
    func signInDecisionAndStateChangeBranches() {
        #expect(SignInView.requestedScopes() == [.fullName])
        #expect(SignInView.controlsDisabled(isBusy: true) == true)
        #expect(SignInView.controlsDisabled(isBusy: false) == false)
        #expect(SignInView.shouldShowError(message: "error") == true)
        #expect(SignInView.shouldShowError(message: nil) == false)
        #expect(SignInView.showsBusyOverlay(isBusy: true) == true)
        #expect(SignInView.showsBusyOverlay(isBusy: false) == false)

        let cancelled = NSError(domain: "test", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Cancelled"])
        switch SignInView.decision(for: .failure(cancelled)) {
        case .showError(let message):
            #expect(message == nil)
        default:
            Issue.record("Expected cancelled sign-in to map to showError(nil)")
        }

        let failed = NSError(domain: "test", code: 9, userInfo: [NSLocalizedDescriptionKey: "Auth failed"])
        switch SignInView.decision(for: .failure(failed)) {
        case .showError(let message):
            #expect(message == "Auth failed")
            let state = SignInView.stateChange(for: .showError(message))
            #expect(state.isBusy == false)
            #expect(state.errorMessage == "Auth failed")
        default:
            Issue.record("Expected non-cancelled sign-in error to surface message")
        }

        if case .ignore = SignInView.decision(for: .success(.unsupportedCredential)) {
            // expected
        } else {
            Issue.record("Expected unsupported credential to be ignored")
        }

        var name = PersonNameComponents()
        name.givenName = "Alex"
        name.familyName = "Ray"
        let successDecision = SignInView.decision(
            for: .success(.appleID(userID: "apple-1", fullName: name, email: "alex@example.com"))
        )
        switch successDecision {
        case .resolveCredential(let userID, let fullName, let email):
            #expect(userID == "apple-1")
            #expect(fullName?.givenName == "Alex")
            #expect(email == "alex@example.com")
            let state = SignInView.stateChange(for: successDecision)
            #expect(state.isBusy)
            #expect(state.errorMessage == nil)
            #expect(state.resolutionContext?.userID == "apple-1")
        default:
            Issue.record("Expected success decision to resolve credential")
        }

        let payloadFailure = SignInView.payload(from: .failure(failed))
        switch payloadFailure {
        case .failure(let error as NSError):
            #expect(error.code == 9)
        default:
            Issue.record("Expected payload conversion to preserve error")
        }
    }

    @Test
    @MainActor
    func sessionRestorationActionBranches() {
        #expect(AuthService.sessionRestorationAction(for: .authorized) == .resolveAuthorized)
        #expect(AuthService.sessionRestorationAction(for: .revoked) == .signedOut(shouldDeleteStoredUserID: true))
        #expect(AuthService.sessionRestorationAction(for: .notFound) == .signedOut(shouldDeleteStoredUserID: true))
        #expect(AuthService.sessionRestorationAction(for: .transferred) == .signedOut(shouldDeleteStoredUserID: true))

        let unknown = unsafeBitCast(Int.max, to: ASAuthorizationAppleIDProvider.CredentialState.self)
        #expect(AuthService.sessionRestorationAction(for: unknown) == .signedOut(shouldDeleteStoredUserID: false))
    }

    @Test
    @MainActor
    func resolveAfterAppleSignInAndRestoreSessionBranches() async throws {
        final class DepState: @unchecked Sendable {
            var saved: [String] = []
            var storedUserID: String?
            var deleted: [String] = []
            var credential: ASAuthorizationAppleIDProvider.CredentialState = .notFound
        }

        let state = DepState()
        let context = try makeContext()
        context.insert(
            User(
                id: "existing-user",
                name: "Existing",
                experienceLevel: .beginner,
                primaryGoal: .strength,
                gender: .preferNotToSay,
                appleUserID: "existing-apple-id",
                onboardingComplete: false
            )
        )
        try context.save()

        let service = AuthService(
            dependencies: .init(
                saveAppleUserID: { state.saved.append($0) },
                loadAppleUserID: { state.storedUserID },
                deleteAppleUserID: {
                    if let id = state.storedUserID { state.deleted.append(id) }
                },
                credentialStateForUserID: { _ in state.credential },
                makeUUID: { "generated-user-id" }
            )
        )

        let signedIn = await service.resolveAfterAppleSignIn(
            appleUserID: "new-apple-id",
            fullName: nil,
            email: nil,
            modelContext: context
        )
        if case .needsOnboarding(let userID, let appleUserID) = signedIn {
            #expect(userID == "generated-user-id")
            #expect(appleUserID == "new-apple-id")
        } else {
            Issue.record("Expected new apple sign-in user to require onboarding")
        }
        #expect(state.saved == ["new-apple-id"])

        state.storedUserID = nil
        if case .signedOut = await service.restoreSession(modelContext: context) {
            // expected
        } else {
            Issue.record("Expected signedOut without stored user id")
        }

        state.storedUserID = "existing-apple-id"
        state.credential = .authorized
        if case .needsOnboarding(let userID, let appleUserID) = await service.restoreSession(modelContext: context) {
            #expect(userID == "existing-user")
            #expect(appleUserID == "existing-apple-id")
        } else {
            Issue.record("Expected authorized restore to return existing onboarding user")
        }

        state.credential = .revoked
        _ = await service.restoreSession(modelContext: context)
        state.credential = .transferred
        _ = await service.restoreSession(modelContext: context)
        #expect(state.deleted == ["existing-apple-id", "existing-apple-id"])
    }

    @Test
    func onboardingAnswerApplicationResolvesCycleBranch() {
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let user = User(
            id: "wave3-onboarding-user",
            name: "",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            appleUserID: "apple-wave3"
        )

        OnboardingFlowView.applyOnboardingAnswers(
            to: user,
            experienceLevel: .intermediate,
            primaryGoal: .hypertrophy,
            gender: .male,
            cycleTrackingEnabled: true,
            updatedAt: updatedAt
        )
        #expect(user.experienceLevel == .intermediate)
        #expect(user.primaryGoal == .hypertrophy)
        #expect(user.gender == .male)
        #expect(user.cycleTrackingEnabled == false)
        #expect(user.onboardingComplete == true)
        #expect(user.profileUpdatedAt == updatedAt)

        OnboardingFlowView.applyOnboardingAnswers(
            to: user,
            experienceLevel: .advanced,
            primaryGoal: .endurance,
            gender: .female,
            cycleTrackingEnabled: true,
            updatedAt: updatedAt
        )
        #expect(user.cycleTrackingEnabled == true)
    }

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @MainActor
    private func render<V: View>(_ view: V) {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.loadViewIfNeeded()
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.beginAppearanceTransition(true, animated: false)
        host.endAppearanceTransition()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        #expect(host.view != nil)
    }

    @Test
    @MainActor
    func appRootDestinationAndRestoreBranches() async throws {
        #expect(AppRootView.destination(for: .loading) == .loading)
        #expect(AppRootView.destination(for: .signedOut) == .signedOut)
        #expect(
            AppRootView.destination(for: .needsOnboarding(userID: "wave3-user", appleUserID: "wave3-apple")) ==
            .onboarding(userID: "wave3-user")
        )
        #expect(AppRootView.destination(for: .authenticated(userID: "wave3-auth-user")) == .mainTabs)
        #expect(AppRootView.destination(for: .guest) == .mainTabs)

        KeychainHelper.deleteAppleUserID()
        let appState = AppState()
        await AppRootView.restoreSession(into: appState, modelContext: try makeContext())

        if case .signedOut = appState.authState {
            // expected
        } else {
            Issue.record("Expected restore without stored user to sign out")
        }
        #expect(appState.currentUserID == nil)
    }

    @Test
    @MainActor
    func appRootSignInAndOnboardingRenderingBranches() throws {
        let container = try makeContainer()

        let loadingState = AppState()
        loadingState.apply(.loading)
        render(AppRootView(initialAppState: loadingState, shouldRestoreSession: false).modelContainer(container))

        let signedOutState = AppState()
        signedOutState.apply(.signedOut)
        render(AppRootView(initialAppState: signedOutState, shouldRestoreSession: false).modelContainer(container))

        let onboardingState = AppState()
        onboardingState.apply(.needsOnboarding(userID: "wave3-onboarding-user", appleUserID: "wave3-apple-user"))
        render(AppRootView(initialAppState: onboardingState, shouldRestoreSession: false).modelContainer(container))

        render(SignInView().environment(AppState()).modelContainer(container))
        render(SignInView(initialErrorMessage: "Sign in failed").environment(AppState()).modelContainer(container))
        render(SignInView(initialIsBusy: true).environment(AppState()).modelContainer(container))

        switch SignInView.payload(from: "not-an-apple-credential") {
        case .unsupportedCredential:
            break
        case .appleID:
            Issue.record("Expected non-Apple credential payload to be unsupported")
        }

        let ignored = SignInView.stateChange(for: .ignore)
        #expect(ignored.isBusy == false)
        #expect(ignored.errorMessage == nil)
        #expect(ignored.resolutionContext == nil)

        render(
            OnboardingFlowView(userID: "wave3-onboarding-user", initialStep: .experience)
                .environment(AppState())
                .modelContainer(container)
        )
        render(
            OnboardingFlowView(userID: "wave3-onboarding-user", initialStep: .goal)
                .environment(AppState())
                .modelContainer(container)
        )
        render(
            OnboardingFlowView(userID: "wave3-onboarding-user", initialStep: .gender)
                .environment(AppState())
                .modelContainer(container)
        )
        render(
            OnboardingFlowView(
                userID: "wave3-onboarding-user",
                initialStep: .cycle,
                initialGender: .female,
                initialCycleTrackingEnabled: true
            )
            .environment(AppState())
            .modelContainer(container)
        )
        render(OnboardingStepView(title: "Step", subtitle: "Subtitle") { Text("Body") })
        render(SelectionRow(title: "Option", subtitle: "Details", isSelected: true) {})
        render(SelectionRow(title: "Option", subtitle: nil, isSelected: false) {})
        render(LoadingView())
    }

    @Test
    @MainActor
    func authServiceDisplayAndRestoreAdditionalBranches() async throws {
        final class DepState: @unchecked Sendable {
            var saved: [String] = []
            var storedUserID: String?
            var deleted: [String] = []
            var credential: ASAuthorizationAppleIDProvider.CredentialState = .notFound
            var generated = 0
        }

        let depState = DepState()
        let context = try makeContext()
        context.insert(
            User(
                id: "wave3-existing-complete",
                name: "Existing Complete",
                experienceLevel: .intermediate,
                primaryGoal: .strength,
                gender: .female,
                appleUserID: "wave3-existing-apple",
                onboardingComplete: true
            )
        )
        try context.save()

        let service = AuthService(
            dependencies: .init(
                saveAppleUserID: { depState.saved.append($0) },
                loadAppleUserID: { depState.storedUserID },
                deleteAppleUserID: {
                    if let id = depState.storedUserID { depState.deleted.append(id) }
                },
                credentialStateForUserID: { _ in depState.credential },
                makeUUID: {
                    depState.generated += 1
                    return "wave3-generated-\(depState.generated)"
                }
            )
        )

        if case .authenticated(let userID) = await service.resolveAfterAppleSignIn(
            appleUserID: "wave3-existing-apple",
            modelContext: context
        ) {
            #expect(userID == "wave3-existing-complete")
        } else {
            Issue.record("Expected existing completed user to authenticate")
        }
        #expect(depState.saved == ["wave3-existing-apple"])

        if case .needsOnboarding(let userID, let appleUserID) = await service.resolveAfterCredential(
            userID: "wave3-wrapper-apple",
            modelContext: context
        ) {
            #expect(userID.hasPrefix("wave3-generated-"))
            #expect(appleUserID == "wave3-wrapper-apple")
        } else {
            Issue.record("Expected wrapper credential resolver to route new user into onboarding")
        }
        #expect(depState.saved == ["wave3-existing-apple", "wave3-wrapper-apple"])

        var fullName = PersonNameComponents()
        fullName.givenName = "Riley"
        fullName.familyName = "Stone"
        if case .needsOnboarding(let userID, let appleUserID) = await service.resolveAuthState(
            appleUserID: "wave3-new-apple",
            fullName: fullName,
            modelContext: context
        ) {
            #expect(userID.hasPrefix("wave3-generated-"))
            #expect(appleUserID == "wave3-new-apple")
        } else {
            Issue.record("Expected new user to enter onboarding")
        }

        let newUserDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserID == "wave3-new-apple" }
        )
        let newUsers = try context.fetch(newUserDescriptor)
        #expect(newUsers.first?.name == "Riley Stone")

        #expect(AuthService.displayName(from: fullName) == "Riley Stone")
        var givenOnly = PersonNameComponents()
        givenOnly.givenName = "Solo"
        #expect(AuthService.displayName(from: givenOnly) == "Solo")
        #expect(AuthService.displayName(from: nil) == "")

        depState.storedUserID = "wave3-existing-apple"
        depState.credential = .authorized
        if case .authenticated(let userID) = await service.restoreSession(modelContext: context) {
            #expect(userID == "wave3-existing-complete")
        } else {
            Issue.record("Expected authorized restore to authenticate complete user")
        }

        let unknown = unsafeBitCast(Int.max, to: ASAuthorizationAppleIDProvider.CredentialState.self)
        depState.credential = unknown
        if case .signedOut = await service.restoreSession(modelContext: context) {
            // expected
        } else {
            Issue.record("Expected unknown restore state to sign out")
        }
        #expect(depState.deleted.isEmpty)

        let completeUser = User(
            id: "wave3-existing-complete",
            name: "Existing Complete",
            experienceLevel: .intermediate,
            primaryGoal: .strength,
            gender: .female,
            appleUserID: "wave3-existing-apple",
            onboardingComplete: true
        )
        if case .authenticated(let userID) = AuthService.authState(
            for: completeUser,
            appleUserID: "wave3-existing-apple"
        ) {
            #expect(userID == "wave3-existing-complete")
        } else {
            Issue.record("Expected static auth state helper to authenticate completed user")
        }

        let incompleteUser = User(
            id: "wave3-incomplete-user",
            name: "Incomplete",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            appleUserID: "wave3-incomplete-apple",
            onboardingComplete: false
        )
        if case .needsOnboarding(let userID, let appleUserID) = AuthService.authState(
            for: incompleteUser,
            appleUserID: "wave3-incomplete-apple"
        ) {
            #expect(userID == "wave3-incomplete-user")
            #expect(appleUserID == "wave3-incomplete-apple")
        } else {
            Issue.record("Expected static auth state helper to route incomplete user to onboarding")
        }
    }

    @Test
    @MainActor
    func authServiceLiveDependenciesAndAuthErrorBranches() {
        let live = AuthService.Dependencies.live
        live.deleteAppleUserID()
        live.saveAppleUserID("wave3-live-apple")
        _ = live.loadAppleUserID()
        _ = live.makeUUID()
        live.deleteAppleUserID()

        #expect(AuthError.invalidCredential.errorDescription == "Invalid Apple credential received.")
        #expect(AuthError.cancelled.errorDescription == "Sign in was cancelled.")
    }

    @Test
    @MainActor
    func onboardingPersistenceAndDisplayBranches() throws {
        let context = try makeContext()
        let appState = AppState()
        let user = User(
            id: "wave3-persist-user",
            name: "",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            appleUserID: "wave3-persist-apple",
            onboardingComplete: false
        )
        context.insert(user)
        try context.save()

        #expect(OnboardingFlowView.nextVisibleStep(from: .experience, gender: .male) == .goal)
        #expect(OnboardingFlowView.previousVisibleStep(from: .cycle, gender: .female) == .gender)

        #expect(ExperienceLevel.beginner.displayName == "Beginner")
        #expect(ExperienceLevel.intermediate.displayName == "Intermediate")
        #expect(ExperienceLevel.advanced.displayName == "Advanced")
        #expect(ExperienceLevel.beginner.subtitle == "0–2 years of consistent training")
        #expect(PrimaryGoal.strength.displayName == "Strength")
        #expect(PrimaryGoal.hypertrophy.displayName == "Muscle building")
        #expect(PrimaryGoal.endurance.displayName == "Endurance")
        #expect(PrimaryGoal.weightLoss.displayName == "Weight loss")
        #expect(Gender.male.displayName == "Male")
        #expect(Gender.female.displayName == "Female")
        #expect(Gender.preferNotToSay.displayName == "Prefer not to say")

        let updatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let persisted = OnboardingFlowView.persistOnboardingAnswers(
            userID: "wave3-persist-user",
            experienceLevel: .advanced,
            primaryGoal: .endurance,
            gender: .female,
            cycleTrackingEnabled: true,
            modelContext: context,
            appState: appState,
            updatedAt: updatedAt
        )
        #expect(persisted)
        #expect(user.experienceLevel == .advanced)
        #expect(user.primaryGoal == .endurance)
        #expect(user.gender == .female)
        #expect(user.cycleTrackingEnabled == true)
        #expect(user.onboardingComplete == true)
        #expect(user.profileUpdatedAt == updatedAt)

        if case .authenticated(let userID) = appState.authState {
            #expect(userID == "wave3-persist-user")
        } else {
            Issue.record("Expected persistence to authenticate user")
        }

        let missingState = AppState()
        let missing = OnboardingFlowView.persistOnboardingAnswers(
            userID: "missing-wave3-user",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .male,
            cycleTrackingEnabled: true,
            modelContext: context,
            appState: missingState,
            updatedAt: updatedAt
        )
        #expect(missing == false)
        if case .loading = missingState.authState {
            // expected
        } else {
            Issue.record("Expected missing user save to preserve auth state")
        }
    }
}
