import SwiftUI

/// Placeholder — full implementation in Phase 2.
struct SignInView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            AppTheme.Color.cream.ignoresSafeArea()
            VStack(spacing: AppTheme.Spacing.xl) {
                Text("Sundee Fundee")
                    .font(AppTheme.Font.heading(32))
                    .foregroundStyle(AppTheme.Color.navy)

                Text("Strength Gained — On Your Cycle")
                    .font(AppTheme.Font.body(16))
                    .foregroundStyle(AppTheme.Color.textSecondary)

                // Sign in with Apple button added in Phase 2
                Button("Continue as Guest") {
                    appState.signInAsGuest()
                }
                .foregroundStyle(AppTheme.Color.navy)
                .padding(.top, AppTheme.Spacing.lg)
            }
            .padding(AppTheme.Spacing.xl)
        }
    }
}
