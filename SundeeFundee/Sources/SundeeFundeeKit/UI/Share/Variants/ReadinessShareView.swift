import SwiftUI

/// A privacy-first readiness outcome card. The view has no access to the
/// underlying assessment or its inputs; only sanitized presentation metadata is
/// accepted.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ReadinessShareView: View {
    let summary: ShareSanitizedSummary
    let aspect: ShareCardAspect
    let privacyOptions: SharePrivacyOptions

    var body: some View {
        SanitizedOutcomeShareView(
            summary: summary,
            badge: "READINESS",
            aspect: aspect,
            privacyOptions: privacyOptions,
            accessibilityLabel: "Readiness share card: \(summary.title)"
        )
    }
}
