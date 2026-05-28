import SwiftUI

// MARK: - BuddyCheckInShareView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct BuddyCheckInShareView: View {
    let summary: BuddyCheckInSummary
    let displayName: String
    let aspect: ShareCardAspect

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("BUDDY CHECK-IN".uppercased())
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.gold)
                    .tracking(1.6)
                Spacer()
            }

            Text(displayName)
                .font(AppTheme.Typography.displayMedium)
                .foregroundColor(AppTheme.Text.cream)
                .lineLimit(2)

            Text("\(summary.completedCheckIns) of \(summary.totalCheckIns) check-ins completed this week")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.cream.opacity(0.9))

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Text.cream.opacity(0.2))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Accent.gold)
                        .frame(
                            width: summary.totalCheckIns > 0
                                ? geo.size.width * CGFloat(summary.completedCheckIns) / CGFloat(summary.totalCheckIns)
                                : 0,
                            height: 8
                        )
                }
            }
            .frame(height: 8)

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
