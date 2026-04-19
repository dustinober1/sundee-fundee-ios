#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - SelfieOverlayShareView
//
// User-supplied photo with workout summary overlay. Navy gradient in the bottom
// 45% of the card keeps text legible on any photo. Branded footer.

@available(iOS 18.0, *)
struct SelfieOverlayShareView: View {
    let image: UIImage
    let summary: ShareSummary
    let aspect: ShareCardAspect

    var body: some View {
        ZStack(alignment: .bottom) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: aspect.size.width, height: aspect.size.height)
                .clipped()

            LinearGradient(
                colors: [
                    Color.clear,
                    AppTheme.Background.navy.opacity(0.55),
                    AppTheme.Background.navy.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: aspect.size.height * 0.55)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(summary.title)
                    .font(AppTheme.Typography.displaySmall)
                    .foregroundColor(AppTheme.Text.cream)
                    .lineLimit(2)
                HStack(spacing: AppTheme.Spacing.lg) {
                    metric(value: "\(summary.durationMinutes)", label: "min")
                    metric(value: "\(summary.exerciseCount)", label: "lifts")
                    metric(value: volumeString, label: summary.weightUnit + " vol")
                }
                ShareFooter(palette: .onDark)
                    .padding(.top, AppTheme.Spacing.sm)
            }
            .padding(AppTheme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)

            // QR badge: bottom-right, sized ~10% of card width.
            QRBadge(url: ShareURL.appStore, size: aspect.size.width * 0.10)
                .padding(AppTheme.Spacing.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(width: aspect.size.width, height: aspect.size.height)
        .background(AppTheme.Background.navy)
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(AppTheme.Typography.monoLarge)
                .foregroundColor(AppTheme.Text.cream)
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.gold)
                .tracking(1.5)
        }
    }

    private var volumeString: String {
        let v = summary.totalVolume
        if v >= 10_000 {
            return String(format: "%.1fk", v / 1000)
        }
        if v == floor(v) {
            return "\(Int(v))"
        }
        return String(format: "%.0f", v)
    }
}
#endif
