import SwiftUI

// MARK: - ConfettiParticle

struct ConfettiParticle: Sendable {
    let x: Double
    let y: Double
    let size: Double
    let rotation: Double
    let color: ConfettiColor
    let speed: Double

    enum ConfettiColor: CaseIterable, Sendable {
        case orange, gold, cream

        var swiftUIColor: Color {
            switch self {
            case .orange: return AppTheme.Colors.accentOrange
            case .gold:   return AppTheme.Colors.gold
            case .cream:  return AppTheme.Colors.cream
            }
        }
    }

    static func generate(count: Int, seed: Int = 0) -> [ConfettiParticle] {
        // Deterministic-ish generation using simple LCG
        var state = UInt64(seed == 0 ? 42 : seed)
        func nextRandom() -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Double((state >> 33) & 0x7FFFFFFF) / Double(0x7FFFFFFF)
        }
        return (0..<count).map { _ in
            ConfettiParticle(
                x: nextRandom(),
                y: -nextRandom() * 0.3,
                size: 4 + nextRandom() * 8,
                rotation: nextRandom() * 360,
                color: ConfettiColor.allCases[Int(nextRandom() * 3) % 3],
                speed: 100 + nextRandom() * 200
            )
        }
    }
}

// MARK: - CelebrationOverlayView

struct CelebrationOverlayView: View {
    let event: CelebrationEvent
    var weightUnit: WeightUnit = .pounds
    var onDismiss: () -> Void = {}

    @State private var particles: [ConfettiParticle] = []
    @State private var elapsed: TimeInterval = 0
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    for particle in particles {
                        let yOffset = particle.speed * (time.truncatingRemainder(dividingBy: 10))
                        let x = particle.x * size.width
                        let y = particle.y * size.height + yOffset.truncatingRemainder(dividingBy: size.height * 1.3)
                        let rect = CGRect(
                            x: x - particle.size / 2,
                            y: y - particle.size / 2,
                            width: particle.size,
                            height: particle.size
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(particle.color.swiftUIColor)
                        )
                    }
                }
                .allowsHitTesting(false)
            }

            // Art Deco card
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: cardIcon)
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.Colors.gold)

                Text(event.title)
                    .font(AppTheme.Fonts.heading)
                    .foregroundStyle(AppTheme.Colors.gold)

                Text(event.subtitle(unit: weightUnit))
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.cream)
                    .multilineTextAlignment(.center)
            }
            .padding(AppTheme.Spacing.xl)
            .background(AppTheme.Colors.navy)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .shadow(color: AppTheme.Colors.gold.opacity(0.3), radius: 12, x: 0, y: 4)
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .opacity(opacity)
        .onTapGesture { dismissOverlay() }
        .onAppear {
            particles = ConfettiParticle.generate(count: 60)
            triggerHaptic()
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                dismissOverlay()
            }
        }
    }

    private var cardIcon: String {
        switch event {
        case .workoutCompleted: return "checkmark.seal.fill"
        case .newPersonalRecord: return "trophy.fill"
        case .programCompleted: return "star.fill"
        case .weightMilestone: return "flame.fill"
        }
    }

    private func dismissOverlay() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        #endif
    }
}
