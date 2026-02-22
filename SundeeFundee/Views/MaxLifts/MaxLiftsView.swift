import SwiftUI
import SwiftData

struct MaxLiftsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Environment(AuthenticationViewModel.self) private var authViewModel

    @State private var viewModel = MaxLiftsViewModel()
    @State private var expandedCategories: Set<LiftCategory> = Set(LiftCategory.allCases)

    private var userId: String {
        if let user = users.first { return user.id }
        return authViewModel.authState == .guest ? "guest" : ""
    }

    var body: some View {
        NavigationStack {
            BrandBackgroundView {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header description
                        Text("Track your rep maxes across every lift. Tap a field to enter weight in lbs.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 4)

                        ForEach(LiftCategory.allCases) { category in
                            LiftCategorySection(
                                category: category,
                                isExpanded: expandedCategories.contains(category),
                                onToggle: { toggleCategory(category) },
                                userId: userId,
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Max Lifts")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                viewModel.load(userId: userId, context: modelContext)
            }
        }
    }

    private func toggleCategory(_ category: LiftCategory) {
        withAnimation(.easeInOut(duration: 0.25)) {
            if expandedCategories.contains(category) {
                expandedCategories.remove(category)
            } else {
                expandedCategories.insert(category)
            }
        }
    }
}

// MARK: - Category Section

private struct LiftCategorySection: View {
    let category: LiftCategory
    let isExpanded: Bool
    let onToggle: @MainActor () -> Void
    let userId: String
    @Bindable var viewModel: MaxLiftsViewModel

    private var exercises: [ExerciseDefinition] {
        Exercises.byCategory[category] ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundStyle(Brand.tint)
                        .frame(width: 28)

                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(exercises.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Brand.surface.opacity(0.6))
                        .clipShape(Capsule())

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Brand.surface.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // Expanded exercises
            if isExpanded {
                LazyVStack(spacing: 0) {
                    ForEach(exercises) { exercise in
                        VStack(spacing: 0) {
                            if exercise.supportsStraps {
                                // Without straps row
                                LiftMaxInputRow(
                                    exercise: exercise,
                                    withStraps: false,
                                    userId: userId,
                                    viewModel: viewModel
                                )
                                .padding(.horizontal, 16)

                                Divider()
                                    .padding(.horizontal, 24)
                                    .opacity(0.5)

                                // With straps row
                                LiftMaxInputRow(
                                    exercise: exercise,
                                    withStraps: true,
                                    userId: userId,
                                    viewModel: viewModel
                                )
                                .padding(.horizontal, 16)
                            } else {
                                LiftMaxInputRow(
                                    exercise: exercise,
                                    withStraps: false,
                                    userId: userId,
                                    viewModel: viewModel
                                )
                                .padding(.horizontal, 16)
                            }

                            if exercise.id != exercises.last?.id {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(Brand.surface.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    MaxLiftsView()
        .modelContainer(for: [User.self, LiftMax.self], inMemory: true)
        .environment(AuthenticationViewModel())
}
