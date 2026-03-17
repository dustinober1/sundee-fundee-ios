import SwiftUI
import SwiftData

/// Routes between loading, sign-in, onboarding, and main app based on AppState.
struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState: AppState
    private let shouldRestoreSession: Bool
    @State private var subscriptionService = SubscriptionService()

    init(initialAppState: AppState = AppState(), shouldRestoreSession: Bool = true) {
        _appState = State(initialValue: initialAppState)
        self.shouldRestoreSession = shouldRestoreSession
    }

    enum Destination: Equatable {
        case loading
        case signedOut
        case onboarding(userID: String)
        case mainTabs
    }

    static func destination(for authState: AuthState) -> Destination {
        switch authState {
        case .loading:
            .loading
        case .signedOut:
            .signedOut
        case .needsOnboarding(let userID, _):
            .onboarding(userID: userID)
        case .authenticated, .guest:
            .mainTabs
        }
    }

    @MainActor
    static func restoreSession(into appState: AppState, modelContext: ModelContext) async {
        print("[AppRootView] Starting session restoration...")
        let state = await appState.authService.restoreSession(modelContext: modelContext)
        print("[AppRootView] Session restored to: \(state)")
        appState.apply(state)
    }

    @MainActor
    static func restoreSessionIfNeeded(
        shouldRestoreSession: Bool,
        appState: AppState,
        modelContext: ModelContext
    ) async {
        guard shouldRestoreSession else { return }
        await restoreSession(into: appState, modelContext: modelContext)
    }

    var body: some View {
        Group {
            switch Self.destination(for: appState.authState) {
            case .loading:
                LoadingView()
            case .signedOut:
                SignInView()
            case .onboarding(let userID):
                OnboardingFlowView(userID: userID)
            case .mainTabs:
                MainTabView()
            }
        }
        .environment(appState)
        .environment(subscriptionService)
        .task { await Self.restoreSessionIfNeeded(shouldRestoreSession: shouldRestoreSession, appState: appState, modelContext: modelContext) }
        .task { await subscriptionService.loadStatus() }
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
        .onAppear {
            print("[LoadingView] LoadingView appeared - waiting for auth state...")
        }
    }
}
