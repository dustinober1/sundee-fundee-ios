import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct QuickCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = QuickCheckInViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Today") {
                    valueSlider("Energy", value: $viewModel.energy)
                    valueSlider("Fatigue", value: $viewModel.fatigue)
                    valueSlider("Soreness", value: $viewModel.soreness)
                    valueSlider("Cramps", value: $viewModel.cramps)
                }

                Section("Pain") {
                    Toggle("Pain today", isOn: $viewModel.hasPain)

                    if viewModel.hasPain {
                        valueSlider("Intensity", value: $viewModel.painIntensity, range: 1...10)

                        Picker("Area", selection: $viewModel.painLocationID) {
                            ForEach(BodyRegions.allRegions, id: \.id) { region in
                                Text(region.displayName).tag(region.id)
                            }
                        }

                        Picker("Type", selection: $viewModel.painType) {
                            ForEach(PainType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    }
                }

                Section("Cycle") {
                    Toggle("Period active today", isOn: $viewModel.isPeriodActive)
                }

                Section("Notes") {
                    TextField("Optional", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Quick Check-In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .alert("Check-In Failed", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func valueSlider(_ title: String, value: Binding<Int>, range: ClosedRange<Int> = 0...10) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("\(title): \(value.wrappedValue)")

            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
        }
    }
}
