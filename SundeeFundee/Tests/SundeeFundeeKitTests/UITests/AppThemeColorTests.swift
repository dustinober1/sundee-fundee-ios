#if canImport(AppKit)
import AppKit
import SwiftUI
import Testing
@testable import SundeeFundeeKit

@Suite("AppTheme Colors")
struct AppThemeColorTests {
    @Test("Background cream resolves darker in dark appearance")
    func backgroundCreamAdaptsToDarkAppearance() {
        let light = resolvedRGBA(AppTheme.Background.cream, appearance: .aqua)
        let dark = resolvedRGBA(AppTheme.Background.cream, appearance: .darkAqua)

        #expect(luminance(dark) < luminance(light))
    }

    @Test("Primary text resolves lighter in dark appearance")
    func primaryTextAdaptsToDarkAppearance() {
        let light = resolvedRGBA(AppTheme.Text.primary, appearance: .aqua)
        let dark = resolvedRGBA(AppTheme.Text.primary, appearance: .darkAqua)

        #expect(luminance(dark) > luminance(light))
    }

    @Test("Card background differs between light and dark appearances")
    func cardBackgroundAdaptsToDarkAppearance() {
        let light = resolvedRGBA(AppTheme.Background.card, appearance: .aqua)
        let dark = resolvedRGBA(AppTheme.Background.card, appearance: .darkAqua)

        #expect(light != dark)
        #expect(luminance(dark) < luminance(light))
    }

    @Test("Semantic colors adapt between light and dark appearances")
    func semanticColorsAdaptToDarkAppearance() {
        let semanticColors: [(String, Color)] = [
            ("success", AppTheme.Semantic.success),
            ("warning", AppTheme.Semantic.warning),
            ("error", AppTheme.Semantic.error),
            ("info", AppTheme.Semantic.info)
        ]

        for (name, color) in semanticColors {
            let light = resolvedRGBA(color, appearance: .aqua)
            let dark = resolvedRGBA(color, appearance: .darkAqua)

            #expect(light != dark, "\(name) should resolve differently in dark appearance")
        }
    }

    @Test("Subtle shadow opacity is stronger in dark appearance")
    func subtleShadowStrengthensInDarkAppearance() {
        let light = resolvedRGBA(AppTheme.Shadow.subtle, appearance: .aqua)
        let dark = resolvedRGBA(AppTheme.Shadow.subtle, appearance: .darkAqua)

        #expect(dark.3 > light.3)
    }
}

private func resolvedRGBA(_ color: Color, appearance: NSAppearance.Name) -> (Double, Double, Double, Double) {
    let appearance = NSAppearance(named: appearance)!
    var resolved: NSColor?
    appearance.performAsCurrentDrawingAppearance {
        resolved = NSColor(color).usingColorSpace(NSColorSpace.deviceRGB)
    }

    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    resolved!.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return (red, green, blue, alpha)
}

private func luminance(_ rgba: (Double, Double, Double, Double)) -> Double {
    0.2126 * rgba.0 + 0.7152 * rgba.1 + 0.0722 * rgba.2
}
#endif
