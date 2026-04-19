import SwiftUI

// MARK: - ShareFooter
//
// Reusable footer strip for share cards. Renders a thin gold ornament rule above
// the wordmark and tagline. Intended to sit at the bottom of a card over any
// background (works on navy, cream, or photo overlays via the `palette` arg).

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ShareFooter: View {
    enum Palette {
        case onDark
        case onLight

        var wordmark: Color {
            switch self {
            case .onDark:  return AppTheme.Text.cream
            case .onLight: return AppTheme.Text.primary
            }
        }

        var tagline: Color {
            switch self {
            case .onDark:  return AppTheme.Text.gold
            case .onLight: return AppTheme.Text.secondary
            }
        }

        var ornament: Color {
            AppTheme.Accent.gold
        }
    }

    let palette: Palette

    init(palette: Palette = .onDark) {
        self.palette = palette
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            ornamentRule
            Text("SUNDEE FUNDEE")
                .font(AppTheme.Typography.headlineSmall)
                .tracking(3)
                .foregroundColor(palette.wordmark)
            Text("Cycle-aware training")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(palette.tagline)
        }
    }

    private var ornamentRule: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Rectangle()
                .fill(palette.ornament.opacity(0.35))
                .frame(height: 1)
            Circle()
                .fill(palette.ornament)
                .frame(width: 4, height: 4)
            Rectangle()
                .fill(palette.ornament.opacity(0.35))
                .frame(height: 1)
        }
        .frame(maxWidth: 180)
    }
}
