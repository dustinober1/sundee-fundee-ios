import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct SkeletonCard: View {
    let height: CGFloat
    @State private var shimmerPhase: CGFloat = -1

    public init(height: CGFloat = 80) {
        self.height = height
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
            .fill(AppTheme.Background.card)
            .frame(height: height)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            AppTheme.Accent.goldLight.opacity(0.0),
                            AppTheme.Accent.goldLight.opacity(0.35),
                            AppTheme.Accent.goldLight.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: shimmerPhase * geo.size.width)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1.5
                }
            }
            .accessibilityHidden(true)
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct SkeletonStatRow: View {
    public init() {}

    public var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            SkeletonCard(height: 80)
            SkeletonCard(height: 80)
            SkeletonCard(height: 80)
        }
        .accessibilityHidden(true)
    }
}
