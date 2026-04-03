import SwiftUI
import SundeeFundeeKit

@main
struct SundeeFundeeMain: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var themeViewModel = ThemeViewModel()

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
        }
    }
}
