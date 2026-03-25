import Testing
import SwiftUI
import SwiftData
import AuthenticationServices
import UIKit
@testable import SundeeFundee

@Model
private final class AuthOnboardingCoverageTempModel {
    var value: String

    init(value: String = "temp") {
        self.value = value
    }
}

@Suite("Auth + Onboarding View Coverage", .serialized)
struct AuthOnboardingViewCoverageTests {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([AuthOnboardingCoverageTempModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @MainActor
    private func makeAppContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV9.models)
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

    @Test @MainActor
    func signInViewRendersWithInjectedEnvironment() throws {
        let appState = AppState()
        let container = try makeContainer()
        render(SignInView().environment(appState).modelContainer(container))

        if case .loading = appState.authState {
            // expected
        } else {
            Issue.record("Rendering SignInView should not mutate auth state")
        }
    }

    @Test @MainActor
    func signInHelperBranches() {
        #expect(SignInView.requestedScopes() == [.fullName, .email])
        let request = ASAuthorizationAppleIDProvider().createRequest()
        SignInView.requestConfigurator(request)
        #expect(request.requestedScopes == [.fullName, .email])
        #expect(SignInView.controlsDisabled(isBusy: true))
        #expect(!SignInView.controlsDisabled(isBusy: false))
        #expect(SignInView.shouldShowError(message: "Oops"))
        #expect(!SignInView.shouldShowError(message: nil))
        #expect(SignInView.showsBusyOverlay(isBusy: true))
        #expect(!SignInView.showsBusyOverlay(isBusy: false))

        let cancelled = NSError(domain: "test", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Cancelled"])
        #expect(SignInView.errorMessage(for: cancelled) == nil)

        let failed = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Failed"])
        #expect(SignInView.errorMessage(for: failed) == "Failed")

        let appState = AppState()
        appState.signInAsGuest()
        if case .guest = appState.authState {
            // expected
        } else {
            Issue.record("Expected guest auth state after signInAsGuestAction")
        }
    }

    @Test @MainActor
    func signInResolveActionClosureExecutes() async throws {
        let container = try makeAppContainer()
        let context = ModelContext(container)
        let appState = AppState()
        var view = SignInView(initialIsBusy: true)
        let completion = view.handleAppleResultAction(appState: appState, modelContext: context)
        completion(.failure(NSError(domain: "auth-onboarding", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Cancelled"])))
        let task = view.apply(
            decision: .resolveCredential(userID: "resolve-user", fullName: nil, email: nil),
            appState: appState,
            modelContext: context
        )
        #expect(task != nil)
        await task?.value
        if case .loading = appState.authState {
            Issue.record("Expected auth state to move past loading after resolveAction")
        }
    }

    @Test @MainActor
    func onboardingActionHelpersMutateStateAndSelection() {
        var selected = false
        let selection = OnboardingFlowView.selectionAction(
            binding: Binding(
                get: { selected },
                set: { selected = $0 }
            ),
            value: true
        )
        selection()
        #expect(selected == true)

        let previousFlow = OnboardingFlowView(userID: "u-1", initialStep: .goal)
        previousFlow.previousStepAnimatedAction()

        let nextFlow = OnboardingFlowView(userID: "u-2", initialStep: .experience)
        nextFlow.nextStepAnimatedAction()
    }

    @Test @MainActor
    func onboardingFlowRendersDefaultStep() throws {
        let appState = AppState()
        let container = try makeContainer()
        render(OnboardingFlowView(userID: "user-coverage").environment(appState).modelContainer(container))
    }

    @Test @MainActor
    func onboardingFinalStepPersistencePath() throws {
        let container = try makeAppContainer()
        let context = ModelContext(container)
        let user = User(
            id: "user-persist",
            name: "Jordan",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .female,
            appleUserID: "apple-user-persist",
            cycleTrackingEnabled: true,
            onboardingComplete: false
        )
        context.insert(user)
        try context.save()

        let appState = AppState()
        let flow = OnboardingFlowView(
            userID: user.id,
            initialStep: .cycle,
            initialExperienceLevel: user.experienceLevel,
            initialPrimaryGoal: user.primaryGoal,
            initialGender: user.gender,
            initialCycleTrackingEnabled: user.cycleTrackingEnabled
        )
        #expect(!flow.nextStepWithPersistence(appState: appState, modelContext: context))

        let refreshed = try context.fetch(FetchDescriptor<User>()).first(where: { $0.id == user.id })
        #expect(refreshed?.onboardingComplete == true)
        if case .authenticated(let authenticatedUserID) = appState.authState {
            #expect(authenticatedUserID == user.id)
        } else {
            Issue.record("Expected authenticated auth state after final onboarding step")
        }
    }

    @Test @MainActor
    func onboardingAndAuthRoutingBranches() {
        #expect(OnboardingFlowView.visibleSteps(for: .male) == [.experience, .goal, .gender])
        #expect(OnboardingFlowView.visibleSteps(for: .female) == [.experience, .goal, .gender, .cycle])
        #expect(OnboardingFlowView.visibleSteps(for: .preferNotToSay) == [.experience, .goal, .gender, .cycle])
        #expect(OnboardingFlowView.showsBackButton(for: .experience) == false)
        #expect(OnboardingFlowView.showsBackButton(for: .goal))
        #expect(OnboardingFlowView.actionTitle(for: .experience, gender: .female) == "Next")
        #expect(OnboardingFlowView.actionTitle(for: .cycle, gender: .female) == "Get Started")
        #expect(OnboardingFlowView.isLastStep(.gender, gender: .male))
        #expect(OnboardingFlowView.isLastStep(.cycle, gender: .female))
        #expect(OnboardingFlowView.nextVisibleStep(from: .gender, gender: .male) == nil)
        #expect(OnboardingFlowView.nextVisibleStep(from: .gender, gender: .female) == .cycle)
        #expect(OnboardingFlowView.previousVisibleStep(from: .experience, gender: .female) == nil)
        #expect(OnboardingFlowView.previousVisibleStep(from: .goal, gender: .female) == .experience)
        #expect(!OnboardingFlowView.resolvedCycleTrackingEnabled(gender: .male, requestedValue: true))
        #expect(OnboardingFlowView.resolvedCycleTrackingEnabled(gender: .female, requestedValue: true))
        #expect(!OnboardingFlowView.resolvedCycleTrackingEnabled(gender: .preferNotToSay, requestedValue: false))

        #expect(AppRootView.destination(for: .loading) == .loading)
        #expect(AppRootView.destination(for: .signedOut) == .signedOut)
        #expect(
            AppRootView.destination(for: .needsOnboarding(userID: "user-1", appleUserID: "apple-1")) ==
            .onboarding(userID: "user-1")
        )
        #expect(AppRootView.destination(for: .authenticated(userID: "user-2")) == .mainTabs)
        #expect(AppRootView.destination(for: .guest) == .mainTabs)
    }

    @Test @MainActor
    func onboardingSubcomponentsRenderAcrossStates() {
        render(OnboardingStepView(title: "Title", subtitle: "Subtitle") { Text("Step body") })
        render(SelectionRow(title: "Option", subtitle: "Detail", isSelected: true) {})
        render(SelectionRow(title: "Option", subtitle: nil, isSelected: false) {})
        render(LoadingView())
    }

    @Test
    func onboardingDisplayMetadataBranches() {
        #expect(ExperienceLevel.beginner.displayName == "Beginner")
        #expect(ExperienceLevel.intermediate.subtitle == "2–5 years of consistent training")
        #expect(ExperienceLevel.advanced.subtitle == "5+ years of consistent training")
        #expect(PrimaryGoal.strength.displayName == "Strength")
        #expect(PrimaryGoal.hypertrophy.displayName == "Muscle building")
        #expect(PrimaryGoal.endurance.subtitle == "Improve stamina and conditioning")
        #expect(PrimaryGoal.weightLoss.subtitle == "Reduce body fat while maintaining muscle")
        #expect(Gender.male.displayName == "Male")
        #expect(Gender.female.displayName == "Female")
        #expect(Gender.preferNotToSay.displayName == "Prefer not to say")
    }
}
