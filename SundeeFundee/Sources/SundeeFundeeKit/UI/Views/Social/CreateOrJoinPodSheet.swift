import SwiftUI

// MARK: - CreateOrJoinPodSheet

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct CreateOrJoinPodSheet: View {
    @ObservedObject var viewModel: AccountabilityPodViewModel
    let userID: String
    let displayName: String
    @Environment(\.dismiss) private var dismiss

    @State private var mode: PodMode = .create
    @State private var podName = ""
    @State private var targetWorkouts = 16
    @State private var inviteCode = ""

    public enum PodMode: String, CaseIterable, Identifiable {
        case create = "Create Pod"
        case join = "Join with Code"
        public var id: String { rawValue }
    }

    public init(
        viewModel: AccountabilityPodViewModel,
        userID: String,
        displayName: String
    ) {
        self.viewModel = viewModel
        self.userID = userID
        self.displayName = displayName
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $mode) {
                        ForEach(PodMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    #if os(watchOS)
                    .pickerStyle(.automatic)
                    #else
                    .pickerStyle(.segmented)
                    #endif
                }

                if mode == .create {
                    createSection
                } else {
                    joinSection
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundStyle(AppTheme.Semantic.error)
                    }
                }
            }
            .navigationTitle(mode.rawValue)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Create Section

    private var createSection: some View {
        Group {
            Section("Pod Details") {
                TextField("Pod Name (e.g. Iron Sisters)", text: $podName)
                    .autocorrectionDisabled()

                Stepper("Weekly Goal: \(targetWorkouts) workouts", value: $targetWorkouts, in: 2...40, step: 2)
            }

            Section {
                Button {
                    Task {
                        let success = await viewModel.createPod(
                            name: podName.isEmpty ? "Accountability Pod" : podName,
                            targetWorkouts: targetWorkouts,
                            userID: userID,
                            displayName: displayName
                        )
                        if success { dismiss() }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        }
                        Text("Create Accountability Pod")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    // MARK: - Join Section

    private var joinSection: some View {
        Group {
            Section("Enter Invite Code") {
                TextField("6-character code (e.g. WX9K24)", text: $inviteCode)
                    #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
                    .textInputAutocapitalization(.characters)
                    #endif
                    .autocorrectionDisabled()
                    .font(AppTheme.Typography.monoMedium)
            }

            Section {
                Button {
                    Task {
                        let success = await viewModel.joinPod(
                            inviteCode: inviteCode,
                            userID: userID,
                            displayName: displayName
                        )
                        if success { dismiss() }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.trailing, 4)
                        }
                        Text("Join Pod")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
        }
    }
}
