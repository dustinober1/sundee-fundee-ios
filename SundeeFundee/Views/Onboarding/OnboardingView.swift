import SwiftUI

struct OnboardingView: View {
    @Bindable var viewModel: AuthenticationViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var experienceLevel: ExperienceLevel = .beginner
    @State private var primaryGoal: PrimaryGoal = .strength
    @State private var gender: Gender = .preferNotToSay

    var body: some View {
        NavigationStack {
            BrandBackgroundView {
                Form {
                    Section("About You") {
                        TextField("Your Name", text: $name)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                    }

                    Section("Experience Level") {
                        Picker("Level", selection: $experienceLevel) {
                            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                                Text(level.rawValue.capitalized).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Primary Goal") {
                        Picker("Goal", selection: $primaryGoal) {
                            ForEach(PrimaryGoal.allCases, id: \.self) { goal in
                                Text(goal.rawValue.capitalized).tag(goal)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Gender") {
                        Picker("Gender", selection: $gender) {
                            ForEach(Gender.allCases, id: \.self) { g in
                                Text(g.displayName).tag(g)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        Button("Get Started") {
                            viewModel.completeOnboarding(
                                name: name,
                                experienceLevel: experienceLevel,
                                primaryGoal: primaryGoal,
                                gender: gender,
                                context: modelContext
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Welcome")
        }
    }
}
