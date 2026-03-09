import SwiftUI

struct BarbellPresetsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                ForEach(viewModel.barbellPresets, id: \.id) { preset in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .font(AppTheme.Fonts.body)
                                .foregroundStyle(AppTheme.Colors.navy)
                            Text(Self.weightLabel(preset: preset, weightUnit: viewModel.weightUnit))
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                        }
                        Spacer()
                        if preset.isBuiltIn {
                            Text("Built-in")
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !preset.isBuiltIn {
                            Button(role: .destructive) {
                                viewModel.deleteCustomBarbell(id: preset.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Barbells")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddBarbellSheet(viewModel: viewModel)
        }
    }

    static func weightLabel(preset: BarbellPresetDTO, weightUnit: WeightUnit) -> String {
        let formatted = WeightUnitConversion.format(kilograms: preset.weightKg, unit: weightUnit, maximumFractionDigits: 1)
        return "\(formatted) \(weightUnit.symbol)"
    }
}

struct AddBarbellSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var weightValue: String = ""

    static func canSave(name: String, weightValue: String) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(weightValue) != nil && (Double(weightValue) ?? 0) > 0
    }

    static func saveAction(
        viewModel: SettingsViewModel,
        name: String,
        weightValue: String,
        weightUnit: WeightUnit,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            guard let value = Double(weightValue) else { return }
            let kg = WeightUnitConversion.kilograms(from: value, unit: weightUnit)
            viewModel.addCustomBarbell(name: name.trimmingCharacters(in: .whitespaces), weightKg: kg)
            dismiss()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Trap Bar, Safety Squat Bar", text: $name)
                }
                Section("Weight (\(viewModel.weightUnit.symbol))") {
                    TextField("Weight", text: $weightValue)
                        .keyboardType(.decimalPad)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Add Barbell")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: Self.saveAction(
                        viewModel: viewModel,
                        name: name,
                        weightValue: weightValue,
                        weightUnit: viewModel.weightUnit,
                        dismiss: dismiss.callAsFunction
                    ))
                    .disabled(!Self.canSave(name: name, weightValue: weightValue))
                }
            }
        }
    }
}
