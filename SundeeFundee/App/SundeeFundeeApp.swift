import SwiftUI
import SwiftData

@main
struct SundeeFundeeApp: App {
    let container: ModelContainer

    init() {
        container = AppModelContainer.shared
        MetricsService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(container)
        }
    }
}
