import SwiftUI

// MARK: - NewPRShareView
//
// Celebratory "New Personal Record" share card. Big weight, exercise name,
// delta vs previous best. Branded footer.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct NewPRShareView: View {
    let exerciseName: String
    let weight: Double
    let unit: String
    let previousBest: Double?
    let aspect: ShareCardAspect
    let shareURL: URL

    var body: some View {
        ZStack {
            AppTheme.Background.navy
            goldRadial
            VStack(spacing: AppTheme.Spacing.lg) {
                Spacer()
                Text("NEW PR")
                    .font(AppTheme.Typography.headlineMedium)
                    .tracking(8)
                    .foregroundColor(AppTheme.Accent.gold)
                starOrnament
                Text(exerciseName)
                    .font(AppTheme.Typography.displayMedium)
                    .foregroundColor(AppTheme.Text.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                weightBlock
                if let delta = deltaText {
                    Text(delta)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.gold)
                }
                Spacer()
                ShareFooter(palette: .onDark)
                    .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
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

    private var goldRadial: some View {
        RadialGradient(
            colors: [AppTheme.Accent.gold.opacity(0.18), Color.clear],
            center: .center,
            startRadius: 0,
            endRadius: aspect.size.width * 0.6
        )
        .blendMode(.plusLighter)
    }

    private var starOrnament: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Rectangle()
                .fill(AppTheme.Accent.gold.opacity(0.5))
                .frame(width: 40, height: 1)
            Image(systemName: "star.fill")
                .font(.headline)
                .foregroundColor(AppTheme.Accent.gold)
            Rectangle()
                .fill(AppTheme.Accent.gold.opacity(0.5))
                .frame(width: 40, height: 1)
        }
    }

    private var weightBlock: some View {
        VStack(spacing: 4) {
            Text(weightString)
                .font(.system(size: aspect == .story ? 96 : 84, weight: .bold, design: .serif))
                .foregroundColor(AppTheme.Text.cream)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(unit.uppercased())
                .font(AppTheme.Typography.headlineSmall)
                .tracking(4)
                .foregroundColor(AppTheme.Accent.gold)
        }
    }

    private var weightString: String {
        if weight == floor(weight) { return "\(Int(weight))" }
        return String(format: "%.1f", weight)
    }

    private var deltaText: String? {
        guard let prev = previousBest, prev > 0 else { return nil }
        let delta = weight - prev
        guard delta > 0 else { return nil }
        let deltaStr: String = (delta == floor(delta))
            ? "\(Int(delta))"
            : String(format: "%.1f", delta)
        return "+\(deltaStr) \(unit) over previous best"
    }
}
