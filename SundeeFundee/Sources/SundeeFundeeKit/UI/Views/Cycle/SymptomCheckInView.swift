import SwiftUI

// MARK: - SymptomCheckInView

/// A form for logging daily symptom check-ins across four dimensions:
/// cramps, fatigue, soreness, and energy (all 0-10 sliders).
/// Saves a `SymptomCheckInRecord` via `DataClientFactory`.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct SymptomCheckInView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var cramps: Double = 0
    @State private var fatigue: Double = 0
    @State private var soreness: Double = 0
    @State private var energy: Double = 5
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var didSave: Bool = false
    @State private var errorMessage: String?

    private let dataClient = DataClientFactory.shared.client

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                disclaimerCard

                sliderCard(
                    title: "Cramps",
                    value: $cramps,
                    color: AppTheme.Accent.orange
                )

                sliderCard(
                    title: "Fatigue",
                    value: $fatigue,
                    color: AppTheme.Accent.gold
                )

                sliderCard(
                    title: "Soreness",
                    value: $soreness,
                    color: AppTheme.Accent.orange
                )

                sliderCard(
                    title: "Energy",
                    value: $energy,
                    color: AppTheme.Recovery.green
                )

                notesCard

                if let error = errorMessage {
                    Text(error)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Semantic.error)
                }

                if didSave {
                    Label("Check-in saved", systemImage: "checkmark.circle.fill")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Recovery.green)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .artDecoBackground()
        .navigationTitle("Symptom Check-In")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCheckIn()
                }
                .disabled(isSaving || didSave)
            }
        }
    }

    // MARK: - Subviews

    private var disclaimerCard: some View {
        ArtDecoCard {
            Text("Symptom tracking is for personal fitness awareness only. It is not a substitute for professional medical advice.")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func sliderCard(
        title: String,
        value: Binding<Double>,
        color: Color
    ) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text(title)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Spacer()

                    Text("\(Int(value.wrappedValue))/10")
                        .font(AppTheme.Typography.monoLarge)
                        .foregroundColor(color)
                }

                Slider(value: value, in: 0...10, step: 1)
                    .tint(color)

                HStack {
                    Text("None")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Text.secondary)
                    Spacer()
                    Text("Severe")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }
        }
    }

    private var notesCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Notes (optional)")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                TextField("How are you feeling today?", text: $notes, axis: .vertical)
                    .font(AppTheme.Typography.bodyMedium)
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Background.cream.opacity(0.5))
                    .cornerRadius(AppTheme.CornerRadius.small)
            }
        }
    }

    // MARK: - Save

    private func saveCheckIn() {
        guard !authViewModel.isGuest else { return }
        isSaving = true
        errorMessage = nil

        let record = SymptomCheckInRecord(
            symptomDate: Date(),
            cramps: Int(cramps),
            fatigue: Int(fatigue),
            soreness: Int(soreness),
            energy: Int(energy),
            notes: notes.isEmpty ? nil : notes
        )

        Task {
            do {
                try await dataClient.save(record, recordType: "SymptomCheckInRecord")
                didSave = true
                HapticFeedback.success()
            } catch {
                errorMessage = "Could not save check-in. Please try again."
            }
            isSaving = false
        }
    }
}
