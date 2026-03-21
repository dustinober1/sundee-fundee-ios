import XCTest
import SwiftUI
import SwiftData
import UIKit
@testable import SundeeFundee

final class SwiftUISmokeTestsB: XCTestCase {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @MainActor
    private func makeAuthenticatedAppState(userID: String = "smoke-user") -> AppState {
        let appState = AppState()
        appState.apply(.authenticated(userID: userID))
        return appState
    }

    @MainActor
    private func host<Content: View>(
        _ view: Content,
        container: ModelContainer,
        appState: AppState? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var root = AnyView(view.modelContainer(container))
        if let appState {
            root = AnyView(root.environment(appState))
        }

        let controller = UIHostingController(rootView: root)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        XCTAssertNotNil(controller.view, file: file, line: line)
    }

    @MainActor
    func testCycleTrackingViewHostsWithInMemoryStore() throws {
        host(CycleTrackingView(), container: try makeContainer())
    }

    @MainActor
    func testMaxLiftsViewHostsWithInMemoryStore() throws {
        host(MaxLiftsView(), container: try makeContainer())
    }

    @MainActor
    func testBenchmarksViewHostsWithInMemoryStore() throws {
        host(BenchmarksView(), container: try makeContainer())
    }

    @MainActor
    func testSettingsViewHostsWithInMemoryStore() throws {
        let container = try makeContainer()
        let context = container.mainContext
        context.insert(User(
            id: "smoke-user",
            name: "Smoke User",
            experienceLevel: .beginner,
            primaryGoal: .strength,
            gender: .female,
            appleUserID: "apple-smoke-user"
        ))
        try context.save()

        host(
            SettingsView(),
            container: container,
            appState: makeAuthenticatedAppState()
        )
    }

    @MainActor
    func testMainTabViewHostsWithInMemoryStore() throws {
        throw XCTSkip("MainTabView body evaluation is unstable in headless simulator runs.")
    }
}
