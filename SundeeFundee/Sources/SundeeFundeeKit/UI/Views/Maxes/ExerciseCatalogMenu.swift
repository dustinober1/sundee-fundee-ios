import SwiftUI

// MARK: - ExerciseCatalogMenu
//
// Single-select dropdown sourcing from `weightliftingExercises`, grouped by
// WeightliftingCategory. A trailing "Add custom…" option flips the binding
// into custom-entry mode so the caller can show a text field.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ExerciseCatalogMenu: View {
    @Binding public var selectedName: String
    @Binding public var isCustom: Bool

    public init(selectedName: Binding<String>, isCustom: Binding<Bool>) {
        self._selectedName = selectedName
        self._isCustom = isCustom
    }

    public var body: some View {
        Menu {
            ForEach(WeightliftingCategory.allCases, id: \.self) { category in
                Section(category.rawValue) {
                    ForEach(weightliftingExercises.filter { $0.category == category }) { entry in
                        Button(entry.id) {
                            selectedName = entry.id
                            isCustom = false
                        }
                    }
                }
            }

            Section {
                Button("Add custom…") {
                    selectedName = ""
                    isCustom = true
                }
            }
        } label: {
            HStack {
                Text(label)
                    .foregroundStyle(labelForeground)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
    }

    private var label: String {
        if isCustom { return "Custom exercise" }
        return selectedName.isEmpty ? "Select exercise" : selectedName
    }

    private var labelForeground: Color {
        (selectedName.isEmpty && !isCustom) ? .secondary : .primary
    }
}
