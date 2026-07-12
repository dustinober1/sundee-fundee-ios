import SwiftUI

/// A privacy-first deload outcome card. Deload cards carry only the explicit,
/// safe summary supplied by the caller.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct DeloadShareView: View {
    let summary: ShareSanitizedSummary
    let aspect: ShareCardAspect
    let privacyOptions: SharePrivacyOptions

    var body: some View {
        SanitizedOutcomeShareView(
            summary: summary,
            badge: "DELOAD",
            aspect: aspect,
            privacyOptions: privacyOptions,
            accessibilityLabel: "Deload share card: \(summary.title)"
        )
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct SanitizedOutcomeShareView: View {
    let summary: ShareSanitizedSummary
    let badge: String
    let aspect: ShareCardAspect
    let privacyOptions: SharePrivacyOptions
    let accessibilityLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(badge)
                .font(AppTheme.Typography.labelSmall)
                .tracking(1.6)
                .foregroundColor(AppTheme.Text.gold)

            Text(summary.title)
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Text.cream)
                .lineLimit(3)

            if let subtitle = summary.subtitle {
                Text(privacyOptions.redactSensitiveText(subtitle))
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.cream.opacity(0.9))
                    .lineLimit(4)
            }

            if let label = summary.metricLabel, let value = summary.metricValue {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(label.uppercased())
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Text.gold)
                    Text(value)
                        .font(AppTheme.Typography.displaySmall)
                        .foregroundColor(AppTheme.Text.cream)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(label), \(value)")
            }

            Spacer()
            ShareFooter(palette: .onDark)
        }
        .padding(.horizontal, aspect == .story ? AppTheme.Spacing.xl : AppTheme.Spacing.xxl)
        .padding(.top, aspect == .story ? AppTheme.Spacing.xxl : AppTheme.Spacing.xl)
        .padding(.bottom, AppTheme.Spacing.lg)
        .frame(width: aspect.size.width, height: aspect.size.height, alignment: .leading)
        .background(AppTheme.Background.navy)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }
}
