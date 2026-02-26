import SwiftUI

// MARK: - PrimaryButtonStyle

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Fonts.subheading)
            .foregroundStyle(AppTheme.Colors.cream)
            .padding(.vertical, AppTheme.Spacing.sm + 4)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                configuration.isPressed
                    ? AppTheme.Colors.accentOrange.opacity(0.8)
                    : AppTheme.Colors.accentOrange
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - DestructiveButtonStyle

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Fonts.body)
            .foregroundStyle(
                configuration.isPressed
                    ? AppTheme.Colors.error.opacity(0.7)
                    : AppTheme.Colors.error
            )
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.error.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - SecondaryButtonStyle

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Fonts.body)
            .foregroundStyle(AppTheme.Colors.navy)
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
                    .stroke(AppTheme.Colors.navy.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
