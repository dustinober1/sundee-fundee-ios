import SwiftUI

// MARK: - SharkWeekBanner
//
// Status pill shown during the menstrual phase when enabled in settings.
// Supports custom terminology styles (casual, physiological, hormonal)
// and user dismissal. Displayed as an overlay from MainTabView or embedded.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct SharkWeekBanner: View {
    var terminologyStyle: CycleTerminologyStyle = .casual
    var onDismiss: (() -> Void)?

    @State private var isPulsing = false

    private var bannerTitle: String {
        switch terminologyStyle {
        case .casual:
            return "Shark Week"
        case .physiological:
            return "Menstrual Phase"
        case .hormone:
            return "Low Hormone Phase"
        }
    }

    private var bannerIcon: String {
        switch terminologyStyle {
        case .casual:
            return "\u{1F988}"
        case .physiological, .hormone:
            return "drop.fill"
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            if terminologyStyle == .casual {
                Text(bannerIcon)
                    .font(.caption)
            } else {
                Image(systemName: bannerIcon)
                    .font(.caption)
                    .foregroundColor(.white)
            }

            Text(bannerTitle)
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(.white)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.leading, AppTheme.Spacing.xs)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss banner")
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Capsule().fill(AppTheme.Accent.orange))
        .opacity(isPulsing ? 0.85 : 1.0)
        .scaleEffect(isPulsing ? 0.98 : 1.0)
        .shadow(color: AppTheme.Accent.orange.opacity(isPulsing ? 0.25 : 0.45), radius: isPulsing ? 2 : 4, y: 1)
        .animation(
            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear {
            isPulsing = true
        }
        .accessibilityLabel("\(bannerTitle) — cycle phase active")
    }
}

// MARK: - SharkWeekMonitor
//
// Thin wrapper that reads from CyclePhaseCache.
// Respects gym privacy and banner toggle.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
final class SharkWeekMonitor: ObservableObject {
    @Published var isSharkWeek: Bool = false

    func sync(with cache: CyclePhaseCache) {
        if cache.isGymPrivacyEnabled || !cache.showSharkWeekBanner {
            isSharkWeek = false
        } else {
            isSharkWeek = cache.isSharkWeek
        }
    }
}
