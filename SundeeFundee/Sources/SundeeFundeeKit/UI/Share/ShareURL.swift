import Foundation

// MARK: - ShareURL
//
// Single source of truth for the public App Store link and share caption text.
// Kept free of UIKit/SwiftUI so it is reachable from tests and pure domain code.

public enum ShareURL {
    public static let appStore = URL(
        string: "https://apps.apple.com/app/sundeefundee/id6759870888"
    )!

    public static let shareCaption =
        "Training with Sundee Fundee — cycle-aware strength. \(appStore.absoluteString)"
}
