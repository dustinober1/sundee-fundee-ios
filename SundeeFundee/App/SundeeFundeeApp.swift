import SwiftUI
import SwiftData
import Foundation

@main
struct SundeeFundeeApp: App {
    // Optional container: set to nil during tests to avoid initializing SwiftData/CloudKit.
    let container: ModelContainer?

    init() {
        self.init(
            isRunningTests: Self.isRunningTests,
            startMetrics: { MetricsService.shared.start() }
        )
    }

    init(
        isRunningTests: Bool = Self.isRunningTests,
        sharedContainer: () -> ModelContainer = { AppModelContainer.shared },
        startMetrics: () -> Void = { MetricsService.shared.start() }
    ) {
        if isRunningTests {
            // Avoid creating any ModelContainer during unit tests to bypass CloudKit validation.
            container = nil
        } else {
            container = sharedContainer()
        }

        startMetrics()
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || NSClassFromString("XCTestCase") != nil
    }

    @ViewBuilder
    static func rootView(container: ModelContainer?) -> some View {
        if let container {
            AppRootView()
                .modelContainer(container)
        } else {
            // Tests: render nothing to avoid modelContext access without a container
            Color.clear
        }
    }

    var body: some Scene {
        WindowGroup {
            Self.rootView(container: container)
        }
    }
}
