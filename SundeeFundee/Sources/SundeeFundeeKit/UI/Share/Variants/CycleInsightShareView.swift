import SwiftUI

// MARK: - CycleInsightShareView
//
// Cycle-aware insight share card — the differentiator. Shows the current phase,
// cycle day, and a short trainer-voice insight line.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct CycleInsightShareView: View {
    let phase: CyclePhase
    let cycleDay: Int
    let insight: String
    let aspect: ShareCardAspect
    let shareURL: URL

    var body: some View {
        ZStack {
            AppTheme.Background.brandCream
            phaseBand
            VStack(spacing: AppTheme.Spacing.lg) {
                topBadge
                Spacer()
                Text(phaseHeading)
                    .font(AppTheme.Typography.displayLarge)
                    .foregroundColor(AppTheme.Text.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                Text("Day \(cycleDay)")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                    .tracking(2)
                divider
                Text(insight)
                    .font(AppTheme.Typography.bodyLarge)
                    .foregroundColor(AppTheme.Text.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                Spacer()
                ShareFooter(palette: .onLight)
                    .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.xxl)
            #if canImport(UIKit)
            if #available(iOS 18.0, *) {
                QRBadge(url: shareURL, size: aspect.size.width * 0.10)
                    .padding(AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            #endif
        }
        .frame(width: aspect.size.width, height: aspect.size.height)
    }

    private var phaseBand: some View {
        Rectangle()
            .fill(phase.chartBandColor.opacity(0.18))
            .frame(height: aspect.size.height * 0.25)
            .frame(maxHeight: .infinity, alignment: .top)
    }

    private var topBadge: some View {
        Text(phase.rawValue.uppercased())
            .font(AppTheme.Typography.labelLarge)
            .tracking(4)
            .foregroundColor(AppTheme.Text.primary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(phase.chartBandColor, lineWidth: 1)
            )
    }

    private var divider: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Rectangle()
                .fill(AppTheme.Accent.gold.opacity(0.35))
                .frame(height: 1)
            Circle()
                .fill(AppTheme.Accent.gold)
                .frame(width: 5, height: 5)
            Rectangle()
                .fill(AppTheme.Accent.gold.opacity(0.35))
                .frame(height: 1)
        }
        .frame(maxWidth: 180)
    }

    private var phaseHeading: String {
        switch phase {
        case .menstrual:  return "Honor Your Rhythm"
        case .follicular: return "Build & Rise"
        case .ovulation:  return "Peak Power"
        case .luteal:     return "Steady Strength"
        }
    }
}
