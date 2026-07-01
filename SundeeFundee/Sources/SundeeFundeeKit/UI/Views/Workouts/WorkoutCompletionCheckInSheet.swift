import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WorkoutCompletionCheckInSheet: View {
    @ObservedObject private var viewModel: WorkoutCompletionCheckInViewModel
    private let onDismiss: () -> Void

    public init(
        viewModel: WorkoutCompletionCheckInViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Effort") {
                    Picker("Session RPE", selection: $viewModel.sessionRPE) {
                        Text("Skip").tag(Int?.none)
                        ForEach(1...10, id: \.self) { value in
                            Text("\(value)").tag(Optional(value))
                        }
                    }
                }

                Section("How do you feel?") {
                    Stepper("Soreness \(viewModel.soreness)/10", value: $viewModel.soreness, in: 0...10)
                    Stepper("Pain \(viewModel.pain)/10", value: $viewModel.pain, in: 0...10)
                    Toggle("This was the right workout for today", isOn: $viewModel.wasRightForToday)
                }

                Section {
                    Button {
                        Task {
                            await viewModel.submit()
                            HapticFeedback.light()
                            onDismiss()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView("Saving check-in...")
                        } else {
                            Text("Save Check-In")
                        }
                    }
                    .disabled(viewModel.isSaving)

                    Button("Skip") {
                        onDismiss()
                    }
                }
            }
            .navigationTitle("Workout Check-In")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
