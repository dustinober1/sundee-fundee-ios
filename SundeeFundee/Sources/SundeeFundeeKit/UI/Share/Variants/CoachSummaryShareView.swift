import SwiftUI

// MARK: - CoachSummaryShareView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct CoachSummaryShareView: View {
    let title: String
    let subtitle: String
    let badge: String
    let bullets: [String]
    let aspect: ShareCardAspect

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text(badge.uppercased())
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.gold)
                    .tracking(1.6)
                Spacer()
            }

            Text(title)
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Text.cream)
                .lineLimit(3)

            Text(subtitle)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.cream.opacity(0.9))
                .lineLimit(4)

            if !bullets.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    ForEach(Array(bullets.enumerated()), id: \.offset) { _, bullet in
                        HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                            Circle()
                                .fill(AppTheme.Accent.gold)
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)
                            Text(bullet)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.cream.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Spacer()
            ShareFooter(palette: .onDark)
        }
        .padding(.horizontal, aspect == .story ? AppTheme.Spacing.xl : AppTheme.Spacing.xxl)
        .padding(.top, aspect == .story ? AppTheme.Spacing.xxl : AppTheme.Spacing.xl)
        .padding(.bottom, AppTheme.Spacing.lg)
        .frame(width: aspect.size.width, height: aspect.size.height, alignment: .leading)
        .background(AppTheme.Background.navy)
    }
}
