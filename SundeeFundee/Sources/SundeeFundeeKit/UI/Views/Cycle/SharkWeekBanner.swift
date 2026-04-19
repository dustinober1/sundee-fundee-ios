import SwiftUI

// MARK: - SharkWeekBanner
//
// Pulsing red banner shown on every screen when the user is in the menstrual phase.
// Displayed as an overlay from MainTabView.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct SharkWeekBanner: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Text("\u{1F988}")
                .font(.caption)

            Text("Shark Week")
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(.white)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Capsule().fill(AppTheme.Accent.orange))
        .opacity(isPulsing ? 0.7 : 1.0)
        .scaleEffect(isPulsing ? 0.98 : 1.0)
        .shadow(color: AppTheme.Accent.orange.opacity(isPulsing ? 0.3 : 0.5), radius: isPulsing ? 2 : 4, y: 1)
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
// Thin wrapper that reads from CyclePhaseCache.
// Previously duplicated all cycle-phase CloudKit + HealthKit queries —
// now delegates to the shared cache so the work happens only once.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
final class SharkWeekMonitor: ObservableObject {
    @Published var isSharkWeek: Bool = false

    func sync(with cache: CyclePhaseCache) {
        isSharkWeek = cache.isSharkWeek
    }
}
