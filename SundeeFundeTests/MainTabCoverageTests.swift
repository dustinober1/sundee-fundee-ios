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
        let schema = Schema(AppSchemaV9.models)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    func testTabMetadataAndOrderAreStable() {
        let tabs = MainTabView.orderedTabs

        XCTAssertEqual(tabs, [.dashboard, .programs, .history, .maxes, .benchmarks, .cycle, .settings])
        XCTAssertEqual(tabs.map(\.title), ["Dashboard", "Programs", "History", "Maxes", "Benchmarks", "Cycle", "Settings"])
        XCTAssertEqual(
            tabs.map(\.systemImage),
            [
                "house.fill",
                "list.bullet.rectangle.portrait.fill",
                "clock.fill",
                "dumbbell.fill",
                "checkmark.seal.fill",
                "circle.dotted",
                "gearshape.fill",
            ]
        )
    }

    func testDestinationBuilderCoversEveryTabCase() {
        let destinations = MainTabView.orderedTabs.map { AnyView(MainTabView.destination(for: $0)) }
        XCTAssertEqual(destinations.count, MainTabView.orderedTabs.count)
    }

    func testMainTabHostsAndBuildsAllTabsWithStubDestinations() {
        var builtTabs: [MainTabView.TabRoute] = []
        let view = MainTabView { tab in
            builtTabs.append(tab)
            return AnyView(Text(tab.title))
        }

        _ = host(view)
        XCTAssertEqual(Set(builtTabs), Set(MainTabView.orderedTabs))
    }

    func testMainTabBodyBuildsWithoutCrashing() {
        _ = MainTabView().body
    }

    func testDefaultDestinationBuilderPathExecutesInHostedView() throws {
        let appState = AppState()
        appState.apply(.authenticated(userID: "tabs-user"))
        let container = try makeContainer()
        let root = MainTabView()
            .environment(appState)
            .modelContainer(container)
        XCTAssertNotNil(host(root).view)
    }

    func testOrderedTabsExcludesCycleForMale() {
        let tabs = MainTabView.orderedTabs(for: .male)
        XCTAssertFalse(tabs.contains(.cycle))
        XCTAssertEqual(tabs, [.dashboard, .programs, .history, .maxes, .benchmarks, .settings])
    }

    func testOrderedTabsIncludesCycleForFemale() {
        let tabs = MainTabView.orderedTabs(for: .female)
        XCTAssertTrue(tabs.contains(.cycle))
    }

    func testOrderedTabsIncludesCycleForPreferNotToSay() {
        let tabs = MainTabView.orderedTabs(for: .preferNotToSay)
        XCTAssertTrue(tabs.contains(.cycle))
    }

    func testOrderedTabsIncludesCycleForNilGender() {
        let tabs = MainTabView.orderedTabs(for: nil)
        XCTAssertTrue(tabs.contains(.cycle))
    }

}
