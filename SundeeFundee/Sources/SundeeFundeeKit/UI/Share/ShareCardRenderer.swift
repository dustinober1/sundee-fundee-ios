#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - ShareCardRenderer
//
// Unified entry point that turns a ShareCardVariant + ShareCardAspect into a
// rendered UIImage. Uses SwiftUI ImageRenderer at scale 3.0 for crisp output
// on modern devices.

@available(iOS 18.0, *)
public enum ShareCardRenderer {
    public static let renderScale: CGFloat = 3.0

    public static func render(
        _ variant: ShareCardVariant,
        aspect: ShareCardAspect,
        shareContext: ShareContext? = nil
    ) async -> UIImage? {
        await Task.detached(priority: .userInitiated) { @MainActor in
            let renderer = ImageRenderer(content: content(for: variant, aspect: aspect, shareContext: shareContext))
            renderer.scale = renderScale
            return renderer.uiImage
        }.value
    }

    // MARK: - View routing

    @ViewBuilder
    @MainActor
    public static func content(
        for variant: ShareCardVariant,
        aspect: ShareCardAspect,
        shareContext: ShareContext? = nil
    ) -> some View {
        switch variant {
        case .completedWorkout(let workout, let prs):
            CompletedWorkoutShareView(
                workout: workout,
                personalRecords: prs,
                aspect: aspect,
                shareURL: ShareURL.link(for: shareContext)
            )
        case .newPR(let exercise, let weight, let unit, let previousBest):
            NewPRShareView(
                exerciseName: exercise,
                weight: weight,
                unit: unit,
                previousBest: previousBest,
                aspect: aspect,
                shareURL: ShareURL.link(for: shareContext)
            )
        case .cycleInsight(let phase, let day, let insight):
            CycleInsightShareView(
                phase: phase,
                cycleDay: day,
                insight: insight,
                aspect: aspect,
                shareURL: ShareURL.link(for: shareContext)
            )
        case .coachSummary(let title, let subtitle, let badge, let bullets):
            CoachSummaryShareView(
                title: title,
                subtitle: subtitle,
                badge: badge,
                bullets: bullets,
                aspect: aspect
            )
        case .weeklyRecap(let title, let subtitle, let badge, let bullets):
            CoachSummaryShareView(
                title: title,
                subtitle: subtitle,
                badge: badge,
                bullets: bullets,
                aspect: aspect
            )
        case .selfieOverlay(let image, let summary):
            SelfieOverlayShareView(
                image: image,
                summary: summary,
                aspect: aspect
            )
        }
    }
}
#endif
