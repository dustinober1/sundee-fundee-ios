import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionLabel: String?
    let action: (() -> Void)?
    let secondaryActionLabel: String?
    let secondaryAction: (() -> Void)?

    public init(
        icon: String,
        title: String,
        subtitle: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil,
        secondaryActionLabel: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionLabel = actionLabel
        self.action = action
        self.secondaryActionLabel = secondaryActionLabel
        self.secondaryAction = secondaryAction
    }

    public var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: icon)
                .font(.system(.largeTitle))
                .foregroundColor(AppTheme.Accent.gold.opacity(0.5))
                .accessibilityHidden(true)

            Text(title)
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)

            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .artDecoButton(style: .primary)
            }

            if let secondaryActionLabel, let secondaryAction {
                Button(secondaryActionLabel, action: secondaryAction)
                    .artDecoButton(style: .ghost)
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
