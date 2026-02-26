import SwiftUI
import SwiftData
import Foundation

@main
struct SundeeFundeeApp: App {
    // Optional container: set to nil during tests to avoid initializing SwiftData/CloudKit.
    let container: ModelContainer?

    init() {
        let runningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || NSClassFromString("XCTestCase") != nil
        if runningTests {
            // Avoid creating any ModelContainer during unit tests to bypass CloudKit validation.
            container = nil
        } else {
            container = AppModelContainer.shared
        }

        MetricsService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            if let container = container {
                AppRootView()
                    .modelContainer(container)
            } else {
                // Tests or preview without a ModelContainer
                AppRootView()
            }
        }
    }
}
