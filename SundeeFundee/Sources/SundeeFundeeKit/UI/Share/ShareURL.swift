import Foundation

// MARK: - ShareURL
//
// Single source of truth for the public App Store link and share caption text.
// Kept free of UIKit/SwiftUI so it is reachable from tests and pure domain code.

public enum ShareURL {
    public static let appStore = GrowthLinkService.appStoreURL

    public static let shareCaption =
        "Training with Sundee Fundee - cycle-aware strength. \(appStore.absoluteString)"

    public static func link(for context: ShareContext? = nil) -> URL {
        GrowthLinkService.link(for: context)
    }

    public static func caption(for context: ShareContext? = nil) -> String {
        GrowthLinkService.caption(for: context)
    }
}
