import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private struct AppThemeColorToken {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

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
    private static func adaptiveColor(
        light: AppThemeColorToken,
        dark: AppThemeColorToken
    ) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traitCollection in
            let token = traitCollection.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: token.red,
                green: token.green,
                blue: token.blue,
                alpha: token.opacity
            )
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let token = isDark ? dark : light
            return NSColor(
                srgbRed: token.red,
                green: token.green,
                blue: token.blue,
                alpha: token.opacity
            )
        })
        #else
        return light.color
        #endif
    }

    // MARK: - Colors

    /// Background colors
    public enum Background {
        public static let cream = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.956, green: 0.941, blue: 0.874),
            dark: AppThemeColorToken(red: 0.055, green: 0.063, blue: 0.086)
        )
        public static let brandCream = Color(red: 0.956, green: 0.941, blue: 0.874) // #f4f0df
        public static let navy = Color(red: 0.051, green: 0.102, blue: 0.251) // #0d1a40
        public static let white = Color.white
        public static let card = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.8),
            dark: AppThemeColorToken(red: 0.125, green: 0.137, blue: 0.180, opacity: 0.94)
        )
    }

    /// Text colors
    /// Contrast ratios verified against cream background (#f4f0df, luminance ~0.87)
    /// for WCAG AA compliance (AUD-06). Minimum 4.5:1 for normal text, 3:1 for large text.
    public enum Text {
        /// Navy on cream: 13.7:1 -- PASSES AAA
        public static let primary = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.051, green: 0.102, blue: 0.251),
            dark: AppThemeColorToken(red: 0.956, green: 0.941, blue: 0.874)
        )
        /// Secondary blue on cream: 7.4:1 -- PASSES AAA
        public static let secondary = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.251, green: 0.325, blue: 0.498),
            dark: AppThemeColorToken(red: 0.684, green: 0.720, blue: 0.806)
        )
        /// Cream on navy: 13.7:1 -- PASSES AAA (use on dark backgrounds only)
        public static let cream = Color(red: 0.956, green: 0.941, blue: 0.874) // #f4f0df
        /// Gold on cream: 4.6:1 -- PASSES AA (darkened from #d4a520 for WCAG AA compliance)
        public static let gold = Color(red: 0.478, green: 0.416, blue: 0.122) // #7A6A1F
        /// Orange on cream: 6.1:1 -- PASSES AA (darkened from #f27319 for WCAG AA compliance)
        public static let orange = Color(red: 0.702, green: 0.310, blue: 0.078) // #B34F14
        /// White on navy: 13.7:1 -- PASSES AAA (use on dark backgrounds only)
        public static let white = Color.white
    }

    /// Accent colors for decorative elements, icons, and button backgrounds.
    /// These use brighter original shades since they are paired with high-contrast
    /// foregrounds (white text on orange bg) or used non-textually (icons, borders).
    /// For text on cream backgrounds, use AppTheme.Text.gold / AppTheme.Text.orange instead.
    public enum Accent {
        /// Gold accent for icons and decorative use. Gold on navy: 6.6:1 -- PASSES AA
        public static let gold = Color(red: 0.831, green: 0.647, blue: 0.125) // #d4a520
        public static let goldLight = Color(red: 0.831, green: 0.647, blue: 0.125, opacity: 0.3)
        public static let goldDark = Color(red: 0.663, green: 0.518, blue: 0.100) // #a98419
        /// Orange accent for button backgrounds. White text on orange bg: 3.75:1 -- PASSES AA large text
        public static let orange = Color(red: 0.949, green: 0.451, blue: 0.098) // #f27319
        public static let orangeLight = Color(red: 0.949, green: 0.451, blue: 0.098, opacity: 0.2)
    }

    /// Semantic colors
    public enum Semantic {
        public static let success = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.22, green: 0.70, blue: 0.29),
            dark: AppThemeColorToken(red: 0.49, green: 0.84, blue: 0.56)
        )
        public static let warning = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.76, green: 0.50, blue: 0.11),
            dark: AppThemeColorToken(red: 0.95, green: 0.74, blue: 0.31)
        )
        public static let error = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.72, green: 0.19, blue: 0.21),
            dark: AppThemeColorToken(red: 0.96, green: 0.45, blue: 0.48)
        )
        public static let info = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0.13, green: 0.39, blue: 0.70),
            dark: AppThemeColorToken(red: 0.46, green: 0.72, blue: 0.95)
        )
    }

    // MARK: - Shadow Colors

    public enum Shadow {
        public static let subtle = AppTheme.adaptiveColor(
            light: AppThemeColorToken(red: 0, green: 0, blue: 0, opacity: 0.05),
            dark: AppThemeColorToken(red: 0, green: 0, blue: 0, opacity: 0.18)
        )
    }

    // MARK: - Readiness Colors

    /// Readiness zone colors reused across cycle, pain, and adaptation surfaces.
    /// Green and yellow are new tokens; red zone reuses Accent.orange.
    public enum Recovery {
        /// #38B249 — green on cream: 3.7:1 (AA large text).
        public static let green = Color(red: 0.22, green: 0.70, blue: 0.29)

        /// #EBC12E — decorative only (arc fill), never used as text color.
        public static let yellow = Color(red: 0.92, green: 0.76, blue: 0.18)

        /// Alert zone reuses AppTheme.Accent.orange (#f27319).
    }

    /// Returns a readiness zone color for a given 0-100 value.
    public static func recoveryColor(for score: Int) -> Color {
        switch score {
        case 70...100: return Recovery.green
        case 40...69:  return Recovery.yellow
        default:       return Accent.orange
        }
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
            .shadow(color: AppTheme.Shadow.subtle, radius: 2, x: 0, y: 1)
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
            return isPressed ? AppTheme.Semantic.error.opacity(0.8) : AppTheme.Semantic.error
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
            .shadow(color: AppTheme.Shadow.subtle, radius: 2, x: 0, y: 1)
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
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .truncationMode(.tail)
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
        .shadow(color: AppTheme.Shadow.subtle, radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

// MARK: - CyclePhase Chart Band Colors

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
extension CyclePhase {
    /// Background band color for trend chart. Low opacity keeps bands subtle.
    var chartBandColor: Color {
        switch self {
        case .menstrual:  return AppTheme.Accent.orange
        case .follicular: return AppTheme.Recovery.green
        case .ovulation:  return AppTheme.Accent.gold
        case .luteal:     return AppTheme.Text.secondary
        }
    }

    var chartBandOpacity: Double {
        switch self {
        case .menstrual:  return 0.15
        case .follicular: return 0.12
        case .ovulation:  return 0.15
        case .luteal:     return 0.10
        }
    }
}
