import SwiftUI

/// Routes between loading, sign-in, onboarding, and main app based on AppState.
struct AppRootView: View {
    @State private var appState = AppState()

    var body: some View {
        Group {
            switch appState.authState {
            case .loading:
                LoadingView()
            case .signedOut:
                SignInView()
            case .needsOnboarding(let userID, let appleUserID):
                Text("Onboarding — Phase 3") // placeholder until Phase 3
                    .task {
                        _ = userID; _ = appleUserID
                    }
            case .authenticated:
                Text("Main App — Phase 6+") // placeholder until shell is built
            case .guest:
                Text("Guest Mode — Phase 6+") // placeholder
            }
        }
        .environment(appState)
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
