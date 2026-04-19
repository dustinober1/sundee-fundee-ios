import CoreGraphics

// MARK: - ShareCardAspect
//
// Aspect ratios for generated share cards. Story for IG/TikTok/iMessage, square
// for IG feed, Facebook, and LinkedIn. Point sizes are the SwiftUI render frame;
// the renderer applies scale 3.0 to produce ~1080px-wide export images.

public enum ShareCardAspect: String, CaseIterable, Sendable {
    case story
    case square

    /// SwiftUI point-space size used when laying out the card.
    public var size: CGSize {
        switch self {
        case .story:  return CGSize(width: 360, height: 640)
        case .square: return CGSize(width: 500, height: 500)
        }
    }

    /// Pixel size of the final rendered image at scale 3.0.
    public var pixelSize: CGSize {
        CGSize(width: size.width * 3.0, height: size.height * 3.0)
    }

    /// Human-readable label for UI pickers.
    public var displayName: String {
        switch self {
        case .story:  return "Story"
        case .square: return "Square"
        }
    }

    /// Aspect ratio hint, e.g. "9:16".
    public var ratioLabel: String {
        switch self {
        case .story:  return "9:16"
        case .square: return "1:1"
        }
    }
}
