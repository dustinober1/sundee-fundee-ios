import SwiftUI

struct ReadinessCard: View {
    let result: ReadinessResult?
    let onCheckIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DAILY READINESS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                        .tracking(1.5)
                    if let result {
                        Text(ReadinessSurvey.tierDisplayName(result.tier))
                            .font(AppTheme.Fonts.subheading)
                            .foregroundStyle(AppTheme.Colors.navy)
                    } else {
                        Text("Not checked in yet")
                            .font(AppTheme.Fonts.subheading)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
                Spacer()
                if let result {
                    Text(String(format: "%.1f", result.score))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(ReadinessSurveySheet.tierColor(result.tier))
                } else {
                    Image(systemName: "heart.text.clipboard")
                        .font(.title2)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }

            Button(action: onCheckIn) {
                Label(
                    result == nil ? "Check In" : "Update",
                    systemImage: result == nil ? "plus.circle.fill" : "arrow.clockwise"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("readiness-check-in-button")
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}
