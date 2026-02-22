import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var authViewModel = AuthenticationViewModel()

    var body: some View {
        BrandBackgroundView {
            VStack(spacing: 24) {
                // Circular logo at the top
                LogoView()
                    .frame(width: 96, height: 96)
                    .accessibilityIdentifier("appLogo")

                Group {
                    switch authViewModel.authState {
                    case .loading:
                        ProgressView("Loading...")
                    case .unauthenticated:
                        SignInView(viewModel: authViewModel)
                    case .needsOnboarding:
                        OnboardingView(viewModel: authViewModel)
                    case .authenticated, .guest:
                        MainTabView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                authViewModel.checkAuthState(context: modelContext)
            }
        }
        .environment(authViewModel)
    }
}

private struct LogoView: View {
    var body: some View {
        // Replace "AppLogo" with your actual asset name if different
        Image("AppLogo")
            .resizable()
            .scaledToFill()
            .clipShape(Circle())
            .contentShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(.clear, lineWidth: 0)
            )
            .compositingGroup()
            .clipped()
            .shadow(radius: 0)
            .accessibilityLabel("App logo")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
}
