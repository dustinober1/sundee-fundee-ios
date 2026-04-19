#if canImport(UIKit)
import XCTest
import SwiftUI
import CoreImage
@testable import SundeeFundeeKit

@available(iOS 18.0, *)
final class QRBadgeTests: XCTestCase {
    @MainActor
    func testQRDecodesToAppStoreURL() throws {
        let badge = QRBadge(url: ShareURL.appStore, size: 256)
        let renderer = ImageRenderer(content: badge.frame(width: 256, height: 256))
        renderer.scale = 2.0
        let image = try XCTUnwrap(renderer.uiImage)

        let ciImage = try XCTUnwrap(CIImage(image: image))
        let detector = try XCTUnwrap(
            CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)
        )
        let features = detector.features(in: ciImage).compactMap { $0 as? CIQRCodeFeature }
        let decoded = features.compactMap(\.messageString)
        XCTAssertTrue(
            decoded.contains(ShareURL.appStore.absoluteString),
            "QR should decode to App Store URL, got: \(decoded)"
        )
    }
}
#endif
