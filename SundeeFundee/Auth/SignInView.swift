import SwiftUI
import AuthenticationServices
import SwiftData

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var errorMessage: String?
    @State private var isBusy = false

    var body: some View {
        ZStack {
            AppTheme.Color.cream.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()

                // Wordmark
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Sundee Fundee")
                        .font(AppTheme.Font.heading(36))
                        .foregroundStyle(AppTheme.Color.navy)

                    Text("Strength Gained — On Your Cycle")
                        .font(AppTheme.Font.body(16))
                        .foregroundStyle(AppTheme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: AppTheme.Spacing.md) {
                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleResult(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(AppTheme.Radius.sm)
                    .disabled(isBusy)

                    // Guest mode
                    Button {
                        appState.signInAsGuest()
                    } label: {
                        Text("Continue without signing in")
                            .font(AppTheme.Font.body(15))
                            .foregroundStyle(AppTheme.Color.textSecondary)
                    }
                    .disabled(isBusy)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(AppTheme.Font.body(13))
                        .foregroundStyle(AppTheme.Color.error)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: AppTheme.Spacing.xxl)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            if isBusy {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView().tint(AppTheme.Color.orange)
            }
        }
    }

    // MARK: - Private

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
            else { return }
            isBusy = true
            errorMessage = nil
            Task { @MainActor in
                defer { isBusy = false }
                let state = await appState.authService.resolveAfterCredential(
                    credential: credential,
                    modelContext: modelContext
                )
                appState.apply(state)
            }
        case .failure(let error):
            let nsErr = error as NSError
            // Code 1001 = user cancelled — don't show an error.
            if nsErr.code != 1001 {
                errorMessage = error.localizedDescription
            }
        }
    }
}
