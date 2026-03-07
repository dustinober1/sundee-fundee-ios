import SwiftUI
import SwiftData

/// Settings for body weight tracking — used for AI workout generation context.
struct BodyWeightSettingView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Body Weight (Optional)") {
                HStack {
                    TextField("Enter weight", value: $viewModel.bodyWeight, format: .number)
                        .keyboardType(.decimalPad)

                    Picker("Unit", selection: $viewModel.weightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.symbol.uppercased()).tag(unit)
                        }
                    }
                    .frame(maxWidth: 80)
                }
            }

            Section {
                Text("Your body weight helps personalize AI workout generation — load calculations are based on your body weight and strength profile.")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.cream)
        .navigationTitle("Body Weight")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: {
                    Task {
                        await viewModel.saveProfile()
                        dismiss()
                    }
                })
            }
        }
    }
}
