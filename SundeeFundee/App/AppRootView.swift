import SwiftUI
import SwiftData

/// Routes between loading, sign-in, onboarding, and main app based on AppState.
struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState = AppState()

    var body: some View {
        Group {
            switch appState.authState {
            case .loading:
                LoadingView()
            case .signedOut:
                SignInView()
            case .needsOnboarding(let userID, _):
                OnboardingFlowView(userID: userID)
            case .authenticated:
                Text("Main App — Phase 6+") // placeholder until shell is built
            case .guest:
                Text("Guest Mode — Phase 6+") // placeholder
            }
        }
        .environment(appState)
        .task {
            // Restore session on cold launch.
            let state = await appState.authService.restoreSession(modelContext: modelContext)
            appState.apply(state)
        }
    }
}

// MARK: - Loading placeholder

struct LoadingView: View {
    var body: some View {
        ZStack {
            AppTheme.Color.cream.ignoresSafeArea()
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("Sundee Fundee")
                    .font(AppTheme.Font.heading(28))
                    .foregroundStyle(AppTheme.Color.navy)
                ProgressView()
                    .tint(AppTheme.Color.orange)
            }
        }
    }
}
