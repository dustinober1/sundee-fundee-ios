import SwiftUI

// MARK: - ScreenshotModeBanner
//
// Benefit-first headline shown above the app UI while capturing App Store
// screenshots. Only renders when the app is launched with --seed-screenshots
// (see SundeeFundeeScreenshotTests and fastlane's capture_store_screenshots),
// so normal app runs are untouched.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public enum ScreenshotMode {
    public static let isEnabled = CommandLine.arguments.contains("--seed-screenshots")

    public static func caption(for tab: Tab) -> String {
        switch tab {
        case .today:
            return "Lift with your cycle, not against it."
        case .train:
            return "A plan that adapts to your energy, pain, and phase."
        case .cycle:
            return "Track your period. Train smarter."
        case .progress:
            return "Watch your strength climb, week by week."
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ScreenshotModeBanner: View {
    let caption: String

    public init(caption: String) {
        self.caption = caption
    }

    public var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(caption)
                .font(AppTheme.Typography.displaySmall)
                .foregroundStyle(AppTheme.Text.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle()
                .fill(AppTheme.Accent.gold)
                .frame(width: 48, height: 3)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(AppTheme.Background.brandCream)
        .accessibilityElement(children: .combine)
    }
}
