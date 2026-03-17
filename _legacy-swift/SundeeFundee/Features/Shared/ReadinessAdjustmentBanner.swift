import SwiftUI

struct ReadinessAdjustmentBanner: View {
    let tier: AdaptationReadinessTier

    var body: some View {
        if let text = ReadinessSurvey.adjustmentBannerText(for: tier) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: tier == .high ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                Text(text)
                    .font(AppTheme.Fonts.caption)
            }
            .foregroundStyle(tier == .high ? AppTheme.Colors.cream : .white)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.sm)
            .background(tier == .high ? AppTheme.Colors.accentOrange : AppTheme.Colors.warmRose)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        }
    }

    static func todayTier(defaults: UserDefaults = .standard) -> AdaptationReadinessTier? {
        guard let result = ReadinessSurvey.loadTodayResult(defaults: defaults) else { return nil }
        return result.tier == .neutral ? nil : result.tier
    }
}
