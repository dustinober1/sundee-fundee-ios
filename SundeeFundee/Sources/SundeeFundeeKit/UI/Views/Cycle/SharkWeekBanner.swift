import SwiftUI

// MARK: - SharkWeekBanner
//
// Pulsing red banner shown on every screen when the user is in the menstrual phase.
// Displayed as an overlay from MainTabView.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct SharkWeekBanner: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("\u{1F988}")
                .font(.system(size: 20))

            Text("Shark Week")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.red)
        )
        .opacity(isPulsing ? 0.7 : 1.0)
        .scaleEffect(isPulsing ? 0.97 : 1.0)
        .shadow(color: Color.red.opacity(isPulsing ? 0.3 : 0.5), radius: isPulsing ? 4 : 8, y: 2)
        .animation(
            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear {
            isPulsing = true
        }
        .accessibilityLabel("Shark Week — menstrual phase active")
    }
}

// MARK: - SharkWeekMonitor
//
// Lightweight observable that checks if the current cycle phase is menstrual.
// Used by MainTabView to decide whether to show the SharkWeekBanner.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
final class SharkWeekMonitor: ObservableObject {
    @Published var isSharkWeek: Bool = false

    private let healthClient: HealthClientProtocol

    init(healthClient: HealthClientProtocol = HealthClientFactory.shared.client) {
        self.healthClient = healthClient
    }

    func check() async {
        guard healthClient.isAvailable else { return }
        do {
            try? await healthClient.requestStandardAuthorization()
            let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
            let cycles = try await healthClient.fetchMenstrualCycles(
                startDate: sixMonthsAgo,
                endDate: nil,
                limit: 100
            )
            if let status = CyclePhaseHelper.calculatePhase(from: cycles) {
                isSharkWeek = status.currentPhase == .menstrual
            }
        } catch {
            // HealthKit not available or permission denied — degrade gracefully
        }
    }
}
