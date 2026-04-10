import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - AppTheme
//
// Art Deco design system for Sundee Fundee.
// Matches the web app's cream/navy/orange color scheme.
//
// Colors:
// - Cream: #f4f0df (background)
// - Navy: #0d1a40 (primary text, cards)
// - Gold: #d4a520 (accents, highlights)
// - Orange: #f27319 (CTAs, active states)
//
// Typography:
// - Display/Headline: Fixed-size (per CONTEXT.md decision)
// - Body/Label/Mono: Dynamic Type-scalable via UIFontMetrics (AUD-05)

/// App theme container for Art Deco design tokens
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public enum AppTheme {
    // MARK: - Colors

    /// Background colors
    public enum Background {
        public static let cream = Color(red: 0.956, green: 0.941, blue: 0.874) // #f4f0df
        public static let navy = Color(red: 0.051, green: 0.102, blue: 0.251) // #0d1a40
        public static let white = Color.white
        public static let card = Color.white.opacity(0.8)
    }

    /// Text colors
    public enum Text {
        public static let primary = Color(red: 0.051, green: 0.102, blue: 0.251) // #0d1a40
        public static let secondary = Color(red: 0.251, green: 0.325, blue: 0.498) // #40537f
        public static let cream = Color(red: 0.956, green: 0.941, blue: 0.874) // #f4f0df
        public static let gold = Color(red: 0.831, green: 0.647, blue: 0.125) // #d4a520
        public static let orange = Color(red: 0.949, green: 0.451, blue: 0.098) // #f27319
        public static let white = Color.white
    }

    /// Accent colors
    public enum Accent {
        public static let gold = Color(red: 0.831, green: 0.647, blue: 0.125) // #d4a520
        public static let goldLight = Color(red: 0.831, green: 0.647, blue: 0.125, opacity: 0.3)
        public static let goldDark = Color(red: 0.663, green: 0.518, blue: 0.100) // #a98419
        public static let orange = Color(red: 0.949, green: 0.451, blue: 0.098) // #f27319
        public static let orangeLight = Color(red: 0.949, green: 0.451, blue: 0.098, opacity: 0.2)
    }

    /// Semantic colors
    public enum Semantic {
        public static let success = Color.green
        public static let warning = Color.orange
        public static let error = Color.red
        public static let info = Color.blue
    }

    // MARK: - Spacing

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    public enum CornerRadius {
        public static let small: CGFloat = 6
        public static let medium: CGFloat = 10
        public static let large: CGFloat = 16
        public static let xlarge: CGFloat = 24
        public static let circle: CGFloat = 9999
    }

    // MARK: - Typography

    /// Custom font sizes and weights.
    /// Display and headline fonts are fixed-size (per CONTEXT.md decision).
    /// Body, label, and mono fonts scale with Dynamic Type via UIFontMetrics (AUD-05).
    public enum Typography {
        // Display - headings (FIXED SIZE)
        public static let displayLarge = Font.system(size: 32, weight: .bold, design: .serif)
        public static let displayMedium = Font.system(size: 24, weight: .bold, design: .serif)
        public static let displaySmall = Font.system(size: 20, weight: .semibold, design: .serif)

        // Headline - section headers (FIXED SIZE)
        public static let headlineLarge = Font.system(size: 18, weight: .semibold)
        public static let headlineMedium = Font.system(size: 16, weight: .semibold)
        public static let headlineSmall = Font.system(size: 14, weight: .medium)

        // Body - content text (DYNAMIC TYPE scalable)
        /// Scales with Dynamic Type. Base 16pt at default size.
        public static var bodyLarge: Font {
            scaledFont(baseSize: 16, weight: .regular)
        }
        /// Scales with Dynamic Type. Base 14pt at default size.
        public static var bodyMedium: Font {
            scaledFont(baseSize: 14, weight: .regular)
        }
        /// Scales with Dynamic Type. Base 12pt at default size.
        public static var bodySmall: Font {
            scaledFont(baseSize: 12, weight: .regular)
        }

        // Label - metadata, captions (DYNAMIC TYPE scalable)
        /// Scales with Dynamic Type. Base 12pt at default size.
        public static var labelLarge: Font {
            scaledFont(baseSize: 12, weight: .medium)
        }
        /// Scales with Dynamic Type. Base 11pt at default size.
        public static var labelMedium: Font {
            scaledFont(baseSize: 11, weight: .medium)
        }
        /// Scales with Dynamic Type. Base 10pt at default size.
        public static var labelSmall: Font {
            scaledFont(baseSize: 10, weight: .medium)
        }

        // Mono - numbers, IDs, metrics (DYNAMIC TYPE scalable)
        /// Scales with Dynamic Type. Base 14pt at default size, monospaced.
        public static var monoLarge: Font {
            scaledFont(baseSize: 14, weight: .regular, design: .monospaced)
        }
        /// Scales with Dynamic Type. Base 12pt at default size, monospaced.
        public static var monoMedium: Font {
            scaledFont(baseSize: 12, weight: .regular, design: .monospaced)
        }
        /// Scales with Dynamic Type. Base 10pt at default size, monospaced.
        public static var monoSmall: Font {
            scaledFont(baseSize: 10, weight: .regular, design: .monospaced)
        }

        /// Scales a font size using UIFontMetrics for Dynamic Type support.
        /// Falls back to fixed size on non-iOS platforms.
        private static func scaledFont(
            baseSize: CGFloat,
            weight: Font.Weight,
            design: Font.Design? = nil
        ) -> Font {
            #if os(iOS)
            let metrics = UIFontMetrics(forTextStyle: .body)
            let scaledSize = metrics.scaledValue(for: baseSize)
            if let design {
                return Font.system(size: scaledSize, weight: weight, design: design)
            }
            return Font.system(size: scaledSize, weight: weight)
            #else
            if let design {
                return Font.system(size: baseSize, weight: weight, design: design)
            }
            return Font.system(size: baseSize, weight: weight)
            #endif
        }
    }
}

// MARK: - View Extensions

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
extension View {
    /// Applies the Art Deco cream background
    public func artDecoBackground() -> some View {
        self.background(AppTheme.Background.cream)
    }

    /// Applies the standard card style
    public func artDecoCard() -> some View {
        self
            .background(AppTheme.Background.card)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    /// Prevents text clipping at large Dynamic Type sizes by allowing
    /// the font to scale down to 50% of its rendered size within a single line.
    /// Apply to constrained text elements like stat values, metrics, and badges.
    public func artDecoScalableText() -> some View {
        self.minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}

// MARK: - Custom Button Style

/// App button style options
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public enum AppButtonStyle {
    case primary     // Navy background, cream text
    case secondary   // Cream background, navy text, gold border
    case accent      // Orange background, white text
    case ghost       // Transparent, navy text
    case destructive // Red background, white text
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ArtDecoButtonStyle: SwiftUI.ButtonStyle {
    let style: AppButtonStyle

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.labelLarge)
            .foregroundColor(foregroundColor(for: configuration.isPressed))
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(backgroundColor(for: configuration.isPressed))
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(borderColor(for: configuration.isPressed) ?? Color.clear, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private func foregroundColor(for isPressed: Bool) -> Color {
        switch style {
        case .primary, .accent, .destructive:
            return .white
        case .secondary, .ghost:
            return AppTheme.Text.primary
        }
    }

    private func backgroundColor(for isPressed: Bool) -> Color {
        switch style {
        case .primary:
            return isPressed ? Color(red: 0.04, green: 0.08, blue: 0.2) : AppTheme.Background.navy
        case .secondary:
            return isPressed ? AppTheme.Background.cream.opacity(0.8) : AppTheme.Background.cream
        case .accent:
            return isPressed ? Color(red: 0.8, green: 0.35, blue: 0.05) : AppTheme.Accent.orange
        case .ghost:
            return .clear
        case .destructive:
            return isPressed ? Color.red.opacity(0.8) : Color.red
        }
    }

    private func borderColor(for isPressed: Bool) -> Color? {
        switch style {
        case .secondary:
            return isPressed ? AppTheme.Accent.goldLight : AppTheme.Accent.gold
        case .ghost:
            return AppTheme.Text.primary.opacity(0.3)
        default:
            return nil
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
extension View {
    /// Applies the Art Deco button style
    public func artDecoButton(style: AppButtonStyle = .primary) -> some View {
        self.buttonStyle(ArtDecoButtonStyle(style: style))
    }
}

// MARK: - Custom Card View

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ArtDecoCard<Content: View>: View {
    let content: Content
    let padding: EdgeInsets

    public init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
    }

    public var body: some View {
        content
            .padding(padding)
            .background(AppTheme.Background.card)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Stat Card Component

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct StatCard: View {
    let value: String
    let label: String

    public init(value: String, label: String) {
        self.value = value
        self.label = label
    }

    public var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Text.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)

            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.secondary)
                .artDecoScalableText()
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Background.card)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
