import SwiftUI
import AuthenticationServices
import SwiftData

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var errorMessage: String?
    @State private var isBusy = false

    enum AppleAuthorizationPayload {
        case appleID(userID: String, fullName: PersonNameComponents?, email: String?)
        case unsupportedCredential
    }

    enum AppleSignInDecision {
        case resolveCredential(userID: String, fullName: PersonNameComponents?, email: String?)
        case ignore
        case showError(String?)
    }

    struct AppleSignInResolutionContext {
        let userID: String
        let fullName: PersonNameComponents?
        let email: String?
    }

    struct AppleSignInStateChange {
        let isBusy: Bool
        let errorMessage: String?
        let resolutionContext: AppleSignInResolutionContext?
    }

    init(initialErrorMessage: String? = nil, initialIsBusy: Bool = false) {
        _errorMessage = State(initialValue: initialErrorMessage)
        _isBusy = State(initialValue: initialIsBusy)
    }

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
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: Self.requestConfigurator,
                        onCompletion: handleAppleResultAction(appState: appState, modelContext: modelContext)
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(AppTheme.Radius.sm)
                    .disabled(Self.controlsDisabled(isBusy: isBusy))

                    // Guest mode
                    Button("Continue without signing in", action: appState.signInAsGuest)
                        .font(AppTheme.Font.body(15))
                        .foregroundStyle(AppTheme.Color.textSecondary)
                    .disabled(Self.controlsDisabled(isBusy: isBusy))
                }

                if Self.shouldShowError(message: errorMessage), let error = errorMessage {
                    Text(error)
                        .font(AppTheme.Font.body(13))
                        .foregroundStyle(AppTheme.Color.error)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: AppTheme.Spacing.xxl)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            if Self.showsBusyOverlay(isBusy: isBusy) {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView().tint(AppTheme.Color.orange)
            }
        }
    }

    // MARK: - Private

    static func requestedScopes() -> [ASAuthorization.Scope] {
        [.fullName, .email]
    }

    @MainActor
    static var requestConfigurator: (ASAuthorizationAppleIDRequest) -> Void { configureAppleRequest }

    static func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = requestedScopes()
    }

    static func controlsDisabled(isBusy: Bool) -> Bool {
        isBusy
    }

    static func shouldShowError(message: String?) -> Bool {
        message != nil
    }

    static func showsBusyOverlay(isBusy: Bool) -> Bool {
        isBusy
    }

    static func errorMessage(for error: Error) -> String? {
        let nsErr = error as NSError
        return nsErr.code == 1001 ? nil : error.localizedDescription
    }

    static func payload(from credential: Any) -> AppleAuthorizationPayload {
        guard let credential = credential as? any AppleIDCredentialProviding else {
            return .unsupportedCredential
        }
        return .appleID(userID: credential.user, fullName: credential.fullName, email: credential.email)
    }

    static func payload(from result: Result<ASAuthorization, Error>) -> Result<AppleAuthorizationPayload, Error> {
        switch result {
        case .success(let authorization):
            return .success(payload(from: authorization.credential))
        case .failure(let error):
            return .failure(error)
        }
    }

    static func decision(for result: Result<AppleAuthorizationPayload, Error>) -> AppleSignInDecision {
        switch result {
        case .success(.appleID(let userID, let fullName, let email)):
            return .resolveCredential(userID: userID, fullName: fullName, email: email)
        case .success(.unsupportedCredential):
            return .ignore
        case .failure(let error):
            return .showError(errorMessage(for: error))
        }
    }

    static func stateChange(for decision: AppleSignInDecision) -> AppleSignInStateChange {
        switch decision {
        case .resolveCredential(let userID, let fullName, let email):
            return AppleSignInStateChange(
                isBusy: true,
                errorMessage: nil,
                resolutionContext: AppleSignInResolutionContext(userID: userID, fullName: fullName, email: email)
            )
        case .ignore:
            return AppleSignInStateChange(isBusy: false, errorMessage: nil, resolutionContext: nil)
        case .showError(let message):
            return AppleSignInStateChange(isBusy: false, errorMessage: message, resolutionContext: nil)
        }
    }

    func handleAppleResultAction(
        appState: AppState,
        modelContext: ModelContext
    ) -> (Result<ASAuthorization, Error>) -> Void {
        { result in
            _ = handleAppleResult(result, appState: appState, modelContext: modelContext)
        }
    }

    @discardableResult
    func handleAppleResult(
        _ result: Result<ASAuthorization, Error>,
        appState: AppState,
        modelContext: ModelContext
    ) -> Task<Void, Never>? {
        apply(decision: Self.decision(for: Self.payload(from: result)), appState: appState, modelContext: modelContext)
    }

    @discardableResult
    func apply(
        decision: AppleSignInDecision,
        appState: AppState,
        modelContext: ModelContext
    ) -> Task<Void, Never>? {
        let stateChange = Self.stateChange(for: decision)
        isBusy = stateChange.isBusy
        errorMessage = stateChange.errorMessage
        guard let context = stateChange.resolutionContext else { return nil }
        return resolve(context: context, appState: appState, modelContext: modelContext)
    }

    @discardableResult
    func resolve(
        context: AppleSignInResolutionContext,
        appState: AppState,
        modelContext: ModelContext
    ) -> Task<Void, Never> {
        Task { @MainActor in
            defer { isBusy = false }
            await Self.resolveAndApply(context, appState: appState, modelContext: modelContext)
        }
    }

    @MainActor
    static func resolveAndApply(
        _ context: AppleSignInResolutionContext,
        appState: AppState,
        modelContext: ModelContext
    ) async {
        let state = await appState.authService.resolveAfterAppleSignIn(
            appleUserID: context.userID,
            fullName: context.fullName,
            email: context.email,
            modelContext: modelContext
        )
        appState.apply(state)
    }

    @discardableResult
    func apply(
        decision: AppleSignInDecision,
        resolver: @escaping @MainActor (AppleSignInResolutionContext) async -> Void
    ) -> Task<Void, Never>? {
        let stateChange = Self.stateChange(for: decision)
        isBusy = stateChange.isBusy
        errorMessage = stateChange.errorMessage

        guard let context = stateChange.resolutionContext else { return nil }
        return Task { @MainActor in
            defer { isBusy = false }
            await resolver(context)
        }
    }
}
