import SwiftUI
import SwiftData

struct LiftMaxInputRow: View {
    let exercise: ExerciseDefinition
    let withStraps: Bool
    let userId: String
    @Bindable var viewModel: MaxLiftsViewModel
    @Environment(\.modelContext) private var modelContext

    private let repCounts = [1, 3, 5, 10]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                if exercise.supportsStraps {
                    Text(withStraps ? "w/ Straps" : "No Straps")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(withStraps ? Brand.gold.opacity(0.25) : Brand.navy.opacity(0.25))
                        .clipShape(Capsule())
                }

                Spacer()
            }

            // Rep-max fields
            HStack(spacing: 8) {
                ForEach(repCounts, id: \.self) { rep in
                    RepMaxField(
                        repCount: rep,
                        value: viewModel.weight(for: exercise.id, repCount: rep, withStraps: withStraps),
                        onSave: { newWeight in
                            viewModel.save(
                                userId: userId,
                                exerciseId: exercise.id,
                                repCount: rep,
                                weight: newWeight,
                                withStraps: withStraps,
                                context: modelContext
                            )
                        }
                    )
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Rep Max Field

private struct RepMaxField: View {
    let repCount: Int
    let value: Double?
    let onSave: (Double) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(repCount)RM")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            TextField("—", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.subheadline.monospacedDigit())
                .fontWeight(.medium)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(Brand.surface.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? Brand.tint : Color.clear, lineWidth: 1.5)
                )
                .focused($isFocused)
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        commitValue()
                    }
                }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .onAppear {
            if let v = value {
                text = formatWeight(v)
            }
        }
        .onChange(of: value) { _, newValue in
            if !isFocused {
                text = newValue.map { formatWeight($0) } ?? ""
            }
        }
    }

    private func commitValue() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let weight = Double(trimmed), weight > 0 else { return }
        onSave(weight)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", w)
            : String(format: "%.1f", w)
    }
}
