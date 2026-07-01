import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct SupportDeveloperSection: View {
    @StateObject private var viewModel: SupportTipViewModel

    public init(viewModel: SupportTipViewModel = SupportTipViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Section("Support") {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Label("Support the Developer", systemImage: "heart.circle")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Text.primary)

                Text("Optional tip. All features stay free.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, AppTheme.Spacing.xs)

            Button {
                Task {
                    await viewModel.purchase()
                    if viewModel.message == "Thank you for supporting Sundee Fundee." {
                        HapticFeedback.success()
                    }
                }
            } label: {
                HStack {
                    Text("Send \(viewModel.priceText) Tip")
                    Spacer()
                    if viewModel.state == .purchasing {
                        ProgressView()
                            .accessibilityLabel("Sending support tip")
                    }
                }
            }
            .disabled(viewModel.isPurchaseDisabled)
            .accessibilityHint("Sends an optional repeatable tip. It is not required for any feature.")

            if let message = viewModel.message {
                Text(message)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(viewModel.state == .failed ? AppTheme.Semantic.error : AppTheme.Text.secondary)
            }
        }
        .task {
            await viewModel.loadOffer()
        }
    }
}
