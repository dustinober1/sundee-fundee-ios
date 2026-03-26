import Testing
import Foundation
import SwiftUI
import SwiftData
import AuthenticationServices
import UIKit
@testable import SundeeFundee

private final class Wave5FakeAppleCredential: AppleIDCredentialProviding {
    let user: String
    let fullName: PersonNameComponents?
    let email: String?
    let authorizationCode: Data?

    init(user: String, fullName: PersonNameComponents?, email: String?, authorizationCode: Data? = nil) {
        self.user = user
        self.fullName = fullName
        self.email = email
        self.authorizationCode = authorizationCode
    }
}

private final class Wave5FakeAuthorization: NSObject {
    @objc let credential: Any

    init(credential: Any) {
        self.credential = credential
    }

    var asAuthorization: ASAuthorization {
        unsafeBitCast(self, to: ASAuthorization.self)
    }
}

@MainActor
private final class Wave5FakeAuthorizationController: @MainActor AppleAuthorizationControlling {
    var delegate: ASAuthorizationControllerDelegate?
    var presentationContextProvider: ASAuthorizationControllerPresentationContextProviding?
    private(set) var performRequestsCalls = 0

    func performRequests() {
        performRequestsCalls += 1
    }
}

@Suite("AuthOnboarding Wave5", .serialized)
struct AuthOnboardingCoverageWave5Tests {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV9.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @MainActor
    private func makeContext() throws -> ModelContext {
        ModelContext(try makeContainer())
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
    func signInAndRootBodiesCoverRoutingStates() throws {
        let container = try makeContainer()
        let signInState = AppState()
        render(SignInView().environment(signInState).modelContainer(container))
        render(SignInView(initialErrorMessage: "Sign in failed").environment(signInState).modelContainer(container))
        render(SignInView(initialIsBusy: true).environment(signInState).modelContainer(container))

        let loadingState = AppState()
        loadingState.apply(.loading)
        _ = AppRootView(initialAppState: loadingState, shouldRestoreSession: false).body

        let signedOutState = AppState()
        signedOutState.apply(.signedOut)
        _ = AppRootView(initialAppState: signedOutState, shouldRestoreSession: false).body

        let onboardingState = AppState()
        onboardingState.apply(.needsOnboarding(userID: "wave5-onboarding-user", appleUserID: "wave5-apple"))
        _ = AppRootView(initialAppState: onboardingState, shouldRestoreSession: false).body

        let authenticatedState = AppState()
        authenticatedState.apply(.authenticated(userID: "wave5-auth-user"))
        _ = AppRootView(initialAppState: authenticatedState, shouldRestoreSession: false).body

        let guestState = AppState()
        guestState.apply(.guest)
        _ = AppRootView(initialAppState: guestState, shouldRestoreSession: false).body

        _ = LoadingView().body
    }

    @Test
    @MainActor
    func onboardingBodiesCoverStepVariants() throws {
        _ = try makeContainer()

        _ = OnboardingFlowView(userID: "wave5-user", initialStep: .experience).body
        _ = OnboardingFlowView(userID: "wave5-user", initialStep: .goal).body
        _ = OnboardingFlowView(userID: "wave5-user", initialStep: .gender).body
        _ = OnboardingFlowView(
            userID: "wave5-user",
            initialStep: .cycle,
            initialGender: .female,
            initialCycleTrackingEnabled: false
        )
        .body
        _ = OnboardingFlowView(
            userID: "wave5-user",
            initialStep: .cycle,
            initialGender: .female,
            initialCycleTrackingEnabled: true
        )
        .body

        _ = OnboardingStepView(title: "Title", subtitle: "Subtitle") { Text("Body") }.body
        _ = SelectionRow(title: "Option", subtitle: "Details", isSelected: true) {}.body
        _ = SelectionRow(title: "Option", subtitle: nil, isSelected: false) {}.body
    }

    @Test
    @MainActor
    func authServiceSignInWithApplePerformerSuccessAndFailureBranches() async throws {
        final class DepState: @unchecked Sendable {
            var savedUserIDs: [String] = []
            var performerInvocations = 0
        }

        let depState = DepState()
        let context = try makeContext()
        context.insert(
            User(
                id: "wave5-existing-user",
                name: "Existing",
                experienceLevel: .advanced,
                primaryGoal: .strength,
                gender: .female,
                appleUserID: "wave5-existing-apple",
                onboardingComplete: true
            )
        )
        try context.save()

        let successService = AuthService(
            dependencies: .init(
                saveAppleUserID: { depState.savedUserIDs.append($0) },
                loadAppleUserID: { nil },
                deleteAppleUserID: {},
                credentialStateForUserID: { _ in .notFound },
                makeUUID: { "wave5-generated" },
                performAppleSignInRequest: { _, _, completion in
                    depState.performerInvocations += 1
                    completion(.success(.init(
                        userID: "wave5-existing-apple",
                        fullName: nil,
                        email: "wave5@example.com"
                    )))
                    return NSObject()
                }
            )
        )

        if case .authenticated(let userID) = try await successService.signInWithApple(
            presentationAnchor: UIWindow(),
            modelContext: context
        ) {
            #expect(userID == "wave5-existing-user")
        } else {
            Issue.record("Expected signInWithApple success branch to authenticate existing user")
        }
        #expect(depState.performerInvocations == 1)
        #expect(depState.savedUserIDs == ["wave5-existing-apple"])

        enum Wave5SignInError: Error { case failed }
        let failureService = AuthService(
            dependencies: .init(
                saveAppleUserID: { _ in },
                loadAppleUserID: { nil },
                deleteAppleUserID: {},
                credentialStateForUserID: { _ in .notFound },
                makeUUID: { "wave5-generated" },
                performAppleSignInRequest: { _, _, completion in
                    completion(.failure(Wave5SignInError.failed))
                    return NSObject()
                }
            )
        )

        do {
            _ = try await failureService.signInWithApple(
                presentationAnchor: UIWindow(),
                modelContext: context
            )
            Issue.record("Expected signInWithApple to surface performer failure")
        } catch {
            #expect(error is Wave5SignInError)
        }
    }

    @Test
    @MainActor
    func authServiceCredentialResolverAndDelegateBranches() async throws {
        final class DepState: @unchecked Sendable {
            var savedUserIDs: [String] = []
        }

        let depState = DepState()
        let context = try makeContext()
        let dependenciesWithDefaultPerformer = AuthService.Dependencies(
            saveAppleUserID: { _ in },
            loadAppleUserID: { nil },
            deleteAppleUserID: {},
            credentialStateForUserID: { _ in .notFound },
            makeUUID: { "wave5-default-performer" }
        )
        _ = dependenciesWithDefaultPerformer.performAppleSignInRequest
        var fullName = PersonNameComponents()
        fullName.givenName = "Wave"
        fullName.familyName = "Five"
        let fakeCredential = Wave5FakeAppleCredential(
            user: "wave5-fake-apple",
            fullName: fullName,
            email: "wave5@coverage.test"
        )

        let service = AuthService(
            dependencies: .init(
                saveAppleUserID: { depState.savedUserIDs.append($0) },
                loadAppleUserID: { nil },
                deleteAppleUserID: {},
                credentialStateForUserID: { _ in .notFound },
                makeUUID: { "wave5-fake-user" }
            )
        )

        if case .needsOnboarding(let userID, let appleUserID) = await service.resolveAfterCredential(
            credential: fakeCredential,
            modelContext: context
        ) {
            #expect(userID == "wave5-fake-user")
            #expect(appleUserID == "wave5-fake-apple")
        } else {
            Issue.record("Expected protocol-backed credential resolver to route to onboarding")
        }
        #expect(depState.savedUserIDs == ["wave5-fake-apple"])

        var delegateResults: [Result<AuthService.AppleSignInCredential, Error>] = []
        let anchor = UIWindow()
        let delegate = AppleSignInDelegate(presentationAnchor: anchor) { delegateResults.append($0) }
        let controller = ASAuthorizationController(
            authorizationRequests: [ASAuthorizationAppleIDProvider().createRequest()]
        )
        #expect(delegate.presentationAnchor(for: controller) === anchor)

        delegate.authorizationController(
            controller: controller,
            didCompleteWithAuthorization: Wave5FakeAuthorization(credential: fakeCredential).asAuthorization
        )
        if case .success(let credential) = delegateResults[0] {
            #expect(credential.userID == "wave5-fake-apple")
            #expect(credential.fullName?.givenName == "Wave")
            #expect(credential.email == "wave5@coverage.test")
        } else {
            Issue.record("Expected delegate success branch to emit mapped credential")
        }

        delegate.authorizationController(
            controller: controller,
            didCompleteWithAuthorization: Wave5FakeAuthorization(credential: NSObject()).asAuthorization
        )
        if case .failure(let error) = delegateResults[1] {
            #expect((error as? AuthError)?.errorDescription == AuthError.invalidCredential.errorDescription)
        } else {
            Issue.record("Expected delegate invalid credential branch")
        }

        enum Wave5DelegateError: Error { case failed }
        delegate.authorizationController(controller: controller, didCompleteWithError: Wave5DelegateError.failed)
        if case .failure(let error) = delegateResults[2] {
            #expect(error is Wave5DelegateError)
        } else {
            Issue.record("Expected delegate explicit error branch")
        }
    }

    @Test
    @MainActor
    func authServiceDefaultPerformerUsesInjectedControllerFactory() {
        let fakeController = Wave5FakeAuthorizationController()
        let originalFactory = AuthService.Dependencies.makeAuthorizationController
        AuthService.Dependencies.makeAuthorizationController = { _ in fakeController }
        defer { AuthService.Dependencies.makeAuthorizationController = originalFactory }

        let dependencies = AuthService.Dependencies(
            saveAppleUserID: { _ in },
            loadAppleUserID: { nil },
            deleteAppleUserID: {},
            credentialStateForUserID: { _ in .notFound },
            makeUUID: { "wave5-default-performer" }
        )

        let retained = dependencies.performAppleSignInRequest(
            ASAuthorizationAppleIDProvider().createRequest(),
            UIWindow()
        ) { _ in }

        #expect(fakeController.performRequestsCalls == 1)
        #expect(fakeController.delegate is AppleSignInDelegate)
        #expect(fakeController.presentationContextProvider is AppleSignInDelegate)
        #expect(retained is AppleSignInDelegate)
    }

    @Test
    @MainActor
    func authServiceLiveDefaultsAndFactoryClosuresAreInvocable() async {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let controller = AuthService.Dependencies.makeAuthorizationController([request])
        #expect(controller is ASAuthorizationController)

        let state = await AuthService.Dependencies.live.credentialStateForUserID("wave5-live-\(UUID().uuidString)")
        switch state {
        case .authorized, .revoked, .notFound, .transferred:
            break
        @unknown default:
            break
        }
    }

    @Test
    @MainActor
    func signInResolveAndApplySeamUpdatesAuthState() async throws {
        KeychainHelper.deleteAppleUserID()
        defer { KeychainHelper.deleteAppleUserID() }

        let appState = AppState()
        let context = try makeContext()
        await SignInView.resolveAndApply(
            .init(userID: "wave5-resolve-apple", fullName: nil, email: nil),
            appState: appState,
            modelContext: context
        )

        if case .needsOnboarding(let userID, let appleUserID) = appState.authState {
            #expect(!userID.isEmpty)
            #expect(appleUserID == "wave5-resolve-apple")
        } else {
            Issue.record("Expected resolveAndApply seam to route new users to onboarding")
        }

        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserID == "wave5-resolve-apple" }
        )
        #expect(try context.fetch(descriptor).count == 1)
    }

    @Test
    @MainActor
    func signInAndOnboardingActionSeams() async throws {
        var fullName = PersonNameComponents()
        fullName.givenName = "Taylor"
        let fakeCredential = Wave5FakeAppleCredential(
            user: "wave5-signin-apple",
            fullName: fullName,
            email: "wave5-signin@test"
        )

        let request = ASAuthorizationAppleIDProvider().createRequest()
        SignInView.configureAppleRequest(request)
        #expect(request.requestedScopes == [.fullName, .email])
        switch SignInView.payload(from: fakeCredential) {
        case .appleID(let userID, let resolvedName, let email):
            #expect(userID == "wave5-signin-apple")
            #expect(resolvedName?.givenName == "Taylor")
            #expect(email == "wave5-signin@test")
        case .unsupportedCredential:
            Issue.record("Expected protocol-backed payload conversion")
        }

        switch SignInView.payload(from: .success(Wave5FakeAuthorization(credential: fakeCredential).asAuthorization)) {
        case .success(.appleID(let userID, _, _)):
            #expect(userID == "wave5-signin-apple")
        default:
            Issue.record("Expected successful authorization payload conversion")
        }

        let signInContext = try makeContext()
        let signInState = AppState()
        var view = SignInView()
        _ = view.handleAppleResult(
            .failure(NSError(domain: "wave5", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Cancelled"])),
            appState: signInState,
            modelContext: signInContext
        )

        final class ResolveState: @unchecked Sendable {
            var contexts: [SignInView.AppleSignInResolutionContext] = []
        }
        let resolveState = ResolveState()
        let resolveTask = view.apply(decision: .resolveCredential(
            userID: "wave5-signin-apple",
            fullName: fullName,
            email: "wave5-signin@test"
        )) { context in
            resolveState.contexts.append(context)
        }
        #expect(resolveTask != nil)
        await resolveTask?.value
        #expect(resolveState.contexts.map(\.userID) == ["wave5-signin-apple"])
        #expect(resolveState.contexts.first?.fullName?.givenName == "Taylor")

        let ignoredTask = view.apply(decision: .ignore) { _ in
            Issue.record("Resolver should not be called for ignore decision")
        }
        #expect(ignoredTask == nil)

        let showErrorTask = view.apply(decision: .showError("Auth failed")) { _ in
            Issue.record("Resolver should not be called for showError decision")
        }
        #expect(showErrorTask == nil)

        let middleFlow = OnboardingFlowView(userID: "wave5-flow", initialStep: .experience, initialGender: .female)
        var savedAtMiddle = false
        #expect(middleFlow.nextStep(saveAndFinish: { savedAtMiddle = true }) == true)
        #expect(savedAtMiddle == false)

        let finalFlow = OnboardingFlowView(userID: "wave5-flow", initialStep: .gender, initialGender: .male)
        var savedAtFinalStep = false
        #expect(finalFlow.nextStep(saveAndFinish: { savedAtFinalStep = true }) == false)
        #expect(savedAtFinalStep == true)

        let firstStepFlow = OnboardingFlowView(userID: "wave5-flow", initialStep: .experience)
        #expect(firstStepFlow.previousStep() == false)
        #expect(firstStepFlow.previousStepAnimated() == false)

        let laterStepFlow = OnboardingFlowView(userID: "wave5-flow", initialStep: .goal)
        #expect(laterStepFlow.previousStep() == true)

        let saveFlow = OnboardingFlowView(
            userID: "wave5-flow",
            initialStep: .cycle,
            initialExperienceLevel: .advanced,
            initialPrimaryGoal: .endurance,
            initialGender: .female,
            initialCycleTrackingEnabled: true
        )
        let persisted = saveFlow.saveAndFinish { userID, experienceLevel, primaryGoal, gender, cycleTrackingEnabled in
            #expect(userID == "wave5-flow")
            #expect(experienceLevel == .advanced)
            #expect(primaryGoal == .endurance)
            #expect(gender == .female)
            #expect(cycleTrackingEnabled == true)
            return true
        }
        #expect(persisted == true)
        #expect(saveFlow.isSavingState == false)
        #expect(saveFlow.currentStep == .cycle)

        let context = try makeContext()
        let persistedUser = User(
            id: "wave5-flow",
            name: "",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .preferNotToSay,
            appleUserID: "wave5-save-apple",
            onboardingComplete: false
        )
        context.insert(persistedUser)
        try context.save()
        let persistedState = AppState()
        #expect(saveFlow.saveAndFinish(appState: persistedState, modelContext: context) == true)
        #expect(persistedUser.onboardingComplete == true)
        if case .authenticated(let userID) = persistedState.authState {
            #expect(userID == "wave5-flow")
        } else {
            Issue.record("Expected explicit saveAndFinish overload to authenticate")
        }
    }


    @Test
    @MainActor
    func appRootRestoreSessionIfNeededBranches() async throws {
        let context = try makeContext()
        KeychainHelper.deleteAppleUserID()
        let appState = AppState()

        await AppRootView.restoreSessionIfNeeded(
            shouldRestoreSession: false,
            appState: appState,
            modelContext: context
        )
        if case .loading = appState.authState {
            // expected
        } else {
            Issue.record("Expected shouldRestoreSession false to skip restore")
        }

        await AppRootView.restoreSessionIfNeeded(
            shouldRestoreSession: true,
            appState: appState,
            modelContext: context
        )
        if case .signedOut = appState.authState {
            // expected
        } else {
            Issue.record("Expected shouldRestoreSession true to restore and sign out")
        }
    }
}
