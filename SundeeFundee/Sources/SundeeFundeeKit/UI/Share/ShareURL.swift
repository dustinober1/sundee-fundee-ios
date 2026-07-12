import Foundation

// MARK: - ShareURL
//
// Single source of truth for the public App Store link and share caption text.
// Kept free of UIKit/SwiftUI so it is reachable from tests and pure domain code.

public enum ShareURL {
    public static let appStore = GrowthLinkService.appStoreURL

    public static let shareCaption =
        "Training with Sundee Fundee - cycle-aware strength. \(appStore.absoluteString)"

    /// Privacy-safe payload used by readiness and deload cards. It deliberately
    /// has no caller context, so titles, referral codes, and source IDs cannot
    /// leak through captions or URLs.
    public static let sanitizedLink: URL = link(for: nil)
    public static let sanitizedCaption: String = caption(for: nil)

    public static func link(for context: ShareContext? = nil) -> URL {
        GrowthLinkService.link(for: context)
    }

    public static func caption(for context: ShareContext? = nil) -> String {
        GrowthLinkService.caption(for: context)
    }
}
