import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Bindable var viewModel: AuthenticationViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        BrandBackgroundView {
            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 16) {
                    BrandCircularLogo("AppLogo", size: 160)

                    Text("Sundee Fundee")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Strength training, powered by your cycle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    viewModel.handleSignIn(result: result, context: modelContext)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .padding(.horizontal, 40)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Brand.danger)
                }

                Spacer()
                    .frame(height: 40)
            }
        }
    }
}
