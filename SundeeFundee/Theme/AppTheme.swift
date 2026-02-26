import SwiftUI

/// Design token namespace matching the Flutter app's cream/navy/orange Art Deco theme.
enum AppTheme {
    // MARK: - Colors
    enum Color {
        static let cream     = SwiftUI.Color(red: 0.98, green: 0.96, blue: 0.92)
        static let navy      = SwiftUI.Color(red: 0.05, green: 0.10, blue: 0.25)
        static let orange    = SwiftUI.Color(red: 0.95, green: 0.45, blue: 0.10)
        static let gold      = SwiftUI.Color(red: 0.85, green: 0.70, blue: 0.30)
        static let cardBg    = SwiftUI.Color(red: 0.99, green: 0.98, blue: 0.95)
        static let separator = SwiftUI.Color(red: 0.88, green: 0.85, blue: 0.78)
        static let textPrimary   = navy
        static let textSecondary = SwiftUI.Color(red: 0.35, green: 0.38, blue: 0.50)
        static let error     = SwiftUI.Color(red: 0.85, green: 0.15, blue: 0.15)
    }

    /// Semantic aliases (preferred in feature views)
    enum Colors {
        static let cream          = Color.cream
        static let navy           = Color.navy
        static let accentOrange   = Color.orange
        static let gold           = Color.gold
        static let cardBackground = Color.cardBg
        static let separator      = Color.separator
        static let textPrimary    = Color.textPrimary
        static let textSecondary  = Color.textSecondary
        static let error          = Color.error
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat  =  4
        static let sm: CGFloat  =  8
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 24
        static let xl: CGFloat  = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner radii
    enum Radius {
        static let sm: CGFloat =  6
        static let md: CGFloat = 12
        static let lg: CGFloat = 20
    }

    enum CornerRadius {
        static let card: CGFloat = 12
        static let button: CGFloat = 8
    }

    // MARK: - Fonts
    enum Font {
        static func heading(_ size: CGFloat, weight: SwiftUI.Font.Weight = .bold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .serif)
        }
        static func body(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
        static func mono(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }
    }

    /// Named font styles used throughout feature views
    enum Fonts {
        static let heading   = SwiftUI.Font.system(size: 22, weight: .bold, design: .serif)
        static let subheading = SwiftUI.Font.system(size: 17, weight: .semibold, design: .serif)
        static let body      = SwiftUI.Font.system(size: 15, weight: .regular)
        static let caption   = SwiftUI.Font.system(size: 13, weight: .regular)
        static let mono      = SwiftUI.Font.system(size: 14, weight: .medium, design: .monospaced)
    }
}

// MARK: - View modifiers

extension View {
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Color.cardBg)
            .cornerRadius(AppTheme.Radius.md)
            .shadow(color: AppTheme.Color.navy.opacity(0.08), radius: 4, y: 2)
    }
}
