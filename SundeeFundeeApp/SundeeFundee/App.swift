import SwiftUI
import SundeeFundeeKit

@main
struct SundeeFundeeMain: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeViewModel = ThemeViewModel()

    private static let isScreenshotMode = CommandLine.arguments.contains("--seed-screenshots")

    init() {
        // Set the free subscription client (all features unlocked)
        SubscriptionClientFactory.shared.client = FreeSubscriptionClient()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    if authViewModel.needsOnboarding {
                        OnboardingView {
                            authViewModel.completeOnboarding()
                        }
                    } else {
                        MainTabView()
                            .environmentObject(authViewModel)
                            .environmentObject(themeViewModel)
                    }
                } else {
                    AuthView()
                        .environmentObject(authViewModel)
                }
            }
            .artDecoBackground()
            .onAppear {
                themeViewModel.applyTheme()
            }
            .task {
                if Self.isScreenshotMode {
                    await ScreenshotSeeder.seed()
                    // Restore auth state after seeding
                    authViewModel.isGuest = true
                    authViewModel.userID = AuthViewModel.guestUserID
                    authViewModel.userName = "Sarah"
                    authViewModel.isAuthenticated = true
                    authViewModel.needsOnboarding = false
                }
            }
        }
    }
}
