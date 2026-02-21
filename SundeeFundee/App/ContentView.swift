import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var authViewModel = AuthenticationViewModel()

    var body: some View {
        BrandBackgroundView {
            Group {
                switch authViewModel.authState {
                case .loading:
                    ProgressView("Loading...")
                case .unauthenticated:
                    SignInView(viewModel: authViewModel)
                case .needsOnboarding:
                    OnboardingView(viewModel: authViewModel)
                case .authenticated:
                    MainTabView()
                }
            }
            .onAppear {
                authViewModel.checkAuthState(context: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
}
