import SwiftUI

struct ReadinessSurveySheet: View {
    @State var viewModel: ReadinessSurveyViewModel
    let onSubmit: (ReadinessResult) -> Void
    let onSkip: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.cream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        headerSection
                        previewSection
                        slidersSection
                        submitButton
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Readiness Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { onSkip() }
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var headerSection: some View {
        Text("How are you feeling?")
            .font(AppTheme.Fonts.heading)
            .foregroundStyle(AppTheme.Colors.navy)
    }

    private var previewSection: some View {
        let preview = viewModel.livePreview
        return VStack(spacing: AppTheme.Spacing.sm) {
            Text(String(format: "%.1f", preview.score))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(Self.tierColor(preview.tier))
            Text(ReadinessSurvey.tierDisplayName(preview.tier))
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.navy)
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }

    private var slidersSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            sliderRow(title: "Sleep Quality", value: $viewModel.sleepQuality, lowLabel: "Poor", highLabel: "Great")
            sliderRow(title: "Stress Level", value: $viewModel.stressLevel, lowLabel: "Calm", highLabel: "Stressed")
            sliderRow(title: "Soreness Level", value: $viewModel.sorenessLevel, lowLabel: "Fresh", highLabel: "Very Sore")
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, lowLabel: String, highLabel: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(title)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                Spacer()
                Text(String(format: "%.0f", value.wrappedValue))
                    .font(AppTheme.Fonts.body.monospacedDigit())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Slider(value: value, in: 1...10, step: 1)
                .tint(AppTheme.Colors.accentOrange)
            HStack {
                Text(lowLabel)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Spacer()
                Text(highLabel)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    private var submitButton: some View {
        Button {
            viewModel.submit()
            onSubmit(viewModel.livePreview)
        } label: {
            Label("Start Workout", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityIdentifier("readiness-submit-button")
    }

    static func tierColor(_ tier: AdaptationReadinessTier) -> Color {
        switch tier {
        case .low: AppTheme.Colors.warmRose
        case .neutral: AppTheme.Colors.navy
        case .high: AppTheme.Colors.accentOrange
        }
    }
}
