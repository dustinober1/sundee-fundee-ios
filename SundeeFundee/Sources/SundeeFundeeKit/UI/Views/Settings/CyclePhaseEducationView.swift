import SwiftUI

// MARK: - CyclePhaseEducationView
//
// Comprehensive educational guide about menstrual cycle phases and their impact on training.
// Accessible from dashboard cycle banner, onboarding, and settings.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct CyclePhaseEducationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CyclePhaseEducationViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Hero section
                    heroSection
                    
                    // Overview
                    overviewSection
                    
                    // The four phases (expandable)
                    phasesSection
                    
                    // How we adapt workouts
                    adaptationSection
                    
                    // Confidence explained
                    confidenceSection
                    
                    // FAQ
                    faqSection
                }
                .padding(AppTheme.Spacing.lg)
            }
            .navigationTitle("Cycle-Aware Training")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.trackEducationOpened()
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Cycle visualization
            ZStack {
                Circle()
                    .fill(AppTheme.Accent.goldLight)
                    .frame(width: 100, height: 100)
                
                HStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.Semantic.error)
                        Image(systemName: "sun.max.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(AppTheme.Accent.orange)
                        Image(systemName: "moon.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                }
            }
            .accessibilityLabel("Four cycle phases: menstrual, follicular, ovulation, luteal")
            
            Text("Train Smarter with Your Cycle")
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Text.primary)
                .multilineTextAlignment(.center)
            
            Text("Your hormones fluctuate throughout your cycle, affecting energy, strength, and recovery. Sundee Fundee adapts your training to match.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Label {
                    Text("Why It Matters")
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Text.primary)
                } icon: {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(AppTheme.Accent.gold)
                }
                
                Text("Research shows that hormonal changes throughout the menstrual cycle affect:")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    BulletPoint(text: "Strength and power output", icon: "bolt.fill")
                    BulletPoint(text: "Energy levels and motivation", icon: "battery.100")
                    BulletPoint(text: "Recovery and injury risk", icon: "heart.fill")
                    BulletPoint(text: "Temperature regulation", icon: "thermometer")
                }
            }
        }
    }
    
    // MARK: - Phases Section
    
    private var phasesSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("The Four Phases")
                    .font(AppTheme.Typography.headlineLarge)
                    .foregroundColor(AppTheme.Text.primary)
                Spacer()
            }
            
            // Menstrual Phase
            PhaseCard(
                phase: .menstrual,
                isExpanded: viewModel.expandedPhase == .menstrual
            ) {
                viewModel.togglePhase(.menstrual)
            }
            
            // Follicular Phase
            PhaseCard(
                phase: .follicular,
                isExpanded: viewModel.expandedPhase == .follicular
            ) {
                viewModel.togglePhase(.follicular)
            }
            
            // Ovulation Phase
            PhaseCard(
                phase: .ovulation,
                isExpanded: viewModel.expandedPhase == .ovulation
            ) {
                viewModel.togglePhase(.ovulation)
            }
            
            // Luteal Phase
            PhaseCard(
                phase: .luteal,
                isExpanded: viewModel.expandedPhase == .luteal
            ) {
                viewModel.togglePhase(.luteal)
            }
        }
    }
    
    // MARK: - Adaptation Section
    
    private var adaptationSection: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Label {
                    Text("How We Adapt Your Workouts")
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Text.primary)
                } icon: {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(AppTheme.Accent.gold)
                }
                
                Text("Sundee Fundee automatically adjusts your training based on your current cycle phase:")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    AdaptationBullet(
                        icon: "scalemass.fill",
                        title: "Volume & Intensity",
                        description: "Higher volume during follicular/ovulation, moderate during luteal, recovery-focused during menstrual"
                    )
                    
                    AdaptationBullet(
                        icon: "clock.fill",
                        title: "Rest Periods",
                        description: "Shorter rest when energy is high, longer when your body needs more recovery"
                    )
                    
                    AdaptationBullet(
                        icon: "figure.run",
                        title: "Exercise Selection",
                        description: "Compound movements when you're strongest, accessory work during lower-energy phases"
                    )
                    
                    AdaptationBullet(
                        icon: "heart.text.square",
                        title: "Recovery Emphasis",
                        description: "Extra focus on stretching, mobility, and active recovery when needed"
                    )
                }
                
                Text("You're always in control. These are suggestions—adjust as needed based on how you feel.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .padding(.top, AppTheme.Spacing.sm)
            }
        }
    }
    
    // MARK: - Confidence Section
    
    private var confidenceSection: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Label {
                    Text("Understanding Confidence")
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Text.primary)
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(AppTheme.Accent.gold)
                }
                
                Text("The confidence percentage shows how sure we are about your current cycle phase.")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                
                VStack(spacing: AppTheme.Spacing.md) {
                    ConfidenceLevel(
                        range: "70-100%",
                        color: AppTheme.Semantic.success,
                        meaning: "High Confidence",
                        description: "Strong pattern detected from consistent cycle data"
                    )
                    
                    ConfidenceLevel(
                        range: "40-69%",
                        color: AppTheme.Accent.gold,
                        meaning: "Medium Confidence",
                        description: "Some variation in cycle length, but reasonable estimate"
                    )
                    
                    ConfidenceLevel(
                        range: "0-39%",
                        color: AppTheme.Accent.orange,
                        meaning: "Lower Confidence",
                        description: "Limited data or irregular cycles—keep tracking to improve"
                    )
                }
                
                Text("Confidence improves as you log more cycles. Even at lower confidence, our recommendations are based on typical hormonal patterns.")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .padding(.top, AppTheme.Spacing.sm)
            }
        }
    }
    
    // MARK: - FAQ Section
    
    private var faqSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Common Questions")
                    .font(AppTheme.Typography.headlineLarge)
                    .foregroundColor(AppTheme.Text.primary)
                Spacer()
            }
            
            FAQCard(
                question: "What if my cycle is irregular?",
                answer: "That's okay! Sundee Fundee adapts to your actual cycle data, not a textbook 28-day model. Keep logging your cycle, and the app will learn your unique patterns. Even with irregularity, general phase-based recommendations can still be helpful.",
                isExpanded: viewModel.expandedFAQ == 0
            ) {
                viewModel.toggleFAQ(0)
            }
            
            FAQCard(
                question: "Do I need to track my cycle outside the app?",
                answer: "You can! Sundee Fundee can read cycle data from Apple Health if you track elsewhere. Or, use the built-in cycle calendar to log directly in the app. Either way works.",
                isExpanded: viewModel.expandedFAQ == 1
            ) {
                viewModel.toggleFAQ(1)
            }
            
            FAQCard(
                question: "What about birth control or menopause?",
                answer: "Hormonal birth control typically suppresses natural cycle fluctuations, so cycle-aware training may be less relevant. You can disable it in Settings. For perimenopause or menopause, focus on how you feel day-to-day—our daily check-ins are more useful than cycle tracking.",
                isExpanded: viewModel.expandedFAQ == 2
            ) {
                viewModel.toggleFAQ(2)
            }
            
            FAQCard(
                question: "Can I ignore the suggestions?",
                answer: "Absolutely! These are recommendations, not requirements. If you feel great during your menstrual phase and want to lift heavy, go for it. Listen to your body first, always.",
                isExpanded: viewModel.expandedFAQ == 3
            ) {
                viewModel.toggleFAQ(3)
            }
        }
    }
}

// MARK: - PhaseCard

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct PhaseCard: View {
    let phase: CyclePhase
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Button(action: onTap) {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: phaseIcon)
                            .font(.title2)
                            .foregroundColor(phaseColor)
                            .frame(width: 32)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(phaseTitle)
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Text.primary)
                            
                            Text(phaseDays)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Divider()
                        
                        Text("What's Happening")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)
                        
                        Text(phaseDescription)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.secondary)
                        
                        Text("Training Approach")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)
                            .padding(.top, AppTheme.Spacing.sm)
                        
                        Text(trainingGuidance)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.secondary)
                        
                        // Key hormones
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Key Hormones")
                                .font(AppTheme.Typography.headlineSmall)
                                .foregroundColor(AppTheme.Text.primary)
                                .padding(.top, AppTheme.Spacing.sm)
                            
                            Text(hormoneInfo)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
    
    private var phaseIcon: String {
        switch phase {
        case .menstrual: return "drop.fill"
        case .follicular: return "sun.max.fill"
        case .ovulation: return "sparkles"
        case .luteal: return "moon.fill"
        }
    }
    
    private var phaseColor: Color {
        switch phase {
        case .menstrual: return AppTheme.Semantic.error
        case .follicular: return AppTheme.Accent.gold
        case .ovulation: return AppTheme.Accent.orange
        case .luteal: return AppTheme.Text.secondary
        }
    }
    
    private var phaseTitle: String {
        switch phase {
        case .menstrual: return "Menstrual Phase"
        case .follicular: return "Follicular Phase"
        case .ovulation: return "Ovulation Phase"
        case .luteal: return "Luteal Phase"
        }
    }
    
    private var phaseDays: String {
        switch phase {
        case .menstrual: return "Days 1-5 (Period)"
        case .follicular: return "Days 6-13"
        case .ovulation: return "Days 14-16"
        case .luteal: return "Days 17-28"
        }
    }
    
    private var phaseDescription: String {
        switch phase {
        case .menstrual:
            return "Your period begins as estrogen and progesterone drop to their lowest levels. Energy may be lower, and you might experience cramping, fatigue, or body aches. This is your body's recovery phase."
        case .follicular:
            return "After your period ends, estrogen begins rising. Energy and mood typically improve, and your body becomes more responsive to training stimulus. This is often when you feel your best."
        case .ovulation:
            return "Estrogen peaks just before ovulation, often bringing your highest energy, strength, and pain tolerance. You may feel invincible during these few days—capitalize on it!"
        case .luteal:
            return "After ovulation, progesterone rises while estrogen drops. Energy may fluctuate, and you might experience PMS symptoms, bloating, or increased appetite. Recovery needs increase."
        }
    }
    
    private var trainingGuidance: String {
        switch phase {
        case .menstrual:
            return "Focus on movement and recovery. Light to moderate intensity, shorter sessions, or active recovery like yoga and walking. Honor your body's need for rest."
        case .follicular:
            return "Great time for progressive overload and skill work. Your body recovers faster, so you can handle higher volume and intensity. Push for PRs and tackle challenging workouts."
        case .ovulation:
            return "Peak performance window! Go for max lifts, high-intensity workouts, and new challenges. Your body is primed for strength and power."
        case .luteal:
            return "Maintain intensity but manage volume carefully. Focus on technique, moderate weights, and adequate rest. Listen closely to your body's recovery signals."
        }
    }
    
    private var hormoneInfo: String {
        switch phase {
        case .menstrual:
            return "🔻 Estrogen: Low • 🔻 Progesterone: Low"
        case .follicular:
            return "🔺 Estrogen: Rising • 🔻 Progesterone: Low"
        case .ovulation:
            return "⬆️ Estrogen: Peak • 🔻 Progesterone: Low (beginning to rise)"
        case .luteal:
            return "🔻 Estrogen: Falling • 🔺 Progesterone: High"
        }
    }
}

// MARK: - Supporting Components

private struct BulletPoint: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.Accent.gold)
                .frame(width: 16)
                .accessibilityHidden(true)
            
            Text(text)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
        }
    }
}

private struct AdaptationBullet: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.Accent.gold)
                .frame(width: 24)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Text.primary)
                
                Text(description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ConfidenceLevel: View {
    let range: String
    let color: Color
    let meaning: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .padding(.top, 4)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(meaning)
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Text.primary)
                    
                    Text(range)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
                
                Text(description)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct FAQCard: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Button(action: onTap) {
                    HStack {
                        Text(question)
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                }
                .buttonStyle(.plain)
                
                if isExpanded {
                    Text(answer)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

// MARK: - CyclePhaseEducationViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class CyclePhaseEducationViewModel: ObservableObject {
    @Published var expandedPhase: CyclePhase?
    @Published var expandedFAQ: Int?
    
    private let dataClient: DataClientProtocol
    
    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }
    
    func togglePhase(_ phase: CyclePhase) {
        withAnimation {
            if expandedPhase == phase {
                expandedPhase = nil
            } else {
                expandedPhase = phase
                // Track which phase users explore
                Task {
                    await GrowthAnalyticsService(dataClient: dataClient).track(
                        GrowthEventName.cycleEducationPhaseExpanded,
                        source: "cycle_education",
                        properties: ["phase": phase.rawValue]
                    )
                }
            }
        }
    }
    
    func toggleFAQ(_ index: Int) {
        withAnimation {
            if expandedFAQ == index {
                expandedFAQ = nil
            } else {
                expandedFAQ = index
            }
        }
    }
    
    func trackEducationOpened() async {
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.cycleEducationOpened,
            source: "cycle_education"
        )
    }
}

// MARK: - Preview

#Preview {
    CyclePhaseEducationView()
}
