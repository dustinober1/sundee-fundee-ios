#if canImport(UIKit)
import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

// MARK: - QRBadge
//
// Themed QR tile for share cards. Cream modules on navy background with a
// gold hairline border. Quartile error correction keeps scans reliable even
// with the border + future ornamentation.

@available(iOS 18.0, *)
struct QRBadge: View {
    let url: URL
    let size: CGFloat

    init(url: URL, size: CGFloat = 96) {
        self.url = url
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(AppTheme.Background.navy)
            if let qr = Self.generate(url: url) {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.08)
            }
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(AppTheme.Accent.gold, lineWidth: 1)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Download QR code, Sundee Fundee App Store link")
        .accessibilityHint("Scan with camera to open the App Store")
    }

    // MARK: - Generation

    private static func generate(url: URL) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "Q"
        guard let output = filter.outputImage else { return nil }

        // Mirrors AppTheme.Background.navy (#0d1a40) and .cream (#f4f0df).
        let navy = CIColor(red: 0.051, green: 0.102, blue: 0.251)
        let cream = CIColor(red: 0.956, green: 0.941, blue: 0.874)
        let colored = output.applyingFilter(
            "CIFalseColor",
            parameters: ["inputColor0": navy, "inputColor1": cream]
        )

        let context = CIContext()
        guard let cg = context.createCGImage(colored, from: colored.extent) else {
            return nil
        }
        return UIImage(cgImage: cg)
    }
}
#endif
