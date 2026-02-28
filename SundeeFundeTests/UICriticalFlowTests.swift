import Foundation
import XCTest
import SwiftData
@testable import SundeeFundee

final class UICriticalFlowTests: XCTestCase {

    @MainActor
    func testAppRootDestinationRoutesCoverAllAuthStates() {
        XCTAssertEqual(AppRootView.destination(for: .loading), .loading)
        XCTAssertEqual(AppRootView.destination(for: .signedOut), .signedOut)
        XCTAssertEqual(
            AppRootView.destination(for: .needsOnboarding(userID: "user-1", appleUserID: "apple-1")),
            .onboarding(userID: "user-1")
        )
        XCTAssertEqual(AppRootView.destination(for: .authenticated(userID: "user-2")), .mainTabs)
        XCTAssertEqual(AppRootView.destination(for: .guest), .mainTabs)
    }

    @MainActor
    func testAppStateSessionTransitionsUpdateRoutingContext() {
        let state = AppState()

        state.apply(.authenticated(userID: "auth-user"))
        XCTAssertEqual(state.currentUserID, "auth-user")

        state.apply(.needsOnboarding(userID: "onboarding-user", appleUserID: "apple-2"))
        XCTAssertEqual(state.currentUserID, "onboarding-user")

        state.signInAsGuest()
        XCTAssertNil(state.currentUserID)
        if case .guest = state.authState {} else { XCTFail("Expected guest auth state") }

        state.signOut()
        XCTAssertNil(state.currentUserID)
        if case .signedOut = state.authState {} else { XCTFail("Expected signedOut auth state") }
    }

    @MainActor
    func testOnboardingFlowHelpersEnforceCriticalProgressionRules() {
        XCTAssertEqual(OnboardingFlowView.visibleSteps(for: .male), [.name, .experience, .goal, .gender])
        XCTAssertEqual(OnboardingFlowView.visibleSteps(for: .female), [.name, .experience, .goal, .gender, .cycle])
        XCTAssertFalse(OnboardingFlowView.canAdvanceFromName("   "))
        XCTAssertTrue(OnboardingFlowView.canAdvanceFromName(" Alex "))
        XCTAssertFalse(OnboardingFlowView.resolvedCycleTrackingEnabled(gender: .male, requestedValue: true))
        XCTAssertTrue(OnboardingFlowView.resolvedCycleTrackingEnabled(gender: .female, requestedValue: true))
    }

    func testOnboardingEligibilityEvaluatorCoversCriticalBranches() {
        XCTAssertEqual(OnboardingEligibilityEvaluator.evaluate(user: nil), .needsOnboarding)
        XCTAssertEqual(OnboardingEligibilityEvaluator.evaluate(user: makeUser(name: "Alex", onboardingComplete: true)), .complete)
        XCTAssertEqual(OnboardingEligibilityEvaluator.evaluate(user: makeUser(name: "Alex", onboardingComplete: false)), .resumeOnboarding)
        XCTAssertEqual(OnboardingEligibilityEvaluator.evaluate(user: makeUser(name: "   ", onboardingComplete: false)), .needsOnboarding)
    }

    func testOnboardingDisplayMetadataRemainsStable() {
        XCTAssertEqual(ExperienceLevel.beginner.displayName, "Beginner")
        XCTAssertEqual(ExperienceLevel.intermediate.subtitle, "2–5 years of consistent training")
        XCTAssertEqual(PrimaryGoal.weightLoss.displayName, "Weight loss")
        XCTAssertEqual(PrimaryGoal.strength.subtitle, "Maximise 1RM in key lifts")
        XCTAssertEqual(Gender.preferNotToSay.displayName, "Prefer not to say")
    }

    @MainActor
    func testAppModelContainerRoutingBranchesUseExpectedRequests() throws {
        let expected = try makeInMemoryContainer()

        do {
            var requests: [AppModelContainer.ContainerRequest] = []
            let container = AppModelContainer.makeSharedContainer(
                isRunningTests: true,
                makeContainer: { request in
                    requests.append(request)
                    return expected
                },
                deleteStoreFiles: {
                    XCTFail("deleteStoreFiles should not run while handling test container path")
                },
                log: { _ in }
            )
            XCTAssertEqual(requests, [.testsInMemory])
            XCTAssertEqual(ObjectIdentifier(container), ObjectIdentifier(expected))
        }

        do {
            enum CloudError: Error { case failed }
            var requests: [AppModelContainer.ContainerRequest] = []
            var deleteCalls = 0

            let container = AppModelContainer.makeSharedContainer(
                isRunningTests: false,
                useCloudKit: true,
                makeContainer: { request in
                    requests.append(request)
                    if request == .cloudKit { throw CloudError.failed }
                    return expected
                },
                deleteStoreFiles: { deleteCalls += 1 },
                log: { _ in }
            )

            XCTAssertEqual(requests, [.cloudKit, .localPersistent])
            XCTAssertEqual(deleteCalls, 0)
            XCTAssertEqual(ObjectIdentifier(container), ObjectIdentifier(expected))
        }

        do {
            enum LocalError: Error { case failed }
            var requests: [AppModelContainer.ContainerRequest] = []
            var deleteCalls = 0
            var localAttempts = 0

            _ = AppModelContainer.makeSharedContainer(
                isRunningTests: false,
                useCloudKit: false,
                makeContainer: { request in
                    requests.append(request)
                    if request == .localPersistent {
                        localAttempts += 1
                        if localAttempts < 3 {
                            throw LocalError.failed
                        }
                    }
                    return expected
                },
                deleteStoreFiles: { deleteCalls += 1 },
                log: { _ in }
            )

            XCTAssertEqual(requests, [.localPersistent, .localPersistent, .fallbackInMemory])
            XCTAssertEqual(deleteCalls, 1)
        }
    }

    @MainActor
    func testAppModelContainerDeletesKnownStoreArtifactsBeforeRetry() throws {
        let fileManager = FileManager.default
        guard let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            XCTFail("Expected an application support directory")
            return
        }
        try fileManager.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)

        let artifacts = ["default.store", "default.store-wal", "default.store-shm"].map {
            appSupportDirectory.appendingPathComponent($0)
        }
        for url in artifacts {
            _ = fileManager.createFile(atPath: url.path, contents: Data("coverage".utf8))
        }

        let expected = try makeInMemoryContainer()
        var localAttempts = 0

        _ = AppModelContainer.makeSharedContainer(
            isRunningTests: false,
            useCloudKit: false,
            makeContainer: { request in
                if request == .localPersistent {
                    localAttempts += 1
                    if localAttempts == 1 {
                        throw NSError(domain: "UICriticalFlowTests", code: 1)
                    }
                }
                return expected
            },
            log: { _ in }
        )

        for artifact in artifacts {
            XCTAssertFalse(fileManager.fileExists(atPath: artifact.path))
        }
    }

    @MainActor
    func testAppModelContainerConcreteRequestsAreCallable() {
        XCTAssertNoThrow(try AppModelContainer.makeContainer(for: .testsInMemory))
        XCTAssertNoThrow(try AppModelContainer.makeContainer(for: .fallbackInMemory))
        // .localPersistent and .cloudKit are not tested here because CoreData's
        // CloudKit validation can crash the process in the simulator environment
        // (non-optional attributes without defaults trigger a fatal error).
    }

    private func makeUser(name: String, onboardingComplete: Bool) -> User {
        User(
            id: UUID().uuidString,
            name: name,
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .female,
            appleUserID: UUID().uuidString,
            onboardingComplete: onboardingComplete
        )
    }

    @MainActor
    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([] as [any PersistentModel.Type])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
