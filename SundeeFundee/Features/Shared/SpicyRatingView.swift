import SwiftUI

/// Pepper-based difficulty rating (1–5). Tap to select, tap again to deselect.
struct SpicyRatingView: View {
    @Binding var rating: Int?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("How spicy was it?")
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.navy)

            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        rating = rating == level ? nil : level
                    } label: {
                        Image(systemName: level <= (rating ?? 0) ? "flame.fill" : "flame")
                            .font(.system(size: 32))
                            .foregroundStyle(level <= (rating ?? 0) ? AppTheme.Colors.accentOrange : AppTheme.Colors.navy.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(level) pepper\(level == 1 ? "" : "s")")
                    .accessibilityHint(rating == level ? "Double tap to deselect" : "Double tap to rate \(level) out of 5")
                    .accessibilityAddTraits(rating == level ? .isSelected : [])
                }
            }

            if let rating {
                Text(Self.label(for: rating))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: rating)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    /// Maps a 1–5 rating to a display label. Returns empty string for out-of-range.
    static func label(for rating: Int) -> String {
        switch rating {
        case 1: return "Mild"
        case 2: return "Warm"
        case 3: return "Medium"
        case 4: return "Hot"
        case 5: return "Inferno"
        default: return ""
        }
    }
}
