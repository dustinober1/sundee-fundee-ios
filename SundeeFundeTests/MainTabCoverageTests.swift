import XCTest
import SwiftUI
import UIKit
import SwiftData
@testable import SundeeFundee

@MainActor
final class MainTabCoverageTests: XCTestCase {
    @discardableResult
    private func host<Content: View>(
        _ view: Content,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UIHostingController<Content> {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        XCTAssertNotNil(controller.view, file: file, line: line)
        return controller
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(AppSchemaV10.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    func testPrimaryTabMetadataIsStable() {
        let tabs = MainTabView.primaryTabs

        XCTAssertEqual(tabs, [.dashboard, .programs, .wods, .history, .more])
        XCTAssertEqual(tabs.map(\.title), ["Dashboard", "Programs", "WODs", "History", "More"])
        XCTAssertEqual(
            tabs.map(\.systemImage),
            [
                "house.fill",
                "list.bullet.rectangle.portrait.fill",
                "flame.fill",
                "clock.fill",
                "ellipsis.circle.fill",
            ]
        )
    }

    func testDestinationBuilderCoversEveryPrimaryTabCase() {
        let destinations = MainTabView.primaryTabs.map { AnyView(MainTabView.destination(for: $0)) }
        XCTAssertEqual(destinations.count, MainTabView.primaryTabs.count)
    }

    func testMainTabHostsAndBuildsAllTabsWithStubDestinations() {
        var builtTabs: [MainTabView.TabRoute] = []
        let view = MainTabView { tab in
            builtTabs.append(tab)
            return AnyView(Text(tab.title))
        }

        _ = host(view)
        // The .more tab renders MoreTabView directly and does not call destinationBuilder
        let expectedBuilderTabs: Set<MainTabView.TabRoute> = [.dashboard, .programs, .wods, .history]
        XCTAssertEqual(Set(builtTabs), expectedBuilderTabs)
    }

    func testMainTabAndPlaceholderBodiesBuildWithoutCrashing() {
        _ = MainTabView().body
        _ = WorkoutsPlaceholderView().body
        _ = CyclePlaceholderView().body
        _ = SettingsPlaceholderView().body
    }

    func testDefaultDestinationBuilderPathExecutesInHostedView() throws {
        let appState = AppState()
        appState.apply(.authenticated(userID: "tabs-user"))
        let container = try makeContainer()
        let root = MainTabView()
            .environment(appState)
            .environment(SubscriptionService())
            .modelContainer(container)
        XCTAssertNotNil(host(root).view)
    }

    func testMoreRoutesExcludesCycleForMale() {
        let routes = MainTabView.moreRoutes(for: .male)
        XCTAssertFalse(routes.contains(.cycle))
        XCTAssertEqual(routes, [.maxes, .benchmarks, .settings])
    }

    func testMoreRoutesIncludesCycleForFemale() {
        let routes = MainTabView.moreRoutes(for: .female)
        XCTAssertTrue(routes.contains(.cycle))
        XCTAssertEqual(routes, [.maxes, .benchmarks, .cycle, .settings])
    }

    func testMoreRoutesIncludesCycleForPreferNotToSay() {
        let routes = MainTabView.moreRoutes(for: .preferNotToSay)
        XCTAssertTrue(routes.contains(.cycle))
    }

    func testMoreRoutesIncludesCycleForNilGender() {
        let routes = MainTabView.moreRoutes(for: nil)
        XCTAssertTrue(routes.contains(.cycle))
    }

    func testMoreRouteMetadataIsCorrect() {
        let allRoutes: [MainTabView.MoreRoute] = [.maxes, .benchmarks, .cycle, .settings]
        XCTAssertEqual(allRoutes.map(\.title), ["Maxes", "Benchmarks", "Cycle", "Settings"])
        XCTAssertEqual(
            allRoutes.map(\.systemImage),
            ["dumbbell.fill", "checkmark.seal.fill", "circle.dotted", "gearshape.fill"]
        )
    }

    func testMoreDestinationCoversAllRoutes() {
        let allRoutes: [MainTabView.MoreRoute] = [.maxes, .benchmarks, .cycle, .settings]
        for route in allRoutes {
            _ = AnyView(MainTabView.moreDestination(for: route))
        }
    }

    func testPlaceholderViewsRenderInHostingController() {
        XCTAssertNotNil(host(WorkoutsPlaceholderView()).view)
        XCTAssertNotNil(host(CyclePlaceholderView()).view)
        XCTAssertNotNil(host(SettingsPlaceholderView()).view)
    }
}
